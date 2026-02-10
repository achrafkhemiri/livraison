package com.example.backend.service;

import com.example.backend.dto.UserDTO;
import java.util.List;

/**
 * Service pour les Clients/Consommateurs (table 'users' existante)
 */
public interface UserService {
    List<UserDTO> findAll();
    UserDTO findById(Long id);
    List<UserDTO> findUsersWithOrders();
    List<UserDTO> findUsersWithPositions();
}
