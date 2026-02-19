package com.example.backend.service.impl;

import com.example.backend.dto.MapDataDTO;
import com.example.backend.dto.ProductStockInfoDTO;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.model.*;
import com.example.backend.repository.*;
import com.example.backend.service.MapDataService;
import com.example.backend.service.OsrmService;
import tools.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MapDataServiceImpl implements MapDataService {

    private static final Logger log = LoggerFactory.getLogger(MapDataServiceImpl.class);

    private final SocieteRepository societeRepository;
    private final MagasinRepository magasinRepository;
    private final DepotRepository depotRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final StockRepository stockRepository;
    private final OrderRepository orderRepository;
    private final ObjectMapper objectMapper;
    private final OsrmService osrmService;

    @Value("${osrm.workload-penalty-minutes:5}")
    private double workloadPenaltyMinutes;

    @Override
    public MapDataDTO getMapData(Long societeId) {
        // Get société
        Societe societe = societeRepository.findById(societeId)
                .orElseThrow(() -> new ResourceNotFoundException("Societe", "id", societeId));

        MapDataDTO.SocieteMarker societeMarker = MapDataDTO.SocieteMarker.builder()
                .id(societe.getId())
                .nom(societe.getRaisonSociale())
                .latitude(societe.getLatitude())
                .longitude(societe.getLongitude())
                .build();

        // Get magasins
        List<Magasin> magasins = magasinRepository.findBySocieteId(societeId);
        List<MapDataDTO.MagasinMarker> magasinMarkers = magasins.stream()
                .filter(m -> m.getLatitude() != null && m.getLongitude() != null)
                .map(m -> MapDataDTO.MagasinMarker.builder()
                        .id(m.getId())
                        .nom(m.getNomMagasin())
                        .adresse(m.getAdresse())
                        .ville(m.getVille())
                        .latitude(m.getLatitude())
                        .longitude(m.getLongitude())
                        .build())
                .collect(Collectors.toList());

        // Get depots
        List<Depot> depots = depotRepository.findBySocieteId(societeId);
        List<MapDataDTO.DepotMarker> depotMarkers = depots.stream()
                .filter(d -> d.getLatitude() != null && d.getLongitude() != null)
                .map(d -> MapDataDTO.DepotMarker.builder()
                        .id(d.getId())
                        .nom(d.getNom())
                        .code(d.getCode())
                        .adresse(d.getAdresse())
                        .ville(d.getVille())
                        .latitude(d.getLatitude())
                        .longitude(d.getLongitude())
                        .actif(d.getActif())
                        .build())
                .collect(Collectors.toList());

        // Get livreurs with positions
        List<Utilisateur> livreurs = utilisateurRepository.findLivreursWithPositionBySocieteId(societeId);
        List<MapDataDTO.LivreurMarker> livreurMarkers = livreurs.stream()
                .map(l -> MapDataDTO.LivreurMarker.builder()
                        .id(l.getId())
                        .nom(l.getNom())
                        .prenom(l.getPrenom())
                        .latitude(l.getLatitude())
                        .longitude(l.getLongitude())
                        .dernierePositionAt(l.getDernierePositionAt() != null 
                                ? l.getDernierePositionAt().toString() : null)
                        .build())
                .collect(Collectors.toList());

        return MapDataDTO.builder()
                .societe(societeMarker)
                .magasins(magasinMarkers)
                .depots(depotMarkers)
                .livreurs(livreurMarkers)
                .build();
    }

    @Override
    public List<ProductStockInfoDTO> getProductsWithStockBySociete(Long societeId) {
        List<Stock> stocks = stockRepository.findAvailableStockBySocieteId(societeId);

        // Group by product
        Map<Long, List<Stock>> stocksByProduct = stocks.stream()
                .filter(s -> s.getProduit() != null)
                .collect(Collectors.groupingBy(s -> s.getProduit().getId()));

        List<ProductStockInfoDTO> result = new ArrayList<>();
        for (Map.Entry<Long, List<Stock>> entry : stocksByProduct.entrySet()) {
            List<Stock> productStocks = entry.getValue();
            Produit produit = productStocks.get(0).getProduit();

            List<ProductStockInfoDTO.DepotStockDTO> depotStocks = productStocks.stream()
                    .filter(s -> s.getDepot() != null)
                    .map(s -> ProductStockInfoDTO.DepotStockDTO.builder()
                            .depotId(s.getDepot().getId())
                            .depotNom(s.getDepot().getNom() != null ? s.getDepot().getNom() : s.getDepot().getLibelleDepot())
                            .depotLatitude(s.getDepot().getLatitude())
                            .depotLongitude(s.getDepot().getLongitude())
                            .quantiteDisponible(s.getActualQuantity())
                            .build())
                    .collect(Collectors.toList());

            BigDecimal totalStock = depotStocks.stream()
                    .map(ProductStockInfoDTO.DepotStockDTO::getQuantiteDisponible)
                    .reduce(BigDecimal.ZERO, BigDecimal::add);

            result.add(ProductStockInfoDTO.builder()
                    .produitId(produit.getId())
                    .produitNom(produit.getName())
                    .produitReference(produit.getReference())
                    .prixHT(produit.getPriceUht())
                    .depotStocks(depotStocks)
                    .totalStock(totalStock)
                    .build());
        }

        // Sort by product name
        result.sort(Comparator.comparing(ProductStockInfoDTO::getProduitNom, 
                Comparator.nullsLast(String::compareToIgnoreCase)));
        return result;
    }

    @Override
    @Transactional
    public Map<String, Object> generateCollectionPlan(Long orderId, Long societeId) {
        // Check if order already has a manual collection plan set by admin
        Order order = orderRepository.findByIdWithItems(orderId).orElse(null);
        if (order != null && order.getCollectionPlan() != null && !order.getCollectionPlan().isBlank()) {
            // Return the existing manual plan — do NOT overwrite
            try {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> existingSteps = objectMapper.readValue(
                        order.getCollectionPlan(),
                        objectMapper.getTypeFactory().constructCollectionType(List.class, Map.class));
                Map<String, Object> result = new HashMap<>();
                result.put("orderId", orderId);
                result.put("totalDepots", existingSteps.size());
                result.put("collectionSteps", existingSteps);
                result.put("manualPlan", true);
                return result;
            } catch (Exception e) {
                // If parsing fails, fall through to auto-generation
            }
        }

        // Delegate to the optimal algorithm (min depots + shortest path)
        // even for a single order – avoids the old "max stock first" greedy approach
        Map<String, Object> optimalResult = generateOptimalCollectionPlan(
                List.of(orderId), societeId, null, null);

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> mergedSteps = (List<Map<String, Object>>)
                optimalResult.getOrDefault("mergedSteps", new ArrayList<>());

        // Re-index steps starting at 1 for backward compatibility
        for (int i = 0; i < mergedSteps.size(); i++) {
            mergedSteps.get(i).put("step", i + 1);
        }

        // Save auto-generated collection plan to order
        if (order != null) {
            try {
                String planJson = objectMapper.writeValueAsString(mergedSteps);
                order.setCollectionPlan(planJson);
                orderRepository.save(order);
            } catch (Exception e) {
                // Ignore serialization error
            }
        }

        Map<String, Object> result = new HashMap<>();
        result.put("orderId", orderId);
        result.put("totalDepots", mergedSteps.size());
        result.put("collectionSteps", mergedSteps);
        return result;
    }

    // =========================================================================
    //  OPTIMAL COLLECTION PLAN: min-depot set cover + shortest route
    // =========================================================================

    @Override
    @Transactional
    public Map<String, Object> generateOptimalCollectionPlan(List<Long> orderIds, Long societeId,
                                                              Double livreurLat, Double livreurLon) {
        // 1. Load all orders
        List<Order> orders = orderRepository.findByIdsWithItems(orderIds);
        if (orders.isEmpty()) {
            Map<String, Object> empty = new HashMap<>();
            empty.put("totalDepots", 0);
            empty.put("totalOrders", 0);
            empty.put("mergedSteps", new ArrayList<>());
            return empty;
        }

        // ── Separate orders with existing manual plans from those needing auto ──
        List<Order> manualOrders = new ArrayList<>();
        List<Order> autoOrders = new ArrayList<>();
        List<Map<String, Object>> manualSteps = new ArrayList<>();

        for (Order order : orders) {
            if (order.getCollectionPlan() != null && !order.getCollectionPlan().isBlank()) {
                manualOrders.add(order);
                // Parse existing manual plan into mergedSteps format
                try {
                    @SuppressWarnings("unchecked")
                    List<Map<String, Object>> steps = objectMapper.readValue(
                            order.getCollectionPlan(),
                            objectMapper.getTypeFactory().constructCollectionType(List.class, Map.class));
                    // Ensure each step has orderIds containing this order
                    for (Map<String, Object> step : steps) {
                        step.putIfAbsent("orderIds", List.of(order.getId()));
                        // Tag items with orderId if missing
                        @SuppressWarnings("unchecked")
                        List<Map<String, Object>> items = (List<Map<String, Object>>) step.getOrDefault("items", new ArrayList<>());
                        for (Map<String, Object> item : items) {
                            item.putIfAbsent("orderId", order.getId());
                        }
                    }
                    manualSteps.addAll(steps);
                } catch (Exception e) {
                    // If parse fails, treat as auto
                    autoOrders.add(order);
                }
            } else {
                autoOrders.add(order);
            }
        }

        // ── Auto-generate plan for orders without manual plans ──
        List<Map<String, Object>> autoSteps = new ArrayList<>();
        if (!autoOrders.isEmpty()) {
            autoSteps = generateAutoSteps(autoOrders, societeId, livreurLat, livreurLon);

            // Save auto-generated plan per order so future calls skip re-computation
            for (Order autoOrder : autoOrders) {
                try {
                    // Filter steps relevant to this order
                    List<Map<String, Object>> orderSteps = new ArrayList<>();
                    for (Map<String, Object> step : autoSteps) {
                        @SuppressWarnings("unchecked")
                        List<Object> stepOrderIds = (List<Object>) step.getOrDefault("orderIds", new ArrayList<>());
                        boolean relevant = stepOrderIds.stream()
                                .anyMatch(oid -> ((Number) oid).longValue() == autoOrder.getId());
                        if (relevant) {
                            // Copy step but filter items for this order only
                            Map<String, Object> orderStep = new LinkedHashMap<>(step);
                            @SuppressWarnings("unchecked")
                            List<Map<String, Object>> allItems = (List<Map<String, Object>>) step.getOrDefault("items", new ArrayList<>());
                            List<Map<String, Object>> orderItems = allItems.stream()
                                    .filter(item -> {
                                        Object oid = item.get("orderId");
                                        return oid != null && ((Number) oid).longValue() == autoOrder.getId();
                                    })
                                    .toList();
                            orderStep.put("items", new ArrayList<>(orderItems));
                            orderStep.put("orderIds", List.of(autoOrder.getId()));
                            orderSteps.add(orderStep);
                        }
                    }
                    if (!orderSteps.isEmpty()) {
                        String planJson = objectMapper.writeValueAsString(orderSteps);
                        autoOrder.setCollectionPlan(planJson);
                        orderRepository.save(autoOrder);
                    }
                } catch (Exception e) {
                    // Ignore save errors, plan is still returned
                }
            }
        }

        // ── Merge manual + auto steps, combining by depot ──
        List<Map<String, Object>> allSteps = new ArrayList<>();
        allSteps.addAll(manualSteps);
        allSteps.addAll(autoSteps);
        allSteps = mergeStepsByDepot(allSteps);

        // Order steps by nearest-neighbor from livreur position
        allSteps = orderStepsByNearest(allSteps, livreurLat, livreurLon);

        // Re-index steps
        for (int i = 0; i < allSteps.size(); i++) {
            allSteps.get(i).put("step", i);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("totalDepots", allSteps.size());
        result.put("totalOrders", orderIds.size());
        result.put("mergedSteps", allSteps);
        result.put("manualCount", manualOrders.size());
        result.put("autoCount", autoOrders.size());
        return result;
    }

    /**
     * Core auto-generation algorithm: min-depot set cover + shortest route.
     * Extracted so it can be called only for orders needing auto-generation.
     */
    private List<Map<String, Object>> generateAutoSteps(List<Order> orders, Long societeId,
                                                         Double livreurLat, Double livreurLon) {
        // 2. Aggregate demand: for each (orderId, productId) → quantity needed
        List<DemandEntry> demands = new ArrayList<>();
        for (Order order : orders) {
            for (OrderItem item : order.getItems()) {
                if (item.getProduit() == null) continue;
                demands.add(new DemandEntry(
                    order.getId(), item.getProduit().getId(),
                    item.getProduit().getName(), item.getActualQuantity()
                ));
            }
        }
        if (demands.isEmpty()) {
            return new ArrayList<>();
        }

        // Aggregate by productId across orders: total needed per product
        Map<Long, Integer> totalDemandByProduct = new LinkedHashMap<>();
        for (DemandEntry d : demands) {
            totalDemandByProduct.merge(d.productId, d.quantity, Integer::sum);
        }

        // 3. Load stock for ALL needed products in a single batch query (avoids N+1)
        Map<Long, List<Stock>> stockByProduct = new LinkedHashMap<>();
        Set<Long> candidateDepotIds = new LinkedHashSet<>();
        Map<Long, Depot> depotMap = new LinkedHashMap<>();

        List<Long> productIds = new ArrayList<>(totalDemandByProduct.keySet());
        List<Stock> allStocks = stockRepository.findByProduitIdsAndSocieteId(productIds, societeId);
        // Remove stocks with null depot or zero quantity
        allStocks.removeIf(s -> s.getDepot() == null || s.getActualQuantity().intValue() <= 0);

        // Group stocks by product
        for (Stock s : allStocks) {
            Long pid = s.getProduit().getId();
            stockByProduct.computeIfAbsent(pid, k -> new ArrayList<>()).add(s);
            candidateDepotIds.add(s.getDepot().getId());
            depotMap.put(s.getDepot().getId(), s.getDepot());
        }

        List<Long> candidateList = new ArrayList<>(candidateDepotIds);
        int numCandidates = candidateList.size();

        // 4. For each candidate depot, build a stock map: depotId → {productId → available_qty}
        Map<Long, Map<Long, Integer>> depotStock = new LinkedHashMap<>();
        for (Long depotId : candidateList) {
            depotStock.put(depotId, new HashMap<>());
        }
        for (Map.Entry<Long, List<Stock>> entry : stockByProduct.entrySet()) {
            Long productId = entry.getKey();
            for (Stock s : entry.getValue()) {
                depotStock.get(s.getDepot().getId()).put(productId, s.getActualQuantity().intValue());
            }
        }

        // 5. Enumerate depot combinations by cardinality k = 1..min(numCandidates, MAX_K)
        //    For each combo, check if it covers ALL product demands (quantity-aware).
        //    Among covering combos of minimum k, pick the one with shortest haversine route.
        int maxK = Math.min(numCandidates, 6); // limit search space
        List<Long> bestCombo = null;
        double bestDistance = Double.MAX_VALUE;

        for (int k = 1; k <= maxK; k++) {
            List<List<Long>> combos = generateCombinations(candidateList, k);

            for (List<Long> combo : combos) {
                if (coversDemand(combo, depotStock, totalDemandByProduct)) {
                    double dist = estimateRouteDistance(combo, depotMap, livreurLat, livreurLon);
                    if (dist < bestDistance) {
                        bestDistance = dist;
                        bestCombo = combo;
                    }
                }
            }

            // Lexicographic: once we find any solution at cardinality k, stop
            if (bestCombo != null) break;
        }

        // 6. Fallback: if no exact cover found (e.g. too many depots), use greedy
        if (bestCombo == null) {
            bestCombo = greedyCover(candidateList, depotStock, totalDemandByProduct, depotMap, livreurLat, livreurLon);
        }

        // 7. Allocate products to chosen depots
        List<Map<String, Object>> mergedSteps = allocateAndBuildSteps(
            bestCombo, depotStock, depotMap, demands
        );

        return mergedSteps;
    }

    /**
     * Merge steps targeting the same depot: combine items and orderIds.
     */
    private List<Map<String, Object>> mergeStepsByDepot(List<Map<String, Object>> steps) {
        Map<Object, Map<String, Object>> byDepot = new LinkedHashMap<>();
        for (Map<String, Object> step : steps) {
            Object depotId = step.get("depotId");
            if (depotId == null) continue;
            if (byDepot.containsKey(depotId)) {
                Map<String, Object> existing = byDepot.get(depotId);
                // Merge items
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> existingItems = (List<Map<String, Object>>) existing.getOrDefault("items", new ArrayList<>());
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> newItems = (List<Map<String, Object>>) step.getOrDefault("items", new ArrayList<>());
                existingItems.addAll(newItems);
                existing.put("items", existingItems);
                // Merge orderIds
                @SuppressWarnings("unchecked")
                List<Object> existingOids = new ArrayList<>((List<Object>) existing.getOrDefault("orderIds", new ArrayList<>()));
                @SuppressWarnings("unchecked")
                List<Object> newOids = (List<Object>) step.getOrDefault("orderIds", new ArrayList<>());
                for (Object oid : newOids) {
                    if (!existingOids.contains(oid)) existingOids.add(oid);
                }
                existing.put("orderIds", existingOids);
            } else {
                byDepot.put(depotId, new LinkedHashMap<>(step));
            }
        }
        return new ArrayList<>(byDepot.values());
    }

    // ---- Helper classes & methods ----

    private record DemandEntry(Long orderId, Long productId, String productName, int quantity) {}

    /**
     * Check if a set of depots can cover ALL product demands (quantity-aware).
     */
    private boolean coversDemand(List<Long> depotIds, Map<Long, Map<Long, Integer>> depotStock,
                                  Map<Long, Integer> totalDemandByProduct) {
        for (Map.Entry<Long, Integer> entry : totalDemandByProduct.entrySet()) {
            Long productId = entry.getKey();
            int needed = entry.getValue();
            int available = 0;
            for (Long depotId : depotIds) {
                available += depotStock.getOrDefault(depotId, Map.of()).getOrDefault(productId, 0);
            }
            if (available < needed) return false;
        }
        return true;
    }

    /**
     * Estimate total route distance for livreur → depot1 → depot2 → ... using nearest-neighbor.
     * Uses OSRM /table API for real road durations; falls back to haversine if OSRM is unavailable.
     * Returns a cost value (OSRM: seconds of travel time, haversine: km).
     */
    private double estimateRouteDistance(List<Long> depotIds, Map<Long, Depot> depotMap,
                                         Double livreurLat, Double livreurLon) {
        if (depotIds.isEmpty()) return 0;
        if (livreurLat == null || livreurLon == null) {
            return depotIds.size(); // prefer fewer depots when no position
        }

        // Build coordinate list: index 0 = livreur, 1..N = depots
        List<double[]> coords = new ArrayList<>();
        coords.add(new double[]{livreurLat, livreurLon});
        List<Integer> validDepotIndices = new ArrayList<>();
        for (Long id : depotIds) {
            Depot d = depotMap.get(id);
            if (d != null && d.getLatitude() != null && d.getLongitude() != null) {
                coords.add(new double[]{d.getLatitude(), d.getLongitude()});
                validDepotIndices.add(coords.size() - 1);
            }
        }
        if (validDepotIndices.isEmpty()) return Double.MAX_VALUE;

        // --- Try OSRM /table first ---
        OsrmService.TableResult table = osrmService.getTable(coords);
        if (table != null && table.durations() != null) {
            // nearest-neighbor on the OSRM duration matrix
            double totalCost = 0;
            int cur = 0; // start at livreur (index 0)
            boolean[] visited = new boolean[coords.size()];
            visited[0] = true;

            for (int i = 0; i < validDepotIndices.size(); i++) {
                double minD = Double.MAX_VALUE;
                int nearest = validDepotIndices.get(0);
                for (int idx : validDepotIndices) {
                    if (visited[idx]) continue;
                    double d = table.durations()[cur][idx];
                    if (d < minD) { minD = d; nearest = idx; }
                }
                visited[nearest] = true;
                totalCost += minD;
                cur = nearest;
            }
            return totalCost; // seconds
        }

        // --- Haversine fallback ---
        log.debug("OSRM /table unavailable, falling back to haversine for estimateRouteDistance");
        double totalDist = 0;
        double curLat = livreurLat, curLon = livreurLon;
        List<double[]> points = coords.subList(1, coords.size()); // skip livreur
        boolean[] visited = new boolean[points.size()];

        for (int i = 0; i < points.size(); i++) {
            double minD = Double.MAX_VALUE;
            int nearest = 0;
            for (int j = 0; j < points.size(); j++) {
                if (visited[j]) continue;
                double d = haversine(curLat, curLon, points.get(j)[0], points.get(j)[1]);
                if (d < minD) { minD = d; nearest = j; }
            }
            visited[nearest] = true;
            totalDist += minD;
            curLat = points.get(nearest)[0];
            curLon = points.get(nearest)[1];
        }
        return totalDist;
    }

    /**
     * Generate all C(n,k) combinations.
     */
    private List<List<Long>> generateCombinations(List<Long> items, int k) {
        List<List<Long>> result = new ArrayList<>();
        combinationsHelper(items, k, 0, new ArrayList<>(), result);
        return result;
    }

    private void combinationsHelper(List<Long> items, int k, int start, List<Long> current, List<List<Long>> result) {
        if (current.size() == k) {
            result.add(new ArrayList<>(current));
            return;
        }
        for (int i = start; i < items.size(); i++) {
            current.add(items.get(i));
            combinationsHelper(items, k, i + 1, current, result);
            current.remove(current.size() - 1);
        }
    }

    /**
     * Greedy fallback: when numCandidates > MAX_K, greedily add depot that covers most remaining demand.
     */
    private List<Long> greedyCover(List<Long> candidates, Map<Long, Map<Long, Integer>> depotStock,
                                    Map<Long, Integer> totalDemandByProduct, Map<Long, Depot> depotMap,
                                    Double livreurLat, Double livreurLon) {
        Map<Long, Integer> remaining = new LinkedHashMap<>(totalDemandByProduct);
        List<Long> chosen = new ArrayList<>();

        while (!remaining.isEmpty()) {
            Long bestDepot = null;
            int bestScore = 0;
            double bestDist = Double.MAX_VALUE;

            for (Long depotId : candidates) {
                if (chosen.contains(depotId)) continue;
                Map<Long, Integer> stock = depotStock.getOrDefault(depotId, Map.of());
                int score = 0;
                for (Map.Entry<Long, Integer> req : remaining.entrySet()) {
                    int avail = stock.getOrDefault(req.getKey(), 0);
                    score += Math.min(avail, req.getValue());
                }
                if (score > 0) {
                    Depot d = depotMap.get(depotId);
                    double dist = (d != null && d.getLatitude() != null && livreurLat != null)
                            ? haversine(livreurLat, livreurLon, d.getLatitude(), d.getLongitude()) : 0;
                    // Pick depot with highest coverage, break ties by distance
                    if (score > bestScore || (score == bestScore && dist < bestDist)) {
                        bestDepot = depotId;
                        bestScore = score;
                        bestDist = dist;
                    }
                }
            }

            if (bestDepot == null) break;
            chosen.add(bestDepot);

            // Subtract what this depot provides
            Map<Long, Integer> stock = depotStock.getOrDefault(bestDepot, Map.of());
            Iterator<Map.Entry<Long, Integer>> it = remaining.entrySet().iterator();
            while (it.hasNext()) {
                Map.Entry<Long, Integer> req = it.next();
                int avail = stock.getOrDefault(req.getKey(), 0);
                int nowNeeded = req.getValue() - avail;
                if (nowNeeded <= 0) {
                    it.remove();
                } else {
                    req.setValue(nowNeeded);
                }
            }
        }
        return chosen;
    }

    /**
     * Allocate per-order items to the chosen depots and build steps.
     */
    private List<Map<String, Object>> allocateAndBuildSteps(List<Long> chosenDepots,
                                                             Map<Long, Map<Long, Integer>> depotStock,
                                                             Map<Long, Depot> depotMap,
                                                             List<DemandEntry> demands) {
        // Track remaining stock so we don't over-allocate
        Map<String, Integer> remaining = new HashMap<>();
        for (Long depotId : chosenDepots) {
            Map<Long, Integer> stock = depotStock.getOrDefault(depotId, Map.of());
            for (Map.Entry<Long, Integer> e : stock.entrySet()) {
                remaining.put(depotId + ":" + e.getKey(), e.getValue());
            }
        }

        // For each demand, allocate to chosen depots (prefer depot with most stock to minimize splits)
        Map<Long, List<Map<String, Object>>> depotItems = new LinkedHashMap<>();
        Map<Long, Set<Long>> depotOrderIds = new LinkedHashMap<>();

        for (DemandEntry demand : demands) {
            int needed = demand.quantity;
            // Sort chosen depots by available stock for this product (descending)
            List<Long> sorted = new ArrayList<>(chosenDepots);
            sorted.sort((a, b) -> {
                int stockA = remaining.getOrDefault(a + ":" + demand.productId, 0);
                int stockB = remaining.getOrDefault(b + ":" + demand.productId, 0);
                return Integer.compare(stockB, stockA);
            });

            for (Long depotId : sorted) {
                if (needed <= 0) break;
                String key = depotId + ":" + demand.productId;
                int avail = remaining.getOrDefault(key, 0);
                if (avail <= 0) continue;

                int take = Math.min(needed, avail);
                remaining.put(key, avail - take);
                needed -= take;

                depotItems.computeIfAbsent(depotId, k -> new ArrayList<>());
                Map<String, Object> itemInfo = new HashMap<>();
                itemInfo.put("produitId", demand.productId);
                itemInfo.put("produitNom", demand.productName);
                itemInfo.put("quantite", take);
                itemInfo.put("orderId", demand.orderId);
                depotItems.get(depotId).add(itemInfo);

                depotOrderIds.computeIfAbsent(depotId, k -> new LinkedHashSet<>());
                depotOrderIds.get(depotId).add(demand.orderId);
            }
        }

        // Build steps
        List<Map<String, Object>> steps = new ArrayList<>();
        for (Long depotId : chosenDepots) {
            if (!depotItems.containsKey(depotId)) continue;
            Depot depot = depotMap.get(depotId);
            if (depot == null) continue;

            Map<String, Object> step = new HashMap<>();
            step.put("depotId", depotId);
            step.put("depotNom", depot.getNom() != null ? depot.getNom() : depot.getLibelleDepot());
            step.put("depotLatitude", depot.getLatitude());
            step.put("depotLongitude", depot.getLongitude());
            step.put("items", depotItems.get(depotId));
            step.put("orderIds", new ArrayList<>(depotOrderIds.getOrDefault(depotId, new LinkedHashSet<>())));
            steps.add(step);
        }
        return steps;
    }

    /**
     * Order steps by optimal route from livreur position.
     * Uses OSRM /trip (TSP) API; falls back to haversine nearest-neighbor.
     */
    private List<Map<String, Object>> orderStepsByNearest(List<Map<String, Object>> steps,
                                                           Double livreurLat, Double livreurLon) {
        if (steps.size() <= 1 || livreurLat == null || livreurLon == null) return steps;

        // Build coordinate list: index 0 = livreur, 1..N = depots
        List<double[]> coords = new ArrayList<>();
        coords.add(new double[]{livreurLat, livreurLon});
        for (Map<String, Object> step : steps) {
            Double lat = (Double) step.get("depotLatitude");
            Double lon = (Double) step.get("depotLongitude");
            coords.add(new double[]{
                lat != null ? lat : 0,
                lon != null ? lon : 0
            });
        }

        // --- Try OSRM /trip (TSP) first ---
        OsrmService.TripResult trip = osrmService.getTrip(coords, false);
        if (trip != null && trip.waypointOrder() != null) {
            // trip returns ordered indices into coords (includes index 0 = livreur)
            List<Map<String, Object>> ordered = new ArrayList<>();
            for (int idx : trip.waypointOrder()) {
                if (idx == 0) continue; // skip livreur waypoint
                int stepIdx = idx - 1;  // map back to steps index
                if (stepIdx >= 0 && stepIdx < steps.size()) {
                    ordered.add(steps.get(stepIdx));
                }
            }
            // If OSRM returned all steps, use that order
            if (ordered.size() == steps.size()) {
                return ordered;
            }
        }

        // --- Haversine nearest-neighbor fallback ---
        log.debug("OSRM /trip unavailable, falling back to haversine for orderStepsByNearest");
        List<Map<String, Object>> ordered = new ArrayList<>();
        boolean[] used = new boolean[steps.size()];
        double curLat = livreurLat, curLon = livreurLon;

        for (int i = 0; i < steps.size(); i++) {
            double minD = Double.MAX_VALUE;
            int nearest = 0;
            for (int j = 0; j < steps.size(); j++) {
                if (used[j]) continue;
                Double lat = (Double) steps.get(j).get("depotLatitude");
                Double lon = (Double) steps.get(j).get("depotLongitude");
                if (lat == null || lon == null) continue;
                double d = haversine(curLat, curLon, lat, lon);
                if (d < minD) { minD = d; nearest = j; }
            }
            used[nearest] = true;
            ordered.add(steps.get(nearest));
            Double lat = (Double) steps.get(nearest).get("depotLatitude");
            Double lon = (Double) steps.get(nearest).get("depotLongitude");
            if (lat != null && lon != null) { curLat = lat; curLon = lon; }
        }
        return ordered;
    }

    /**
     * Haversine distance in km.
     */
    private static double haversine(double lat1, double lon1, double lat2, double lon2) {
        double R = 6371.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    // =========================================================================
    //  LIVREUR RECOMMENDATION: rank livreurs by OSRM travel time (or haversine fallback)
    // =========================================================================

    @Override
    @Transactional(readOnly = true)
    public List<Map<String, Object>> recommendLivreursForOrder(Long orderId, Long societeId) {
        // 1. Get the order
        Order order = orderRepository.findByIdWithItems(orderId).orElse(null);
        if (order == null) return List.of();

        // 2. Get the collection plan for this order (what depots to visit)
        List<double[]> collectionPoints = new ArrayList<>();
        if (order.getCollectionPlan() != null && !order.getCollectionPlan().isBlank()) {
            try {
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> steps = objectMapper.readValue(
                        order.getCollectionPlan(),
                        objectMapper.getTypeFactory().constructCollectionType(List.class, Map.class));
                for (Map<String, Object> step : steps) {
                    Number lat = (Number) step.get("depotLatitude");
                    Number lon = (Number) step.get("depotLongitude");
                    if (lat != null && lon != null) {
                        collectionPoints.add(new double[]{lat.doubleValue(), lon.doubleValue()});
                    }
                }
            } catch (Exception e) {
                // Ignore parse errors
            }
        }

        // If no collection plan yet, generate one to know which depots
        if (collectionPoints.isEmpty()) {
            try {
                Map<String, Object> plan = generateCollectionPlan(orderId, societeId);
                @SuppressWarnings("unchecked")
                List<Map<String, Object>> steps = (List<Map<String, Object>>) plan.getOrDefault("collectionSteps", new ArrayList<>());
                for (Map<String, Object> step : steps) {
                    Number lat = (Number) step.get("depotLatitude");
                    Number lon = (Number) step.get("depotLongitude");
                    if (lat != null && lon != null) {
                        collectionPoints.add(new double[]{lat.doubleValue(), lon.doubleValue()});
                    }
                }
            } catch (Exception e) {
                // Ignore
            }
        }

        // 3. Delivery point
        Double deliveryLat = order.getLatitudeLivraison();
        Double deliveryLon = order.getLongitudeLivraison();

        // 4. Get all active livreurs with known position
        List<Utilisateur> livreurs = utilisateurRepository.findLivreursWithPositionBySocieteId(societeId);

        // 5. Score each livreur: OSRM route travel time (livreur → depots → delivery)
        //    Falls back to haversine distance if OSRM is unavailable
        List<Map<String, Object>> ranked = new ArrayList<>();
        for (Utilisateur livreur : livreurs) {
            double livreurLat = livreur.getLatitude();
            double livreurLon = livreur.getLongitude();

            // Build ordered coordinate sequence: livreur → depot1 → ... → depotN → delivery
            List<double[]> routeCoords = new ArrayList<>();
            routeCoords.add(new double[]{livreurLat, livreurLon});
            routeCoords.addAll(collectionPoints);
            if (deliveryLat != null && deliveryLon != null) {
                routeCoords.add(new double[]{deliveryLat, deliveryLon});
            }

            double totalTimeMinutes = -1;
            double totalDistanceKm = -1;

            // --- Try OSRM /route first ---
            if (routeCoords.size() >= 2) {
                OsrmService.RouteResult route = osrmService.getRoute(routeCoords);
                if (route != null) {
                    totalTimeMinutes = route.totalDurationSeconds() / 60.0;
                    totalDistanceKm = route.totalDistanceMeters() / 1000.0;
                }
            }

            // --- Haversine fallback ---
            if (totalTimeMinutes < 0) {
                double totalHaversineKm = 0;
                double curLat = livreurLat, curLon = livreurLon;
                for (double[] pt : collectionPoints) {
                    totalHaversineKm += haversine(curLat, curLon, pt[0], pt[1]);
                    curLat = pt[0];
                    curLon = pt[1];
                }
                if (deliveryLat != null && deliveryLon != null) {
                    totalHaversineKm += haversine(curLat, curLon, deliveryLat, deliveryLon);
                }
                totalDistanceKm = totalHaversineKm;
                // Rough estimate: 30 km/h average in Tunisia urban areas
                totalTimeMinutes = (totalHaversineKm / 30.0) * 60.0;
            }

            // Count current active orders for this livreur (workload)
            long activeOrderCount = orderRepository.findByLivreurIdAndStatusIn(
                    livreur.getId(), List.of("en_cours", "processing", "shipped", "assigned")
            ).size();

            // Score: travel time in minutes + workload penalty
            double score = totalTimeMinutes + (activeOrderCount * workloadPenaltyMinutes);

            Map<String, Object> entry = new LinkedHashMap<>();
            entry.put("livreurId", livreur.getId());
            entry.put("livreurNom", (livreur.getNom() + " " + livreur.getPrenom()).trim());
            entry.put("livreurLatitude", livreur.getLatitude());
            entry.put("livreurLongitude", livreur.getLongitude());
            entry.put("dernierePositionAt", livreur.getDernierePositionAt() != null ? livreur.getDernierePositionAt().toString() : null);
            entry.put("distanceTotaleKm", Math.round(totalDistanceKm * 100.0) / 100.0);
            entry.put("tempsEstimeMinutes", Math.round(totalTimeMinutes * 10.0) / 10.0);
            entry.put("commandesActives", activeOrderCount);
            entry.put("score", Math.round(score * 10.0) / 10.0);
            entry.put("telephone", livreur.getTelephone());

            ranked.add(entry);
        }

        // Sort by score (ascending = best first)
        ranked.sort((a, b) -> Double.compare(((Number) a.get("score")).doubleValue(), ((Number) b.get("score")).doubleValue()));

        // Add rank
        for (int i = 0; i < ranked.size(); i++) {
            ranked.get(i).put("rang", i + 1);
            ranked.get(i).put("recommended", i == 0);
        }

        return ranked;
    }
}
