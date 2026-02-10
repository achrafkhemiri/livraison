package com.example.backend.service.impl;

import com.example.backend.dto.SocieteDTO;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.mapper.SocieteMapper;
import com.example.backend.model.Societe;
import com.example.backend.repository.SocieteRepository;
import com.example.backend.service.SocieteService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class SocieteServiceImpl implements SocieteService {
    
    private final SocieteRepository societeRepository;
    private final SocieteMapper societeMapper;
    
    @Override
    @Transactional(readOnly = true)
    public List<SocieteDTO> findAll() {
        return societeRepository.findAll().stream()
                .map(societeMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public SocieteDTO findById(Long id) {
        Societe societe = societeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Société", "id", id));
        return societeMapper.toDTO(societe);
    }
    
    @Override
    public SocieteDTO create(SocieteDTO societeDTO) {
        Societe societe = societeMapper.toEntity(societeDTO);
        societe = societeRepository.save(societe);
        return societeMapper.toDTO(societe);
    }
    
    @Override
    public SocieteDTO update(Long id, SocieteDTO societeDTO) {
        Societe societe = societeRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Société", "id", id));
        
        societeMapper.updateEntity(societe, societeDTO);
        societe = societeRepository.save(societe);
        return societeMapper.toDTO(societe);
    }
    
    @Override
    public void delete(Long id) {
        if (!societeRepository.existsById(id)) {
            throw new ResourceNotFoundException("Société", "id", id);
        }
        societeRepository.deleteById(id);
    }
}
