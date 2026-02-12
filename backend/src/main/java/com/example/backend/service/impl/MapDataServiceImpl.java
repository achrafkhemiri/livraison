package com.example.backend.service.impl;

import com.example.backend.dto.MapDataDTO;
import com.example.backend.dto.ProductStockInfoDTO;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.model.*;
import com.example.backend.repository.*;
import com.example.backend.service.MapDataService;
import tools.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
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

    private final SocieteRepository societeRepository;
    private final MagasinRepository magasinRepository;
    private final DepotRepository depotRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final StockRepository stockRepository;
    private final OrderRepository orderRepository;
    private final ObjectMapper objectMapper;

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
        Order order = orderRepository.findByIdWithItems(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order", "id", orderId));

        List<Map<String, Object>> collectionSteps = new ArrayList<>();
        Map<Long, List<Map<String, Object>>> itemsByDepot = new LinkedHashMap<>();

        // For each item in the order, find the best depot (most stock)
        for (OrderItem item : order.getItems()) {
            if (item.getProduit() == null) continue;

            List<Stock> available = new ArrayList<>(stockRepository.findByProduitIdAndSocieteId(
                    item.getProduit().getId(), societeId));

            if (!available.isEmpty()) {
                // Sort by quantity descending - pick depot with most stock
                available.sort((a, b) -> b.getActualQuantity().compareTo(a.getActualQuantity()));
                
                int remaining = item.getActualQuantity();
                for (Stock stock : available) {
                    if (remaining <= 0) break;
                    
                    int canTake = Math.min(remaining, stock.getActualQuantity().intValue());
                    if (canTake <= 0) continue;
                    
                    Long depotId = stock.getDepot().getId();
                    itemsByDepot.computeIfAbsent(depotId, k -> new ArrayList<>());
                    
                    Map<String, Object> itemInfo = new HashMap<>();
                    itemInfo.put("produitId", item.getProduit().getId());
                    itemInfo.put("produitNom", item.getProduit().getName());
                    itemInfo.put("quantite", canTake);
                    itemInfo.put("depotId", depotId);
                    itemInfo.put("depotNom", stock.getDepot().getNom() != null ? 
                            stock.getDepot().getNom() : stock.getDepot().getLibelleDepot());
                    itemInfo.put("depotLatitude", stock.getDepot().getLatitude());
                    itemInfo.put("depotLongitude", stock.getDepot().getLongitude());
                    
                    itemsByDepot.get(depotId).add(itemInfo);
                    remaining -= canTake;
                }
            }
        }

        // Build collection steps per depot
        int stepIndex = 1;
        for (Map.Entry<Long, List<Map<String, Object>>> entry : itemsByDepot.entrySet()) {
            List<Map<String, Object>> items = entry.getValue();
            if (items.isEmpty()) continue;
            
            Map<String, Object> step = new HashMap<>();
            step.put("step", stepIndex++);
            step.put("depotId", entry.getKey());
            step.put("depotNom", items.get(0).get("depotNom"));
            step.put("depotLatitude", items.get(0).get("depotLatitude"));
            step.put("depotLongitude", items.get(0).get("depotLongitude"));
            step.put("items", items);
            collectionSteps.add(step);
        }

        // Save collection plan to order
        try {
            String planJson = objectMapper.writeValueAsString(collectionSteps);
            order.setCollectionPlan(planJson);
            orderRepository.save(order);
        } catch (Exception e) {
            // Ignore serialization error
        }

        Map<String, Object> result = new HashMap<>();
        result.put("orderId", orderId);
        result.put("totalDepots", collectionSteps.size());
        result.put("collectionSteps", collectionSteps);
        return result;
    }
}
