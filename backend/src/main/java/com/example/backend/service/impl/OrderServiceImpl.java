package com.example.backend.service.impl;

import com.example.backend.dto.OrderDTO;
import com.example.backend.dto.OrderItemDTO;
import com.example.backend.exception.BadRequestException;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.mapper.OrderMapper;
import com.example.backend.model.*;
import com.example.backend.repository.*;
import com.example.backend.service.OrderService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class OrderServiceImpl implements OrderService {
    
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final UserRepository userRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final DepotRepository depotRepository;
    private final ProduitRepository produitRepository;
    private final OrderMapper orderMapper;
    
    @Override
    @Transactional(readOnly = true)
    public List<OrderDTO> findAll() {
        return orderRepository.findAllWithItems().stream()
                .map(orderMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<OrderDTO> findBySocieteId(Long societeId) {
        // Try to find by livreur's societe first, then by depot's societe
        List<Order> orders = orderRepository.findBySocieteId(societeId);
        if (orders.isEmpty()) {
            orders = orderRepository.findByDepotSocieteId(societeId);
        }
        return orders.stream()
                .map(orderMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public OrderDTO findById(Long id) {
        Order order = orderRepository.findByIdWithItems(id)
                .orElseThrow(() -> new ResourceNotFoundException("Commande", "id", id));
        return orderMapper.toDTO(order);
    }
    
    @Override
    @Transactional(readOnly = true)
    public OrderDTO findByNumero(String numero) {
        Order order = orderRepository.findByNumero(numero)
                .orElseThrow(() -> new ResourceNotFoundException("Commande", "numero", numero));
        return orderMapper.toDTO(order);
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<OrderDTO> findByUserId(Long userId) {
        return orderRepository.findByUserId(userId).stream()
                .map(orderMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<OrderDTO> findByLivreurId(Long livreurId) {
        return orderRepository.findByLivreurId(livreurId).stream()
                .map(orderMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<OrderDTO> findByStatus(String status) {
        return orderRepository.findByStatus(status).stream()
                .map(orderMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<OrderDTO> findByDepotId(Long depotId) {
        return orderRepository.findByDepotId(depotId).stream()
                .map(orderMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<OrderDTO> findPendingOrdersForLivreur(Long livreurId) {
        // Returns pending orders without an assigned livreur (available for acceptance)
        return orderRepository.findPendingOrdersForLivreur().stream()
                .map(orderMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    public OrderDTO create(OrderDTO orderDTO) {
        Order order = new Order();
        
        // Generate order numbers
        String orderNum = generateOrderNumber();
        order.setNumero(orderNum);
        order.setOrderNumber(orderNum);
        
        // Set userId (utilisateur/client depuis la table 'users')
        Long userId = orderDTO.getUserId() != null ? orderDTO.getUserId() : orderDTO.getClientId();
        if (userId == null) {
            throw new BadRequestException("L'identifiant du client (userId) est obligatoire");
        }
        
        // Vérifier que l'utilisateur existe
        userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur/Client", "id", userId));
        order.setUserId(userId);
        
        // Set required fields from existing table
        order.setTotalAmount(orderDTO.getMontantTTC() != null ? orderDTO.getMontantTTC() : BigDecimal.ZERO);
        order.setShippingAddress(orderDTO.getAdresseLivraison() != null ? orderDTO.getAdresseLivraison() : "N/A");
        order.setPaymentMethod("cash");
        order.setPaymentStatus("pending");
        
        // Set depot if provided
        if (orderDTO.getDepotId() != null) {
            Depot depot = depotRepository.findById(orderDTO.getDepotId())
                    .orElseThrow(() -> new ResourceNotFoundException("Depot", "id", orderDTO.getDepotId()));
            order.setDepot(depot);
        }
        
        // Set livreur if provided
        if (orderDTO.getLivreurId() != null) {
            Utilisateur livreur = utilisateurRepository.findById(orderDTO.getLivreurId())
                    .orElseThrow(() -> new ResourceNotFoundException("Livreur", "id", orderDTO.getLivreurId()));
            if (livreur.getRole() != Role.LIVREUR) {
                throw new BadRequestException("L'utilisateur n'est pas un livreur");
            }
            order.setLivreur(livreur);
        }
        
        order.setStatus("pending");
        order.setSocieteId(orderDTO.getSocieteId());
        order.setAdresseLivraison(orderDTO.getAdresseLivraison());
        order.setLatitudeLivraison(orderDTO.getLatitudeLivraison());
        order.setLongitudeLivraison(orderDTO.getLongitudeLivraison());
        order.setDateLivraisonPrevue(orderDTO.getDateLivraisonPrevue());
        order.setNotes(orderDTO.getNotes());
        
        // Save manual collection plan if provided by admin
        if (orderDTO.getCollectionPlan() != null && !orderDTO.getCollectionPlan().isBlank()) {
            order.setCollectionPlan(orderDTO.getCollectionPlan());
        }
        
        // Save order first
        order = orderRepository.save(order);
        
        // Add items
        if (orderDTO.getItems() != null && !orderDTO.getItems().isEmpty()) {
            for (OrderItemDTO itemDTO : orderDTO.getItems()) {
                addOrderItem(order, itemDTO);
            }
        }
        
        // Calculate totals
        calculateOrderTotals(order);
        order = orderRepository.save(order);
        
        return orderMapper.toDTO(order);
    }
    
    @Override
    public OrderDTO update(Long id, OrderDTO orderDTO) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Commande", "id", id));
        
        if (orderDTO.getAdresseLivraison() != null) {
            order.setAdresseLivraison(orderDTO.getAdresseLivraison());
        }
        if (orderDTO.getLatitudeLivraison() != null) {
            order.setLatitudeLivraison(orderDTO.getLatitudeLivraison());
        }
        if (orderDTO.getLongitudeLivraison() != null) {
            order.setLongitudeLivraison(orderDTO.getLongitudeLivraison());
        }
        if (orderDTO.getDateLivraisonPrevue() != null) {
            order.setDateLivraisonPrevue(orderDTO.getDateLivraisonPrevue());
        }
        if (orderDTO.getNotes() != null) {
            order.setNotes(orderDTO.getNotes());
        }
        
        order = orderRepository.save(order);
        return orderMapper.toDTO(order);
    }
    
    @Override
    public OrderDTO updateStatus(Long id, String status) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Commande", "id", id));
        
        order.setStatus(status);
        
        if ("delivered".equals(status)) {
            order.setDateLivraisonEffective(LocalDateTime.now());
        }
        
        order = orderRepository.save(order);
        return orderMapper.toDTO(order);
    }
    
    @Override
    public OrderDTO assignLivreur(Long orderId, Long livreurId) {
        Order order = orderRepository.findByIdWithItems(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Commande", "id", orderId));
        
        Utilisateur livreur = utilisateurRepository.findById(livreurId)
                .orElseThrow(() -> new ResourceNotFoundException("Livreur", "id", livreurId));
        
        if (livreur.getRole() != Role.LIVREUR) {
            throw new BadRequestException("L'utilisateur n'est pas un livreur");
        }
        
        order.setLivreur(livreur);
        // Update status to 'en_cours' when livreur accepts
        order.setStatus("en_cours");
        order = orderRepository.save(order);
        return orderMapper.toDTO(order);
    }
    
    @Override
    public void delete(Long id) {
        if (!orderRepository.existsById(id)) {
            throw new ResourceNotFoundException("Commande", "id", id);
        }
        orderRepository.deleteById(id);
    }
    
    @Override
    public OrderDTO markAsCollected(Long orderId) {
        Order order = orderRepository.findByIdWithItems(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Commande", "id", orderId));
        order.setCollected(true);
        order.setDateCollection(LocalDateTime.now());
        order = orderRepository.save(order);
        return orderMapper.toDTO(order);
    }
    
    private void addOrderItem(Order order, OrderItemDTO itemDTO) {
        Produit produit = produitRepository.findById(itemDTO.getProduitId())
                .orElseThrow(() -> new ResourceNotFoundException("Produit", "id", itemDTO.getProduitId()));
        
        BigDecimal price = produit.getPriceUht() != null ? produit.getPriceUht() : BigDecimal.ZERO;
        
        OrderItem item = OrderItem.builder()
                .order(order)
                .produit(produit)
                .quantity(itemDTO.getQuantite())
                .priceUht(price)
                .prixUnitaireHT(price)
                .remise(itemDTO.getRemise() != null ? itemDTO.getRemise() : BigDecimal.ZERO)
                .version(1)
                .build();
        
        // Set TVA rate - default to 0 if not available
        item.setTauxTva(BigDecimal.ZERO);
        
        calculateItemTotals(item);
        order.addItem(item);
    }
    
    private void calculateItemTotals(OrderItem item) {
        BigDecimal quantity = BigDecimal.valueOf(item.getActualQuantity());
        BigDecimal remise = item.getRemise() != null ? item.getRemise() : BigDecimal.ZERO;
        BigDecimal prixHT = item.getPrixUnitaireHT() != null ? item.getPrixUnitaireHT() : BigDecimal.ZERO;
        BigDecimal tva = item.getTauxTva() != null ? item.getTauxTva() : BigDecimal.ZERO;
        
        BigDecimal montantHT = prixHT.multiply(quantity);
        montantHT = montantHT.subtract(montantHT.multiply(remise.divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP)));
        item.setMontantHT(montantHT.setScale(2, RoundingMode.HALF_UP));
        
        BigDecimal montantTVA = montantHT.multiply(tva.divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP));
        item.setMontantTVA(montantTVA.setScale(2, RoundingMode.HALF_UP));
        
        item.setMontantTTC(montantHT.add(montantTVA).setScale(2, RoundingMode.HALF_UP));
    }
    
    private void calculateOrderTotals(Order order) {
        BigDecimal totalHT = BigDecimal.ZERO;
        BigDecimal totalTVA = BigDecimal.ZERO;
        
        for (OrderItem item : order.getItems()) {
            totalHT = totalHT.add(item.getMontantHT());
            totalTVA = totalTVA.add(item.getMontantTVA());
        }
        
        order.setMontantHT(totalHT.setScale(2, RoundingMode.HALF_UP));
        order.setMontantTVA(totalTVA.setScale(2, RoundingMode.HALF_UP));
        order.setMontantTTC(totalHT.add(totalTVA).setScale(2, RoundingMode.HALF_UP));
    }
    
    private String generateOrderNumber() {
        String prefix = "CMD";
        String datePart = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd"));
        String timePart = LocalDateTime.now().format(DateTimeFormatter.ofPattern("HHmmss"));
        return prefix + datePart + timePart;
    }
}
