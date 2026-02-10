package com.example.backend.service.impl;

import com.example.backend.dto.MagasinDTO;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.mapper.MagasinMapper;
import com.example.backend.model.Magasin;
import com.example.backend.model.Societe;
import com.example.backend.repository.MagasinRepository;
import com.example.backend.repository.SocieteRepository;
import com.example.backend.service.MagasinService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class MagasinServiceImpl implements MagasinService {
    
    private final MagasinRepository magasinRepository;
    private final SocieteRepository societeRepository;
    private final MagasinMapper magasinMapper;
    
    @Override
    @Transactional(readOnly = true)
    public List<MagasinDTO> findAll() {
        return magasinRepository.findAll().stream()
                .map(magasinMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<MagasinDTO> findAllActive() {
        // All magasins are considered active in the new table structure
        return findAll();
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<MagasinDTO> findBySocieteId(Long societeId) {
        return magasinRepository.findBySocieteId(societeId).stream()
                .map(magasinMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public MagasinDTO findById(Long id) {
        Magasin magasin = magasinRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Magasin", "id", id));
        return magasinMapper.toDTO(magasin);
    }
    
    @Override
    @Transactional(readOnly = true)
    public MagasinDTO findByNom(String nom) {
        Magasin magasin = magasinRepository.findByNomMagasin(nom)
                .orElseThrow(() -> new ResourceNotFoundException("Magasin", "nom", nom));
        return magasinMapper.toDTO(magasin);
    }
    
    @Override
    public MagasinDTO create(MagasinDTO magasinDTO) {
        Magasin magasin = magasinMapper.toEntity(magasinDTO);
        
        if (magasinDTO.getSocieteId() != null) {
            Societe societe = societeRepository.findById(magasinDTO.getSocieteId())
                    .orElseThrow(() -> new ResourceNotFoundException("Société", "id", magasinDTO.getSocieteId()));
            magasin.setSociete(societe);
        }
        
        magasin = magasinRepository.save(magasin);
        return magasinMapper.toDTO(magasin);
    }
    
    @Override
    public MagasinDTO update(Long id, MagasinDTO magasinDTO) {
        Magasin magasin = magasinRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Magasin", "id", id));
        
        magasinMapper.updateEntity(magasin, magasinDTO);
        
        if (magasinDTO.getSocieteId() != null) {
            Societe societe = societeRepository.findById(magasinDTO.getSocieteId())
                    .orElseThrow(() -> new ResourceNotFoundException("Société", "id", magasinDTO.getSocieteId()));
            magasin.setSociete(societe);
        }
        
        magasin = magasinRepository.save(magasin);
        return magasinMapper.toDTO(magasin);
    }
    
    @Override
    public void delete(Long id) {
        if (!magasinRepository.existsById(id)) {
            throw new ResourceNotFoundException("Magasin", "id", id);
        }
        magasinRepository.deleteById(id);
    }
}
