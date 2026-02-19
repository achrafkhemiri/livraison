package com.example.backend.service.impl;

import com.example.backend.service.OsrmService;
import tools.jackson.databind.JsonNode;
import tools.jackson.databind.ObjectMapper;
import tools.jackson.databind.json.JsonMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

/**
 * OSRM integration service.
 * Calls OSRM HTTP API (/table, /trip, /route) and caches results.
 */
@Slf4j
@Service
public class OsrmServiceImpl implements OsrmService {

    private final String osrmBaseUrl;
    private final HttpClient httpClient;
    private final ObjectMapper jsonMapper = JsonMapper.builder().build();

    /** Simple in-memory cache for table results — key = sorted coordinates hash */
    private final ConcurrentHashMap<String, CacheEntry<TableResult>> tableCache = new ConcurrentHashMap<>();
    private static final long CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

    private record CacheEntry<T>(T value, long timestamp) {
        boolean isExpired() { return System.currentTimeMillis() - timestamp > CACHE_TTL_MS; }
    }

    public OsrmServiceImpl(@Value("${osrm.url:http://localhost:5000}") String osrmBaseUrl) {
        this.osrmBaseUrl = osrmBaseUrl;
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(5))
                .build();
    }

    // ========================================================================
    //  /table — duration + distance matrix
    // ========================================================================

    @Override
    public TableResult getTable(List<double[]> coordinates) {
        return getTable(coordinates, null, null);
    }

    @Override
    public TableResult getTable(List<double[]> coordinates, List<Integer> sourceIndices, List<Integer> destIndices) {
        if (coordinates == null || coordinates.size() < 2) return null;

        String cacheKey = tableCacheKey(coordinates, sourceIndices, destIndices);
        CacheEntry<TableResult> cached = tableCache.get(cacheKey);
        if (cached != null && !cached.isExpired()) {
            return cached.value();
        }

        try {
            // Build coordinate string: lon,lat;lon,lat;...
            String coords = coordinates.stream()
                    .map(c -> c[1] + "," + c[0]) // OSRM takes lon,lat
                    .collect(Collectors.joining(";"));

            StringBuilder url = new StringBuilder(osrmBaseUrl)
                    .append("/table/v1/driving/")
                    .append(coords)
                    .append("?annotations=duration,distance");

            if (sourceIndices != null && !sourceIndices.isEmpty()) {
                url.append("&sources=").append(sourceIndices.stream()
                        .map(String::valueOf).collect(Collectors.joining(";")));
            }
            if (destIndices != null && !destIndices.isEmpty()) {
                url.append("&destinations=").append(destIndices.stream()
                        .map(String::valueOf).collect(Collectors.joining(";")));
            }

            String body = httpGet(url.toString());
            if (body == null) return null;

            JsonNode root = jsonMapper.readTree(body);
            if (!"Ok".equals(root.path("code").asText())) {
                log.warn("OSRM /table returned code: {}", root.path("code").asText());
                return null;
            }

            double[][] durations = parseMatrix(root.path("durations"));
            double[][] distances = parseMatrix(root.path("distances"));

            TableResult result = new TableResult(durations, distances);
            tableCache.put(cacheKey, new CacheEntry<>(result, System.currentTimeMillis()));
            return result;

        } catch (Exception e) {
            log.warn("OSRM /table call failed: {}", e.getMessage());
            return null;
        }
    }

    // ========================================================================
    //  /trip — TSP optimization
    // ========================================================================

    @Override
    public TripResult getTrip(List<double[]> coordinates, boolean roundtrip) {
        if (coordinates == null || coordinates.size() < 2) return null;

        try {
            String coords = coordinates.stream()
                    .map(c -> c[1] + "," + c[0])
                    .collect(Collectors.joining(";"));

            String url = osrmBaseUrl + "/trip/v1/driving/" + coords
                    + "?roundtrip=" + roundtrip
                    + "&source=first"
                    + "&geometries=polyline"
                    + "&overview=false";

            String body = httpGet(url);
            if (body == null) return null;

            JsonNode root = jsonMapper.readTree(body);
            if (!"Ok".equals(root.path("code").asText())) {
                log.warn("OSRM /trip returned code: {}", root.path("code").asText());
                return null;
            }

            JsonNode trip = root.path("trips").get(0);
            double totalDuration = trip.path("duration").asDouble();
            double totalDistance = trip.path("distance").asDouble();

            // Extract waypoint order
            JsonNode waypoints = root.path("waypoints");
            List<Integer> order = new ArrayList<>();
            for (JsonNode wp : waypoints) {
                order.add(wp.path("waypoint_index").asInt());
            }

            return new TripResult(order, totalDuration, totalDistance);

        } catch (Exception e) {
            log.warn("OSRM /trip call failed: {}", e.getMessage());
            return null;
        }
    }

    // ========================================================================
    //  /route — fixed sequence route
    // ========================================================================

    @Override
    public RouteResult getRoute(List<double[]> coordinates) {
        if (coordinates == null || coordinates.size() < 2) return null;

        try {
            String coords = coordinates.stream()
                    .map(c -> c[1] + "," + c[0])
                    .collect(Collectors.joining(";"));

            String url = osrmBaseUrl + "/route/v1/driving/" + coords
                    + "?overview=false";

            String body = httpGet(url);
            if (body == null) return null;

            JsonNode root = jsonMapper.readTree(body);
            if (!"Ok".equals(root.path("code").asText())) {
                log.warn("OSRM /route returned code: {}", root.path("code").asText());
                return null;
            }

            JsonNode route = root.path("routes").get(0);
            return new RouteResult(route.path("duration").asDouble(), route.path("distance").asDouble());

        } catch (Exception e) {
            log.warn("OSRM /route call failed: {}", e.getMessage());
            return null;
        }
    }

    // ========================================================================
    //  Health check
    // ========================================================================

    @Override
    public boolean isAvailable() {
        try {
            // Simple route call between two nearby points in Tunisia
            String url = osrmBaseUrl + "/route/v1/driving/10.18,36.80;10.19,36.81?overview=false";
            String body = httpGet(url);
            if (body == null) return false;
            JsonNode root = jsonMapper.readTree(body);
            return "Ok".equals(root.path("code").asText());
        } catch (Exception e) {
            return false;
        }
    }

    // ========================================================================
    //  Internal helpers
    // ========================================================================

    private String httpGet(String url) {
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofSeconds(10))
                    .GET()
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
                return response.body();
            }
            log.warn("OSRM HTTP {} for {}", response.statusCode(), url);
            return null;
        } catch (Exception e) {
            log.warn("OSRM HTTP error: {}", e.getMessage());
            return null;
        }
    }

    private double[][] parseMatrix(JsonNode matrixNode) {
        if (matrixNode == null || matrixNode.isMissingNode()) return new double[0][0];
        int rows = matrixNode.size();
        if (rows == 0) return new double[0][0];
        int cols = matrixNode.get(0).size();
        double[][] matrix = new double[rows][cols];
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < cols; j++) {
                JsonNode val = matrixNode.get(i).get(j);
                matrix[i][j] = (val != null && !val.isNull()) ? val.asDouble() : Double.MAX_VALUE;
            }
        }
        return matrix;
    }

    private String tableCacheKey(List<double[]> coords, List<Integer> sources, List<Integer> dests) {
        StringBuilder sb = new StringBuilder("table:");
        for (double[] c : coords) {
            sb.append(String.format("%.6f,%.6f;", c[0], c[1]));
        }
        if (sources != null) sb.append("|s=").append(sources);
        if (dests != null) sb.append("|d=").append(dests);
        return sb.toString();
    }
}
