package com.example.backend.service;

import java.util.List;

/**
 * Service for calling OSRM APIs (table, trip, route) to get real road distances/durations.
 */
public interface OsrmService {

    /**
     * Result of an OSRM /table call: NxN matrix of durations (seconds) and distances (meters).
     */
    record TableResult(double[][] durations, double[][] distances) {}

    /**
     * Result of an OSRM /trip call: ordered list of waypoint indices + total duration/distance.
     */
    record TripResult(List<Integer> waypointOrder, double totalDurationSeconds, double totalDistanceMeters) {}

    /**
     * Result of an OSRM /route call: total duration/distance for a fixed sequence of points.
     */
    record RouteResult(double totalDurationSeconds, double totalDistanceMeters) {}

    /**
     * Get a duration + distance matrix between all given coordinates.
     * @param coordinates list of [latitude, longitude] pairs
     * @return TableResult with NxN matrices, or null if OSRM is unavailable
     */
    TableResult getTable(List<double[]> coordinates);

    /**
     * Get a duration + distance matrix with specified sources and destinations.
     * @param coordinates all coordinates
     * @param sourceIndices indices into coordinates for sources
     * @param destIndices   indices into coordinates for destinations
     * @return TableResult with sources×destinations matrices, or null if OSRM is unavailable
     */
    TableResult getTable(List<double[]> coordinates, List<Integer> sourceIndices, List<Integer> destIndices);

    /**
     * Solve a round-trip TSP for the given coordinates.
     * @param coordinates list of [latitude, longitude] pairs
     * @param roundtrip   whether to return to the start
     * @return TripResult with optimal order, or null if OSRM is unavailable
     */
    TripResult getTrip(List<double[]> coordinates, boolean roundtrip);

    /**
     * Get the route (duration + distance) for a fixed sequence of coordinates.
     * @param coordinates ordered list of [latitude, longitude] pairs
     * @return RouteResult, or null if OSRM is unavailable
     */
    RouteResult getRoute(List<double[]> coordinates);

    /**
     * Check if OSRM is reachable.
     */
    boolean isAvailable();
}
