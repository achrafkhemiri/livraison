package com.example.backend.service.impl;

import com.example.backend.dto.UserDTO;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.model.User;
import com.example.backend.repository.OrderRepository;
import com.example.backend.repository.UserRepository;
import com.example.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * Service pour les Clients/Consommateurs (table 'users' existante)
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserServiceImpl implements UserService {
    
    private final UserRepository userRepository;
    private final OrderRepository orderRepository;
    
    @Override
    public List<UserDTO> findAll() {
        return userRepository.findAll().stream()
                .map(this::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    public UserDTO findById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("User", "id", id));
        return toDTO(user);
    }
    
    @Override
    public List<UserDTO> findUsersWithOrders() {
        // Get all unique user IDs from orders
        List<Long> userIdsWithOrders = orderRepository.findAll().stream()
                .map(order -> order.getUserId())
                .distinct()
                .collect(Collectors.toList());
        
        return userRepository.findAllById(userIdsWithOrders).stream()
                .map(user -> {
                    UserDTO dto = toDTO(user);
                    // Count orders for this user
                    long count = orderRepository.findByUserId(user.getId()).size();
                    dto.setOrderCount((int) count);
                    return dto;
                })
                .collect(Collectors.toList());
    }
    
    @Override
    public List<UserDTO> findUsersWithPositions() {
        return userRepository.findAll().stream()
                .filter(user -> user.getLatitude() != null && user.getLongitude() != null)
                .map(this::toDTO)
                .collect(Collectors.toList());
    }
    
    private UserDTO toDTO(User user) {
        return UserDTO.builder()
                .id(user.getId())
                .name(user.getName())
                .email(user.getEmail())
                .phone(user.getPhone())
                .address(user.getAddress())
                .latitude(user.getLatitude())
                .longitude(user.getLongitude())
                .profileImage(user.getProfileImage())
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}
