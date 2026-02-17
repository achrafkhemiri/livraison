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

        // Now delegates to optimal → uses findByIdsWithItems
        when(orderRepository.findByIdsWithItems(List.of(1L))).thenReturn(List.of(order));
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
        // Given — product needs 15 but depot1 only has 10, so must split
        OrderItem item = OrderItem.builder()
                .id(1L)
                .produit(produit)
                .quantity(15)
                .build();
        
        Order order = new Order();
        order.setId(2L);
        order.setItems(new ArrayList<>(List.of(item)));
        item.setOrder(order);

        when(orderRepository.findByIdsWithItems(List.of(2L))).thenReturn(List.of(order));
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

    @Test
    void generateCollectionPlan_shouldPickMinDepots_userScenario() {
        // User's exact scenario: order has products A and B.
        // A is in depot 1 AND depot 2, B is ONLY in depot 2.
        // Old algorithm picked depot 1 (more stock) for A + depot 2 for B = 2 depots.
        // Optimal should pick depot 2 alone (covers both A and B) = 1 depot.
        Produit prodA = new Produit(); prodA.setId(10L); prodA.setName("Product A");
        Produit prodB = new Produit(); prodB.setId(20L); prodB.setName("Product B");

        OrderItem itemA = OrderItem.builder().id(100L).produit(prodA).quantity(3).build();
        OrderItem itemB = OrderItem.builder().id(101L).produit(prodB).quantity(2).build();

        Order order = new Order();
        order.setId(99L);
        order.setItems(new ArrayList<>(List.of(itemA, itemB)));

        when(orderRepository.findByIdsWithItems(List.of(99L))).thenReturn(List.of(order));
        when(orderRepository.findByIdWithItems(99L)).thenReturn(Optional.of(order));
        when(orderRepository.save(any())).thenReturn(order);

        Depot depot1 = new Depot(); depot1.setId(1L); depot1.setNom("Dépôt 1"); depot1.setLatitude(34.75); depot1.setLongitude(10.76);
        Depot depot2 = new Depot(); depot2.setId(2L); depot2.setNom("Dépôt 2"); depot2.setLatitude(34.80); depot2.setLongitude(10.80);

        // Depot 1: product A qty 50 (lots of stock)  — NO product B
        Stock stockA1 = new Stock(); stockA1.setProduit(prodA); stockA1.setDepot(depot1); stockA1.setQuantity(50);
        // Depot 2: product A qty 5 + product B qty 10
        Stock stockA2 = new Stock(); stockA2.setProduit(prodA); stockA2.setDepot(depot2); stockA2.setQuantity(5);
        Stock stockB2 = new Stock(); stockB2.setProduit(prodB); stockB2.setDepot(depot2); stockB2.setQuantity(10);

        when(stockRepository.findByProduitIdAndSocieteId(eq(10L), eq(1L))).thenReturn(List.of(stockA1, stockA2));
        when(stockRepository.findByProduitIdAndSocieteId(eq(20L), eq(1L))).thenReturn(List.of(stockB2));

        // When
        Map<String, Object> result = mapDataService.generateCollectionPlan(99L, 1L);

        // Then — should pick only depot 2 (1 depot, NOT 2)
        assertThat(result.get("totalDepots")).isEqualTo(1);

        @SuppressWarnings("unchecked")
        List<Map<String, Object>> steps = (List<Map<String, Object>>) result.get("collectionSteps");
        assertThat(steps).hasSize(1);
        assertThat(steps.get(0).get("depotId")).isEqualTo(2L); // Depot 2, not depot 1
    }

    // ========================================================
    // generateOptimalCollectionPlan — min depot + shortest path
    // ========================================================

    @Test
    void optimalPlan_shouldPickMinimumDepots() {
        // Depot A has p1+p2, Depot B has p2+p3 → need {A,B} to cover all
        // but Depot C has p1+p2+p3 → should pick C alone (1 depot instead of 2)
        Produit p1 = new Produit(); p1.setId(1L); p1.setName("P1");
        Produit p2 = new Produit(); p2.setId(2L); p2.setName("P2");
        Produit p3 = new Produit(); p3.setId(3L); p3.setName("P3");

        OrderItem i1 = OrderItem.builder().id(10L).produit(p1).quantity(2).build();
        OrderItem i2 = OrderItem.builder().id(20L).produit(p2).quantity(3).build();
        OrderItem i3 = OrderItem.builder().id(30L).produit(p3).quantity(1).build();
        Order order = new Order();
        order.setId(100L);
        order.setItems(new ArrayList<>(List.of(i1, i2, i3)));
        i1.setOrder(order); i2.setOrder(order); i3.setOrder(order);

        when(orderRepository.findByIdsWithItems(List.of(100L))).thenReturn(List.of(order));

        Depot depotA = new Depot(); depotA.setId(1L); depotA.setNom("A"); depotA.setLatitude(34.70); depotA.setLongitude(10.70);
        Depot depotB = new Depot(); depotB.setId(2L); depotB.setNom("B"); depotB.setLatitude(34.72); depotB.setLongitude(10.72);
        Depot depotC = new Depot(); depotC.setId(3L); depotC.setNom("C"); depotC.setLatitude(34.74); depotC.setLongitude(10.74);

        // Depot A: p1=10, p2=10
        Stock sA1 = new Stock(); sA1.setProduit(p1); sA1.setDepot(depotA); sA1.setQuantity(10);
        Stock sA2 = new Stock(); sA2.setProduit(p2); sA2.setDepot(depotA); sA2.setQuantity(10);
        // Depot B: p2=10, p3=10
        Stock sB2 = new Stock(); sB2.setProduit(p2); sB2.setDepot(depotB); sB2.setQuantity(10);
        Stock sB3 = new Stock(); sB3.setProduit(p3); sB3.setDepot(depotB); sB3.setQuantity(10);
        // Depot C: p1=10, p2=10, p3=10
        Stock sC1 = new Stock(); sC1.setProduit(p1); sC1.setDepot(depotC); sC1.setQuantity(10);
        Stock sC2 = new Stock(); sC2.setProduit(p2); sC2.setDepot(depotC); sC2.setQuantity(10);
        Stock sC3 = new Stock(); sC3.setProduit(p3); sC3.setDepot(depotC); sC3.setQuantity(10);

        when(stockRepository.findByProduitIdAndSocieteId(eq(1L), eq(1L))).thenReturn(List.of(sA1, sC1));
        when(stockRepository.findByProduitIdAndSocieteId(eq(2L), eq(1L))).thenReturn(List.of(sA2, sB2, sC2));
        when(stockRepository.findByProduitIdAndSocieteId(eq(3L), eq(1L))).thenReturn(List.of(sB3, sC3));

        // When
        Map<String, Object> result = mapDataService.generateOptimalCollectionPlan(
                List.of(100L), 1L, 34.74, 10.74);

        // Then: should pick 1 depot (C) instead of 2 (A+B)
        assertThat(result.get("totalDepots")).isEqualTo(1);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> steps = (List<Map<String, Object>>) result.get("mergedSteps");
        assertThat(steps).hasSize(1);
        assertThat(steps.get(0).get("depotId")).isEqualTo(3L); // Depot C
    }

    @Test
    void optimalPlan_shouldMergeAcrossOrdersAndSkipUnnecessaryDepots() {
        // Your example: 4 depots A(p1,p2) B(p2,p4,p5) C(p4,p1) D(p3,p1)
        // C1 needs p2,p3 — C2 needs p2,p4
        // Mandatory: D for p3, B for p4. B+D also cover p2.
        // No need for A (even if closer). Result should be {B,D}.
        Produit p1 = new Produit(); p1.setId(1L); p1.setName("p1");
        Produit p2 = new Produit(); p2.setId(2L); p2.setName("p2");
        Produit p3 = new Produit(); p3.setId(3L); p3.setName("p3");
        Produit p4 = new Produit(); p4.setId(4L); p4.setName("p4");

        // C1: p2(qty3), p3(qty1)
        OrderItem c1i1 = OrderItem.builder().id(10L).produit(p2).quantity(3).build();
        OrderItem c1i2 = OrderItem.builder().id(11L).produit(p3).quantity(1).build();
        Order c1 = new Order(); c1.setId(1L);
        c1.setItems(new ArrayList<>(List.of(c1i1, c1i2)));
        c1i1.setOrder(c1); c1i2.setOrder(c1);

        // C2: p2(qty2), p4(qty4)
        OrderItem c2i1 = OrderItem.builder().id(20L).produit(p2).quantity(2).build();
        OrderItem c2i2 = OrderItem.builder().id(21L).produit(p4).quantity(4).build();
        Order c2 = new Order(); c2.setId(2L);
        c2.setItems(new ArrayList<>(List.of(c2i1, c2i2)));
        c2i1.setOrder(c2); c2i2.setOrder(c2);

        when(orderRepository.findByIdsWithItems(List.of(1L, 2L))).thenReturn(List.of(c1, c2));

        // Depot A(id=1): p1=10, p2=10
        Depot dA = new Depot(); dA.setId(1L); dA.setNom("A"); dA.setLatitude(34.70); dA.setLongitude(10.70);
        // Depot B(id=2): p2=10, p4=10
        Depot dB = new Depot(); dB.setId(2L); dB.setNom("B"); dB.setLatitude(34.72); dB.setLongitude(10.72);
        // Depot C(id=3): p4=10, p1=10
        Depot dC = new Depot(); dC.setId(3L); dC.setNom("C"); dC.setLatitude(34.74); dC.setLongitude(10.74);
        // Depot D(id=4): p3=10, p1=10
        Depot dD = new Depot(); dD.setId(4L); dD.setNom("D"); dD.setLatitude(34.76); dD.setLongitude(10.76);

        // p1: in A, C, D — not needed by C1 or C2
        Stock sA1 = new Stock(); sA1.setProduit(p1); sA1.setDepot(dA); sA1.setQuantity(10);
        Stock sC1 = new Stock(); sC1.setProduit(p1); sC1.setDepot(dC); sC1.setQuantity(10);
        Stock sD1 = new Stock(); sD1.setProduit(p1); sD1.setDepot(dD); sD1.setQuantity(10);
        // p2: in A, B (needed by C1+C2 = 3+2 = 5 total)
        Stock sA2 = new Stock(); sA2.setProduit(p2); sA2.setDepot(dA); sA2.setQuantity(10);
        Stock sB2 = new Stock(); sB2.setProduit(p2); sB2.setDepot(dB); sB2.setQuantity(10);
        // p3: only in D (needed by C1 = 1)
        Stock sD3 = new Stock(); sD3.setProduit(p3); sD3.setDepot(dD); sD3.setQuantity(10);
        // p4: in B, C (needed by C2 = 4)
        Stock sB4 = new Stock(); sB4.setProduit(p4); sB4.setDepot(dB); sB4.setQuantity(10);
        Stock sC4 = new Stock(); sC4.setProduit(p4); sC4.setDepot(dC); sC4.setQuantity(10);

        when(stockRepository.findByProduitIdAndSocieteId(eq(2L), eq(1L))).thenReturn(List.of(sA2, sB2));
        when(stockRepository.findByProduitIdAndSocieteId(eq(3L), eq(1L))).thenReturn(List.of(sD3));
        when(stockRepository.findByProduitIdAndSocieteId(eq(4L), eq(1L))).thenReturn(List.of(sB4, sC4));

        // When
        Map<String, Object> result = mapDataService.generateOptimalCollectionPlan(
                List.of(1L, 2L), 1L, 34.70, 10.70);

        // Then: should pick exactly 2 depots: B and D
        assertThat(result.get("totalDepots")).isEqualTo(2);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> steps = (List<Map<String, Object>>) result.get("mergedSteps");
        Set<Long> chosenIds = steps.stream().map(s -> (Long) s.get("depotId")).collect(java.util.stream.Collectors.toSet());
        assertThat(chosenIds).containsExactlyInAnyOrder(2L, 4L); // B and D
        assertThat(chosenIds).doesNotContain(1L); // NOT depot A
    }

    @Test
    void optimalPlan_shouldReturnEmptyForNoOrders() {
        when(orderRepository.findByIdsWithItems(List.of(999L))).thenReturn(List.of());
        Map<String, Object> result = mapDataService.generateOptimalCollectionPlan(List.of(999L), 1L, null, null);
        assertThat(result.get("totalDepots")).isEqualTo(0);
    }

    @Test
    void optimalPlan_shouldPreferShorterRouteAmongSameSizeCovers() {
        // Two depots can each individually cover 1 product.
        // Depot CLOSE (near livreur) vs Depot FAR.
        // Both are k=1 covers → should pick the closer one.
        Produit p1 = new Produit(); p1.setId(1L); p1.setName("P1");
        OrderItem item = OrderItem.builder().id(10L).produit(p1).quantity(2).build();
        Order order = new Order(); order.setId(100L);
        order.setItems(new ArrayList<>(List.of(item)));
        item.setOrder(order);

        when(orderRepository.findByIdsWithItems(List.of(100L))).thenReturn(List.of(order));

        Depot close = new Depot(); close.setId(1L); close.setNom("Close"); close.setLatitude(34.740); close.setLongitude(10.760);
        Depot far = new Depot(); far.setId(2L); far.setNom("Far"); far.setLatitude(35.500); far.setLongitude(11.500);

        Stock sClose = new Stock(); sClose.setProduit(p1); sClose.setDepot(close); sClose.setQuantity(10);
        Stock sFar = new Stock(); sFar.setProduit(p1); sFar.setDepot(far); sFar.setQuantity(10);

        when(stockRepository.findByProduitIdAndSocieteId(eq(1L), eq(1L))).thenReturn(List.of(sClose, sFar));

        Map<String, Object> result = mapDataService.generateOptimalCollectionPlan(
                List.of(100L), 1L, 34.740, 10.760);

        assertThat(result.get("totalDepots")).isEqualTo(1);
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> steps = (List<Map<String, Object>>) result.get("mergedSteps");
        assertThat(steps.get(0).get("depotId")).isEqualTo(1L); // Close depot
    }
}
