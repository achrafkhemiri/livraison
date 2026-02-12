package com.example.backend.controller;

import com.example.backend.dto.MapDataDTO;
import com.example.backend.dto.OrderDTO;
import com.example.backend.dto.ProductStockInfoDTO;
import com.example.backend.service.MapDataService;
import com.example.backend.service.OrderService;
import com.example.backend.service.SecurityService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class MapDataControllerTest {

    private MockMvc mockMvc;
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Mock
    private MapDataService mapDataService;
    @Mock
    private OrderService orderService;
    @Mock
    private SecurityService securityService;

    @InjectMocks
    private MapDataController mapDataController;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(mapDataController).build();
    }

    // ========================
    // GET /api/map-data
    // ========================

    @Test
    void getMapData_shouldReturnMapData() throws Exception {
        // Given
        when(securityService.getCurrentUserSocieteId()).thenReturn(1L);

        MapDataDTO mapData = MapDataDTO.builder()
                .societe(MapDataDTO.SocieteMarker.builder()
                        .id(1L).nom("Société Test")
                        .latitude(34.74).longitude(10.76)
                        .build())
                .magasins(List.of(MapDataDTO.MagasinMarker.builder()
                        .id(1L).nom("Magasin A")
                        .latitude(34.75).longitude(10.77)
                        .ville("Sfax").adresse("Rue 1")
                        .build()))
                .depots(List.of(MapDataDTO.DepotMarker.builder()
                        .id(1L).nom("Dépôt Central").code("D001")
                        .latitude(34.76).longitude(10.78).actif(true)
                        .build()))
                .livreurs(List.of(MapDataDTO.LivreurMarker.builder()
                        .id(1L).nom("Dupont").prenom("Jean")
                        .latitude(34.77).longitude(10.79)
                        .build()))
                .build();
        when(mapDataService.getMapData(1L)).thenReturn(mapData);

        // When / Then
        mockMvc.perform(get("/api/map-data"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.societe.nom", is("Société Test")))
                .andExpect(jsonPath("$.societe.latitude", is(34.74)))
                .andExpect(jsonPath("$.magasins", hasSize(1)))
                .andExpect(jsonPath("$.magasins[0].nom", is("Magasin A")))
                .andExpect(jsonPath("$.depots", hasSize(1)))
                .andExpect(jsonPath("$.depots[0].code", is("D001")))
                .andExpect(jsonPath("$.livreurs", hasSize(1)))
                .andExpect(jsonPath("$.livreurs[0].nom", is("Dupont")));

        verify(securityService).getCurrentUserSocieteId();
        verify(mapDataService).getMapData(1L);
    }

    @Test
    void getMapData_shouldReturnForbiddenWhenNoSociete() throws Exception {
        // Given
        when(securityService.getCurrentUserSocieteId()).thenReturn(null);

        // When / Then
        mockMvc.perform(get("/api/map-data"))
                .andExpect(status().isForbidden());

        verify(mapDataService, never()).getMapData(any());
    }

    // ========================
    // GET /api/products-stock
    // ========================

    @Test
    void getProductsStock_shouldReturnProductsList() throws Exception {
        // Given
        when(securityService.getCurrentUserSocieteId()).thenReturn(1L);

        ProductStockInfoDTO product = ProductStockInfoDTO.builder()
                .produitId(1L)
                .produitNom("Produit A")
                .produitReference("REF001")
                .prixHT(BigDecimal.valueOf(25.50))
                .totalStock(BigDecimal.valueOf(150))
                .depotStocks(List.of(
                        ProductStockInfoDTO.DepotStockDTO.builder()
                                .depotId(1L).depotNom("Dépôt Central")
                                .depotLatitude(34.76).depotLongitude(10.78)
                                .quantiteDisponible(BigDecimal.valueOf(150))
                                .build()))
                .build();
        when(mapDataService.getProductsWithStockBySociete(1L)).thenReturn(List.of(product));

        // When / Then
        mockMvc.perform(get("/api/products-stock"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)))
                .andExpect(jsonPath("$[0].produitId", is(1)))
                .andExpect(jsonPath("$[0].produitNom", is("Produit A")))
                .andExpect(jsonPath("$[0].produitReference", is("REF001")))
                .andExpect(jsonPath("$[0].totalStock", is(150)))
                .andExpect(jsonPath("$[0].depotStocks", hasSize(1)));

        verify(mapDataService).getProductsWithStockBySociete(1L);
    }

    @Test
    void getProductsStock_shouldReturnForbiddenWhenNoSociete() throws Exception {
        // Given
        when(securityService.getCurrentUserSocieteId()).thenReturn(null);

        // When / Then
        mockMvc.perform(get("/api/products-stock"))
                .andExpect(status().isForbidden());
    }

    @Test
    void getProductsStock_shouldReturnEmptyListWhenNoProducts() throws Exception {
        // Given
        when(securityService.getCurrentUserSocieteId()).thenReturn(1L);
        when(mapDataService.getProductsWithStockBySociete(1L)).thenReturn(List.of());

        // When / Then
        mockMvc.perform(get("/api/products-stock"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));
    }

    // ========================
    // POST /api/orders/{id}/collection-plan
    // ========================

    @Test
    void generateCollectionPlan_shouldReturnPlan() throws Exception {
        // Given
        when(securityService.getCurrentUserSocieteId()).thenReturn(1L);

        Map<String, Object> plan = Map.of(
                "orderId", 1L,
                "totalDepots", 2,
                "collectionSteps", List.of(
                        Map.of("step", 1, "depotId", 1L, "depotNom", "Dépôt A",
                                "items", List.of(Map.of("produitNom", "Produit 1", "quantite", 5))),
                        Map.of("step", 2, "depotId", 2L, "depotNom", "Dépôt B",
                                "items", List.of(Map.of("produitNom", "Produit 2", "quantite", 3)))
                )
        );
        when(mapDataService.generateCollectionPlan(1L, 1L)).thenReturn(plan);

        // When / Then
        mockMvc.perform(post("/api/orders/1/collection-plan"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.orderId", is(1)))
                .andExpect(jsonPath("$.totalDepots", is(2)))
                .andExpect(jsonPath("$.collectionSteps", hasSize(2)))
                .andExpect(jsonPath("$.collectionSteps[0].depotNom", is("Dépôt A")));

        verify(mapDataService).generateCollectionPlan(1L, 1L);
    }

    @Test
    void generateCollectionPlan_shouldReturnForbiddenWhenNoSociete() throws Exception {
        // Given
        when(securityService.getCurrentUserSocieteId()).thenReturn(null);

        // When / Then
        mockMvc.perform(post("/api/orders/1/collection-plan"))
                .andExpect(status().isForbidden());
    }

    // ========================
    // PATCH /api/orders/{id}/collected
    // ========================

    @Test
    void markOrderCollected_shouldReturnUpdatedOrder() throws Exception {
        // Given
        when(securityService.getCurrentUserSocieteId()).thenReturn(1L);

        OrderDTO collectedOrder = OrderDTO.builder()
                .id(1L)
                .numero("CMD001")
                .collected(true)
                .status("en_cours")
                .build();
        when(orderService.markAsCollected(1L)).thenReturn(collectedOrder);

        // When / Then
        mockMvc.perform(patch("/api/orders/1/collected"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(1)))
                .andExpect(jsonPath("$.collected", is(true)));

        verify(orderService).markAsCollected(1L);
    }

    @Test
    void markOrderCollected_shouldReturnForbiddenWhenNoSociete() throws Exception {
        // Given
        when(securityService.getCurrentUserSocieteId()).thenReturn(null);

        // When / Then
        mockMvc.perform(patch("/api/orders/1/collected"))
                .andExpect(status().isForbidden());

        verify(orderService, never()).markAsCollected(any());
    }
}
