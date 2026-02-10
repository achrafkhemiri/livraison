package com.example.backend.service;

import com.example.backend.dto.CreateUtilisateurDTO;
import com.example.backend.dto.UtilisateurDTO;
import com.example.backend.model.Role;
import java.util.List;

public interface UtilisateurService {
    List<UtilisateurDTO> findAll();
    List<UtilisateurDTO> findAllActive();
    List<UtilisateurDTO> findByRole(Role role);
    List<UtilisateurDTO> findAllLivreurs();
    List<UtilisateurDTO> findAllGerants();
    List<UtilisateurDTO> findAllLivreursWithPositions();
    UtilisateurDTO findById(Long id);
    UtilisateurDTO findByEmail(String email);
    UtilisateurDTO create(CreateUtilisateurDTO createDTO);
    UtilisateurDTO update(Long id, UtilisateurDTO utilisateurDTO);
    UtilisateurDTO updatePosition(Long id, Double latitude, Double longitude);
    void updatePassword(Long id, String newPassword);
    void delete(Long id);
}
