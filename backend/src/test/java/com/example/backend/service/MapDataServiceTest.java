package com.example.backend.service;

import com.example.backend.dto.MapDataDTO;
import com.example.backend.dto.ProductStockInfoDTO;
import com.example.backend.model.*;
import com.example.backend.repository.*;
import com.example.backend.service.impl.MapDataServiceImpl;
import tools.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.Spy;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class MapDataServiceTest {

    @Mock
    private SocieteRepository societeRepository;
    @Mock
    private MagasinRepository magasinRepository;
    @Mock
    private DepotRepository depotRepository;
    @Mock
    private UtilisateurRepository utilisateurRepository;
    @Mock
    private StockRepository stockRepository;
    @Mock
    private OrderRepository orderRepository;
    @Spy
    private ObjectMapper objectMapper = new ObjectMapper();

    @InjectMocks
    private MapDataServiceImpl mapDataService;

    private Societe societe;
    private Magasin magasin;
    private Depot depot;
    private Produit produit;

    @BeforeEach
    void setUp() {
        societe = new Societe();
        societe.setId(1L);
        societe.setRaisonSociale("Test Société");
        societe.setLatitude(34.74);
        societe.setLongitude(10.76);

        magasin = new Magasin();
        magasin.setId(1L);
        magasin.setNomMagasin("Magasin A");
        magasin.setSociete(societe);
        magasin.setLatitude(34.75);
        magasin.setLongitude(10.77);
        magasin.setVille("Sfax");
        magasin.setAdresse("Rue 1");

        depot = new Depot();
        depot.setId(1L);
        depot.setNom("Dépôt Central");
        depot.setCode("D001");
        depot.setLibelleDepot("Dépôt Central Sfax");
        depot.setMagasin(magasin);
        depot.setLatitude(34.76);
        depot.setLongitude(10.78);
        depot.setActif(true);

        produit = new Produit();
        produit.setId(1L);
        produit.setName("Produit Test");
        produit.setReference("REF001");
        produit.setPriceUht(BigDecimal.valueOf(25.50));
    }

    @Test
    void getMapData_shouldReturnAllMarkers() {
        // Given
        when(societeRepository.findById(1L)).thenReturn(Optional.of(societe));
        when(magasinRepository.findBySocieteId(1L)).thenReturn(List.of(magasin));
        when(depotRepository.findBySocieteId(1L)).thenReturn(List.of(depot));

        Utilisateur livreur = new Utilisateur();
        livreur.setId(1L);
        livreur.setNom("Dupont");
        livreur.setPrenom("Jean");
        livreur.setLatitude(34.77);
        livreur.setLongitude(10.79);
        livreur.setDernierePositionAt(LocalDateTime.now());
        when(utilisateurRepository.findLivreursWithPositionBySocieteId(1L)).thenReturn(List.of(livreur));

        // When
        MapDataDTO result = mapDataService.getMapData(1L);

        // Then
        assertThat(result).isNotNull();

        // Société
        assertThat(result.getSociete()).isNotNull();
        assertThat(result.getSociete().getNom()).isEqualTo("Test Société");
        assertThat(result.getSociete().getLatitude()).isEqualTo(34.74);

        // Magasins
        assertThat(result.getMagasins()).hasSize(1);
        assertThat(result.getMagasins().get(0).getNom()).isEqualTo("Magasin A");

        // Depots
        assertThat(result.getDepots()).hasSize(1);
        assertThat(result.getDepots().get(0).getCode()).isEqualTo("D001");

        // Livreurs
        assertThat(result.getLivreurs()).hasSize(1);
        assertThat(result.getLivreurs().get(0).getNom()).isEqualTo("Dupont");
    }

    @Test
    void getMapData_shouldFilterOutNullCoordinates() {
        // Given
        when(societeRepository.findById(1L)).thenReturn(Optional.of(societe));

        Magasin magasinNoCoords = new Magasin();
        magasinNoCoords.setId(2L);
        magasinNoCoords.setNomMagasin("Magasin sans coords");
        // No latitude/longitude set

        when(magasinRepository.findBySocieteId(1L)).thenReturn(List.of(magasin, magasinNoCoords));
        when(depotRepository.findBySocieteId(1L)).thenReturn(List.of());
        when(utilisateurRepository.findLivreursWithPositionBySocieteId(1L)).thenReturn(List.of());

        // When
        MapDataDTO result = mapDataService.getMapData(1L);

        // Then
        assertThat(result.getMagasins()).hasSize(1);
        assertThat(result.getMagasins().get(0).getNom()).isEqualTo("Magasin A");
    }

    @Test
    void getProductsWithStockBySociete_shouldGroupByProduct() {
        // Given
        Stock stock1 = new Stock();
        stock1.setId(1L);
        stock1.setProduit(produit);
        stock1.setDepot(depot);
        stock1.setQuantity(100);

        Depot depot2 = new Depot();
        depot2.setId(2L);
        depot2.setNom("Dépôt 2");
        depot2.setLatitude(34.80);
        depot2.setLongitude(10.80);

        Stock stock2 = new Stock();
        stock2.setId(2L);
        stock2.setProduit(produit);
        stock2.setDepot(depot2);
        stock2.setQuantity(50);

        when(stockRepository.findAvailableStockBySocieteId(1L)).thenReturn(List.of(stock1, stock2));

        // When
        List<ProductStockInfoDTO> result = mapDataService.getProductsWithStockBySociete(1L);

        // Then
        assertThat(result).hasSize(1);
        assertThat(result.get(0).getProduitId()).isEqualTo(1L);
        assertThat(result.get(0).getProduitNom()).isEqualTo("Produit Test");
        assertThat(result.get(0).getDepotStocks()).hasSize(2);
        assertThat(result.get(0).getTotalStock()).isEqualByComparingTo(BigDecimal.valueOf(150));
    }

    @Test
    void getProductsWithStockBySociete_shouldReturnEmptyForNoStock() {
        // Given
        when(stockRepository.findAvailableStockBySocieteId(1L)).thenReturn(List.of());

        // When
        List<ProductStockInfoDTO> result = mapDataService.getProductsWithStockBySociete(1L);

        // Then
        assertThat(result).isEmpty();
    }

    @Test
    void generateCollectionPlan_shouldAssignItemsToDepots() {
        // Given
        OrderItem item = OrderItem.builder()
                .id(1L)
                .produit(produit)
                .quantity(5)
                .build();
        
        Order order = new Order();
        order.setId(1L);
        order.setItems(new ArrayList<>(List.of(item)));
        item.setOrder(order);

        when(orderRepository.findByIdWithItems(1L)).thenReturn(Optional.of(order));

        Stock stock = new Stock();
        stock.setProduit(produit);
        stock.setDepot(depot);
        stock.setQuantity(20);

        when(stockRepository.findByProduitIdAndSocieteId(eq(1L), eq(1L))).thenReturn(List.of(stock));
        when(orderRepository.save(any())).thenReturn(order);

        // When
        Map<String, Object> result = mapDataService.generateCollectionPlan(1L, 1L);

        // Then
        assertThat(result).containsKey("orderId");
        assertThat(result).containsKey("collectionSteps");
        assertThat(result.get("orderId")).isEqualTo(1L);
        
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> steps = (List<Map<String, Object>>) result.get("collectionSteps");
        assertThat(steps).hasSize(1);
        assertThat(steps.get(0).get("depotId")).isEqualTo(1L);
    }

    @Test
    void generateCollectionPlan_shouldSplitAcrossDepots() {
        // Given
        OrderItem item = OrderItem.builder()
                .id(1L)
                .produit(produit)
                .quantity(15)
                .build();
        
        Order order = new Order();
        order.setId(2L);
        order.setItems(new ArrayList<>(List.of(item)));
        item.setOrder(order);

        when(orderRepository.findByIdWithItems(2L)).thenReturn(Optional.of(order));

        Stock stock1 = new Stock();
        stock1.setProduit(produit);
        stock1.setDepot(depot);
        stock1.setQuantity(10);

        Depot depot2 = new Depot();
        depot2.setId(2L);
        depot2.setNom("Dépôt 2");
        depot2.setLatitude(34.80);
        depot2.setLongitude(10.80);

        Stock stock2 = new Stock();
        stock2.setProduit(produit);
        stock2.setDepot(depot2);
        stock2.setQuantity(8);

        when(stockRepository.findByProduitIdAndSocieteId(eq(1L), eq(1L))).thenReturn(List.of(stock1, stock2));
        when(orderRepository.save(any())).thenReturn(order);

        // When
        Map<String, Object> result = mapDataService.generateCollectionPlan(2L, 1L);

        // Then
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> steps = (List<Map<String, Object>>) result.get("collectionSteps");
        assertThat(steps).hasSize(2); // Split across 2 depots
        assertThat(result.get("totalDepots")).isEqualTo(2);
    }
}
