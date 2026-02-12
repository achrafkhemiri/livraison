package com.example.backend.service;

import com.example.backend.dto.OrderDTO;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.mapper.OrderMapper;
import com.example.backend.model.*;
import com.example.backend.repository.*;
import com.example.backend.service.impl.OrderServiceImpl;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private OrderRepository orderRepository;
    @Mock
    private OrderItemRepository orderItemRepository;
    @Mock
    private UserRepository userRepository;
    @Mock
    private UtilisateurRepository utilisateurRepository;
    @Mock
    private DepotRepository depotRepository;
    @Mock
    private ProduitRepository produitRepository;
    @Mock
    private OrderMapper orderMapper;

    @InjectMocks
    private OrderServiceImpl orderService;

    private Order order;
    private OrderDTO orderDTO;

    @BeforeEach
    void setUp() {
        order = new Order();
        order.setId(1L);
        order.setNumero("CMD20250101120000");
        order.setOrderNumber("CMD20250101120000");
        order.setUserId(10L);
        order.setTotalAmount(BigDecimal.valueOf(100.00));
        order.setShippingAddress("123 Rue Test");
        order.setPaymentMethod("cash");
        order.setPaymentStatus("pending");
        order.setStatus("pending");
        order.setItems(new ArrayList<>());

        orderDTO = OrderDTO.builder()
                .id(1L)
                .numero("CMD20250101120000")
                .userId(10L)
                .status("pending")
                .montantTTC(BigDecimal.valueOf(100.00))
                .build();
    }

    // ========================
    // markAsCollected tests
    // ========================

    @Test
    void markAsCollected_shouldSetCollectedTrueAndDateCollection() {
        // Given
        order.setCollected(false);
        order.setDateCollection(null);
        when(orderRepository.findByIdWithItems(1L)).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));

        OrderDTO expectedDTO = OrderDTO.builder()
                .id(1L)
                .collected(true)
                .build();
        when(orderMapper.toDTO(any(Order.class))).thenReturn(expectedDTO);

        // When
        OrderDTO result = orderService.markAsCollected(1L);

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getCollected()).isTrue();

        verify(orderRepository).findByIdWithItems(1L);
        verify(orderRepository).save(any(Order.class));
        verify(orderMapper).toDTO(any(Order.class));
    }

    @Test
    void markAsCollected_shouldThrowWhenOrderNotFound() {
        // Given
        when(orderRepository.findByIdWithItems(999L)).thenReturn(Optional.empty());

        // When / Then
        assertThatThrownBy(() -> orderService.markAsCollected(999L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    void markAsCollected_shouldSaveEntityWithCorrectFields() {
        // Given
        when(orderRepository.findByIdWithItems(1L)).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> {
            Order saved = inv.getArgument(0);
            // Verify the fields were set before save
            assertThat(saved.getCollected()).isTrue();
            assertThat(saved.getDateCollection()).isNotNull();
            assertThat(saved.getDateCollection()).isBeforeOrEqualTo(LocalDateTime.now());
            return saved;
        });
        when(orderMapper.toDTO(any(Order.class))).thenReturn(orderDTO);

        // When
        orderService.markAsCollected(1L);

        // Then
        verify(orderRepository).save(argThat(o -> 
                o.getCollected() && o.getDateCollection() != null));
    }

    // ========================
    // findAll tests
    // ========================

    @Test
    void findAll_shouldReturnAllOrders() {
        // Given
        Order order2 = new Order();
        order2.setId(2L);
        order2.setItems(new ArrayList<>());

        when(orderRepository.findAllWithItems()).thenReturn(List.of(order, order2));

        OrderDTO dto1 = OrderDTO.builder().id(1L).build();
        OrderDTO dto2 = OrderDTO.builder().id(2L).build();
        when(orderMapper.toDTO(order)).thenReturn(dto1);
        when(orderMapper.toDTO(order2)).thenReturn(dto2);

        // When
        List<OrderDTO> result = orderService.findAll();

        // Then
        assertThat(result).hasSize(2);
        verify(orderRepository).findAllWithItems();
    }

    @Test
    void findAll_shouldReturnEmptyListWhenNoOrders() {
        // Given
        when(orderRepository.findAllWithItems()).thenReturn(List.of());

        // When
        List<OrderDTO> result = orderService.findAll();

        // Then
        assertThat(result).isEmpty();
    }

    // ========================
    // findById tests
    // ========================

    @Test
    void findById_shouldReturnOrder() {
        // Given
        when(orderRepository.findByIdWithItems(1L)).thenReturn(Optional.of(order));
        when(orderMapper.toDTO(order)).thenReturn(orderDTO);

        // When
        OrderDTO result = orderService.findById(1L);

        // Then
        assertThat(result).isNotNull();
        assertThat(result.getId()).isEqualTo(1L);
    }

    @Test
    void findById_shouldThrowWhenNotFound() {
        // Given
        when(orderRepository.findByIdWithItems(999L)).thenReturn(Optional.empty());

        // When / Then
        assertThatThrownBy(() -> orderService.findById(999L))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    // ========================
    // updateStatus tests
    // ========================

    @Test
    void updateStatus_shouldUpdateStatusToDelivered() {
        // Given
        when(orderRepository.findById(1L)).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));
        when(orderMapper.toDTO(any(Order.class))).thenReturn(
                OrderDTO.builder().id(1L).status("delivered").build());

        // When
        OrderDTO result = orderService.updateStatus(1L, "delivered");

        // Then
        assertThat(result.getStatus()).isEqualTo("delivered");
        verify(orderRepository).save(argThat(o -> 
                "delivered".equals(o.getStatus()) && o.getDateLivraisonEffective() != null));
    }

    @Test
    void updateStatus_shouldNotSetDeliveryDateForNonDeliveredStatus() {
        // Given
        when(orderRepository.findById(1L)).thenReturn(Optional.of(order));
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));
        when(orderMapper.toDTO(any(Order.class))).thenReturn(
                OrderDTO.builder().id(1L).status("processing").build());

        // When
        orderService.updateStatus(1L, "processing");

        // Then
        verify(orderRepository).save(argThat(o -> 
                "processing".equals(o.getStatus()) && o.getDateLivraisonEffective() == null));
    }

    // ========================
    // assignLivreur tests
    // ========================

    @Test
    void assignLivreur_shouldAssignAndSetStatusEnCours() {
        // Given
        Utilisateur livreur = new Utilisateur();
        livreur.setId(5L);
        livreur.setNom("Dupont");
        livreur.setRole(Role.LIVREUR);

        when(orderRepository.findByIdWithItems(1L)).thenReturn(Optional.of(order));
        when(utilisateurRepository.findById(5L)).thenReturn(Optional.of(livreur));
        when(orderRepository.save(any(Order.class))).thenAnswer(inv -> inv.getArgument(0));
        when(orderMapper.toDTO(any(Order.class))).thenReturn(
                OrderDTO.builder().id(1L).livreurId(5L).status("en_cours").build());

        // When
        OrderDTO result = orderService.assignLivreur(1L, 5L);

        // Then
        assertThat(result.getLivreurId()).isEqualTo(5L);
        assertThat(result.getStatus()).isEqualTo("en_cours");
        verify(orderRepository).save(argThat(o -> 
                o.getLivreur() != null && "en_cours".equals(o.getStatus())));
    }

    @Test
    void assignLivreur_shouldThrowWhenUserIsNotLivreur() {
        // Given
        Utilisateur gerant = new Utilisateur();
        gerant.setId(5L);
        gerant.setRole(Role.GERANT);

        when(orderRepository.findByIdWithItems(1L)).thenReturn(Optional.of(order));
        when(utilisateurRepository.findById(5L)).thenReturn(Optional.of(gerant));

        // When / Then
        assertThatThrownBy(() -> orderService.assignLivreur(1L, 5L))
                .isInstanceOf(com.example.backend.exception.BadRequestException.class)
                .hasMessageContaining("livreur");
    }

    // ========================
    // delete tests
    // ========================

    @Test
    void delete_shouldDeleteExistingOrder() {
        // Given
        when(orderRepository.existsById(1L)).thenReturn(true);

        // When
        orderService.delete(1L);

        // Then
        verify(orderRepository).deleteById(1L);
    }

    @Test
    void delete_shouldThrowWhenOrderNotFound() {
        // Given
        when(orderRepository.existsById(999L)).thenReturn(false);

        // When / Then
        assertThatThrownBy(() -> orderService.delete(999L))
                .isInstanceOf(ResourceNotFoundException.class);
    }
}
