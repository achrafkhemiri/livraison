package com.example.backend.service.impl;

import com.example.backend.dto.CreateUtilisateurDTO;
import com.example.backend.dto.UtilisateurDTO;
import com.example.backend.exception.DuplicateResourceException;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.mapper.UtilisateurMapper;
import com.example.backend.model.Role;
import com.example.backend.model.Utilisateur;
import com.example.backend.repository.UtilisateurRepository;
import com.example.backend.service.UtilisateurService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class UtilisateurServiceImpl implements UtilisateurService {
    
    private final UtilisateurRepository utilisateurRepository;
    private final UtilisateurMapper utilisateurMapper;
    private final PasswordEncoder passwordEncoder;
    
    @Override
    @Transactional(readOnly = true)
    public List<UtilisateurDTO> findAll() {
        return utilisateurRepository.findAll().stream()
                .map(utilisateurMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<UtilisateurDTO> findAllActive() {
        return utilisateurRepository.findByActifTrue().stream()
                .map(utilisateurMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<UtilisateurDTO> findByRole(Role role) {
        return utilisateurRepository.findByRole(role).stream()
                .map(utilisateurMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<UtilisateurDTO> findAllLivreurs() {
        return findByRole(Role.LIVREUR);
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<UtilisateurDTO> findAllGerants() {
        return findByRole(Role.GERANT);
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<UtilisateurDTO> findAllLivreursWithPositions() {
        return utilisateurRepository.findByRoleAndActifTrue(Role.LIVREUR).stream()
                .filter(l -> l.getLatitude() != null && l.getLongitude() != null)
                .map(utilisateurMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public UtilisateurDTO findById(Long id) {
        Utilisateur utilisateur = utilisateurRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur", "id", id));
        return utilisateurMapper.toDTO(utilisateur);
    }
    
    @Override
    @Transactional(readOnly = true)
    public UtilisateurDTO findByEmail(String email) {
        Utilisateur utilisateur = utilisateurRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur", "email", email));
        return utilisateurMapper.toDTO(utilisateur);
    }
    
    @Override
    public UtilisateurDTO create(CreateUtilisateurDTO createDTO) {
        if (utilisateurRepository.existsByEmail(createDTO.getEmail())) {
            throw new DuplicateResourceException("Utilisateur", "email", createDTO.getEmail());
        }
        
        Utilisateur utilisateur = utilisateurMapper.toEntity(createDTO);
        utilisateur.setPassword(passwordEncoder.encode(createDTO.getPassword()));
        
        utilisateur = utilisateurRepository.save(utilisateur);
        return utilisateurMapper.toDTO(utilisateur);
    }
    
    @Override
    public UtilisateurDTO update(Long id, UtilisateurDTO utilisateurDTO) {
        Utilisateur utilisateur = utilisateurRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur", "id", id));
        
        if (utilisateurDTO.getEmail() != null && !utilisateurDTO.getEmail().equals(utilisateur.getEmail())
                && utilisateurRepository.existsByEmail(utilisateurDTO.getEmail())) {
            throw new DuplicateResourceException("Utilisateur", "email", utilisateurDTO.getEmail());
        }
        
        utilisateurMapper.updateEntity(utilisateur, utilisateurDTO);
        utilisateur = utilisateurRepository.save(utilisateur);
        return utilisateurMapper.toDTO(utilisateur);
    }
    
    @Override
    public void updatePassword(Long id, String newPassword) {
        Utilisateur utilisateur = utilisateurRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur", "id", id));
        
        utilisateur.setPassword(passwordEncoder.encode(newPassword));
        utilisateurRepository.save(utilisateur);
    }
    
    @Override
    public UtilisateurDTO updatePosition(Long id, Double latitude, Double longitude) {
        Utilisateur utilisateur = utilisateurRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Utilisateur", "id", id));
        
        utilisateur.setLatitude(latitude);
        utilisateur.setLongitude(longitude);
        utilisateur.setDernierePositionAt(LocalDateTime.now());
        
        utilisateur = utilisateurRepository.save(utilisateur);
        return utilisateurMapper.toDTO(utilisateur);
    }
    
    @Override
    public void delete(Long id) {
        if (!utilisateurRepository.existsById(id)) {
            throw new ResourceNotFoundException("Utilisateur", "id", id);
        }
        utilisateurRepository.deleteById(id);
    }
}
