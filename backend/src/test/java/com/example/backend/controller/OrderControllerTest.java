package com.example.backend.controller;

import com.example.backend.dto.OrderDTO;
import com.example.backend.dto.PageResponse;
import com.example.backend.service.OrderService;
import com.example.backend.service.SecurityService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
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
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@ExtendWith(MockitoExtension.class)
class OrderControllerTest {

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;

    @Mock
    private OrderService orderService;
    @Mock
    private SecurityService securityService;

    @InjectMocks
    private OrderController orderController;

    private OrderDTO sampleOrder1;
    private OrderDTO sampleOrder2;

    @BeforeEach
    void setUp() {
        objectMapper = new ObjectMapper();
        objectMapper.registerModule(new JavaTimeModule());
        mockMvc = MockMvcBuilders.standaloneSetup(orderController).build();

        sampleOrder1 = OrderDTO.builder()
                .id(1L)
                .numero("CMD20250101120000")
                .clientId(10L)
                .clientNom("Client Test")
                .status("pending")
                .montantTTC(BigDecimal.valueOf(150.00))
                .dateCommande(LocalDateTime.of(2025, 2, 20, 10, 0))
                .build();

        sampleOrder2 = OrderDTO.builder()
                .id(2L)
                .numero("CMD20250102130000")
                .clientId(11L)
                .clientNom("Client Deux")
                .status("delivered")
                .montantTTC(BigDecimal.valueOf(250.50))
                .dateCommande(LocalDateTime.of(2025, 2, 21, 14, 30))
                .build();
    }

    // ========================
    // GET /api/orders/search - Pagination
    // ========================

    @Test
    void searchOrders_shouldReturnPaginatedResults() throws Exception {
        PageResponse<OrderDTO> pageResponse = PageResponse.<OrderDTO>builder()
                .content(List.of(sampleOrder1, sampleOrder2))
                .page(0)
                .size(10)
                .totalElements(2)
                .totalPages(1)
                .first(true)
                .last(true)
                .build();

        when(securityService.getCurrentUserSocieteId()).thenReturn(1L);
        when(orderService.searchOrders(eq(1L), any(), any(), any(), any(), eq(0), eq(10)))
                .thenReturn(pageResponse);

        mockMvc.perform(get("/api/orders/search")
                        .param("page", "0")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(2)))
                .andExpect(jsonPath("$.totalElements").value(2))
                .andExpect(jsonPath("$.totalPages").value(1))
                .andExpect(jsonPath("$.first").value(true))
                .andExpect(jsonPath("$.last").value(true));
    }

    @Test
    void searchOrders_withSearchQuery_shouldPassSearchToService() throws Exception {
        PageResponse<OrderDTO> pageResponse = PageResponse.<OrderDTO>builder()
                .content(List.of(sampleOrder1))
                .page(0)
                .size(10)
                .totalElements(1)
                .totalPages(1)
                .first(true)
                .last(true)
                .build();

        when(securityService.getCurrentUserSocieteId()).thenReturn(1L);
        when(orderService.searchOrders(eq(1L), eq("CMD2025"), any(), any(), any(), eq(0), eq(10)))
                .thenReturn(pageResponse);

        mockMvc.perform(get("/api/orders/search")
                        .param("page", "0")
                        .param("size", "10")
                        .param("search", "CMD2025"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(1)))
                .andExpect(jsonPath("$.content[0].numero").value("CMD20250101120000"));

        verify(orderService).searchOrders(eq(1L), eq("CMD2025"), any(), any(), any(), eq(0), eq(10));
    }

    @Test
    void searchOrders_withStatusFilter_shouldPassStatusToService() throws Exception {
        PageResponse<OrderDTO> pageResponse = PageResponse.<OrderDTO>builder()
                .content(List.of(sampleOrder2))
                .page(0)
                .size(10)
                .totalElements(1)
                .totalPages(1)
                .first(true)
                .last(true)
                .build();

        when(securityService.getCurrentUserSocieteId()).thenReturn(1L);
        when(orderService.searchOrders(eq(1L), any(), eq("delivered"), any(), any(), eq(0), eq(10)))
                .thenReturn(pageResponse);

        mockMvc.perform(get("/api/orders/search")
                        .param("page", "0")
                        .param("size", "10")
                        .param("status", "delivered"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(1)))
                .andExpect(jsonPath("$.content[0].status").value("delivered"));
    }

    @Test
    void searchOrders_withDateRange_shouldPassDatesToService() throws Exception {
        PageResponse<OrderDTO> pageResponse = PageResponse.<OrderDTO>builder()
                .content(List.of(sampleOrder1))
                .page(0)
                .size(10)
                .totalElements(1)
                .totalPages(1)
                .first(true)
                .last(true)
                .build();

        when(securityService.getCurrentUserSocieteId()).thenReturn(1L);
        when(orderService.searchOrders(eq(1L), any(), any(),
                eq(LocalDate.of(2025, 2, 1)), eq(LocalDate.of(2025, 2, 28)),
                eq(0), eq(10)))
                .thenReturn(pageResponse);

        mockMvc.perform(get("/api/orders/search")
                        .param("page", "0")
                        .param("size", "10")
                        .param("dateFrom", "2025-02-01")
                        .param("dateTo", "2025-02-28"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(1)));
    }

    @Test
    void searchOrders_emptyResults_shouldReturnEmptyPage() throws Exception {
        PageResponse<OrderDTO> pageResponse = PageResponse.<OrderDTO>builder()
                .content(List.of())
                .page(0)
                .size(10)
                .totalElements(0)
                .totalPages(0)
                .first(true)
                .last(true)
                .build();

        when(securityService.getCurrentUserSocieteId()).thenReturn(1L);
        when(orderService.searchOrders(eq(1L), any(), any(), any(), any(), eq(0), eq(10)))
                .thenReturn(pageResponse);

        mockMvc.perform(get("/api/orders/search")
                        .param("page", "0")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(0)))
                .andExpect(jsonPath("$.totalElements").value(0));
    }

    @Test
    void searchOrders_secondPage_shouldReturnCorrectPage() throws Exception {
        PageResponse<OrderDTO> pageResponse = PageResponse.<OrderDTO>builder()
                .content(List.of(sampleOrder2))
                .page(1)
                .size(1)
                .totalElements(2)
                .totalPages(2)
                .first(false)
                .last(true)
                .build();

        when(securityService.getCurrentUserSocieteId()).thenReturn(1L);
        when(orderService.searchOrders(eq(1L), any(), any(), any(), any(), eq(1), eq(1)))
                .thenReturn(pageResponse);

        mockMvc.perform(get("/api/orders/search")
                        .param("page", "1")
                        .param("size", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.page").value(1))
                .andExpect(jsonPath("$.first").value(false))
                .andExpect(jsonPath("$.last").value(true))
                .andExpect(jsonPath("$.totalPages").value(2));
    }

    @Test
    void searchOrders_withAllFilters_shouldPassAllToService() throws Exception {
        PageResponse<OrderDTO> pageResponse = PageResponse.<OrderDTO>builder()
                .content(List.of(sampleOrder1))
                .page(0)
                .size(5)
                .totalElements(1)
                .totalPages(1)
                .first(true)
                .last(true)
                .build();

        when(securityService.getCurrentUserSocieteId()).thenReturn(2L);
        when(orderService.searchOrders(eq(2L), eq("test"), eq("pending"),
                eq(LocalDate.of(2025, 1, 1)), eq(LocalDate.of(2025, 12, 31)),
                eq(0), eq(5)))
                .thenReturn(pageResponse);

        mockMvc.perform(get("/api/orders/search")
                        .param("page", "0")
                        .param("size", "5")
                        .param("search", "test")
                        .param("status", "pending")
                        .param("dateFrom", "2025-01-01")
                        .param("dateTo", "2025-12-31"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(1)));

        verify(orderService).searchOrders(eq(2L), eq("test"), eq("pending"),
                eq(LocalDate.of(2025, 1, 1)), eq(LocalDate.of(2025, 12, 31)),
                eq(0), eq(5));
    }

    @Test
    void searchOrders_withoutSocieteId_shouldPassNullSocieteId() throws Exception {
        PageResponse<OrderDTO> pageResponse = PageResponse.<OrderDTO>builder()
                .content(List.of(sampleOrder1, sampleOrder2))
                .page(0)
                .size(10)
                .totalElements(2)
                .totalPages(1)
                .first(true)
                .last(true)
                .build();

        when(securityService.getCurrentUserSocieteId()).thenReturn(null);
        when(orderService.searchOrders(eq(null), any(), any(), any(), any(), eq(0), eq(10)))
                .thenReturn(pageResponse);

        mockMvc.perform(get("/api/orders/search")
                        .param("page", "0")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.content", hasSize(2)));

        verify(orderService).searchOrders(eq(null), any(), any(), any(), any(), eq(0), eq(10));
    }

    // ========================
    // GET /api/orders - getAll
    // ========================

    @Test
    void getAll_withSocieteId_shouldReturnBySociete() throws Exception {
        when(securityService.getCurrentUserSocieteId()).thenReturn(1L);
        when(orderService.findBySocieteId(1L)).thenReturn(List.of(sampleOrder1));

        mockMvc.perform(get("/api/orders"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)));
    }

    @Test
    void getAll_withoutSocieteId_shouldReturnAll() throws Exception {
        when(securityService.getCurrentUserSocieteId()).thenReturn(null);
        when(orderService.findAll()).thenReturn(List.of(sampleOrder1, sampleOrder2));

        mockMvc.perform(get("/api/orders"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(2)));
    }

    // ========================
    // GET /api/orders/{id}
    // ========================

    @Test
    void getById_shouldReturnOrder() throws Exception {
        when(orderService.findById(1L)).thenReturn(sampleOrder1);

        mockMvc.perform(get("/api/orders/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(1))
                .andExpect(jsonPath("$.numero").value("CMD20250101120000"));
    }
}
