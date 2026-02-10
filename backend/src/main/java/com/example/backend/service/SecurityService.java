package com.example.backend.service;

import com.example.backend.model.Utilisateur;
import com.example.backend.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class SecurityService {
    
    private final UtilisateurRepository utilisateurRepository;
    
    /**
     * Get the currently authenticated user
     */
    public Utilisateur getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            return null;
        }
        
        String email = auth.getName();
        return utilisateurRepository.findByEmail(email).orElse(null);
    }
    
    /**
     * Get the societe ID of the currently authenticated user
     */
    public Long getCurrentUserSocieteId() {
        Utilisateur user = getCurrentUser();
        if (user != null && user.getSociete() != null) {
            return user.getSociete().getId();
        }
        return null;
    }
    
    /**
     * Get the ID of the currently authenticated user
     */
    public Long getCurrentUserId() {
        Utilisateur user = getCurrentUser();
        return user != null ? user.getId() : null;
    }
}
