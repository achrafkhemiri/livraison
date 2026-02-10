package com.example.backend.service;

import com.example.backend.dto.OrderDTO;
import java.util.List;

public interface OrderService {
    List<OrderDTO> findAll();
    List<OrderDTO> findBySocieteId(Long societeId);
    OrderDTO findById(Long id);
    OrderDTO findByNumero(String numero);
    List<OrderDTO> findByUserId(Long userId);
    List<OrderDTO> findByLivreurId(Long livreurId);
    List<OrderDTO> findByStatus(String status);
    List<OrderDTO> findByDepotId(Long depotId);
    List<OrderDTO> findPendingOrdersForLivreur(Long livreurId);
    OrderDTO create(OrderDTO orderDTO);
    OrderDTO update(Long id, OrderDTO orderDTO);
    OrderDTO updateStatus(Long id, String status);
    OrderDTO assignLivreur(Long orderId, Long livreurId);
    void delete(Long id);
}
