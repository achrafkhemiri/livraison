package com.example.backend.service.impl;

import com.example.backend.dto.DepotDTO;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.mapper.DepotMapper;
import com.example.backend.model.Depot;
import com.example.backend.model.Magasin;
import com.example.backend.repository.DepotRepository;
import com.example.backend.repository.MagasinRepository;
import com.example.backend.service.DepotService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class DepotServiceImpl implements DepotService {
    
    private final DepotRepository depotRepository;
    private final MagasinRepository magasinRepository;
    private final DepotMapper depotMapper;
    
    @Override
    @Transactional(readOnly = true)
    public List<DepotDTO> findAll() {
        return depotRepository.findAll().stream()
                .map(depotMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<DepotDTO> findAllActive() {
        return depotRepository.findByActifTrue().stream()
                .map(depotMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<DepotDTO> findByMagasinId(Long magasinId) {
        return depotRepository.findByMagasinId(magasinId).stream()
                .map(depotMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<DepotDTO> findBySocieteId(Long societeId) {
        return depotRepository.findBySocieteId(societeId).stream()
                .map(depotMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<DepotDTO> findActiveBySocieteId(Long societeId) {
        return depotRepository.findBySocieteIdAndActifTrue(societeId).stream()
                .map(depotMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public DepotDTO findById(Long id) {
        Depot depot = depotRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Dépôt", "id", id));
        return depotMapper.toDTO(depot);
    }
    
    @Override
    @Transactional(readOnly = true)
    public DepotDTO findByCode(String code) {
        Depot depot = depotRepository.findByCode(code)
                .orElseThrow(() -> new ResourceNotFoundException("Dépôt", "code", code));
        return depotMapper.toDTO(depot);
    }
    
    @Override
    public DepotDTO create(DepotDTO depotDTO) {
        Depot depot = depotMapper.toEntity(depotDTO);
        
        if (depotDTO.getMagasinId() != null) {
            Magasin magasin = magasinRepository.findById(depotDTO.getMagasinId())
                    .orElseThrow(() -> new ResourceNotFoundException("Magasin", "id", depotDTO.getMagasinId()));
            depot.setMagasin(magasin);
        }
        
        depot = depotRepository.save(depot);
        return depotMapper.toDTO(depot);
    }
    
    @Override
    public DepotDTO update(Long id, DepotDTO depotDTO) {
        Depot depot = depotRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Dépôt", "id", id));
        
        depotMapper.updateEntity(depot, depotDTO);
        
        if (depotDTO.getMagasinId() != null) {
            Magasin magasin = magasinRepository.findById(depotDTO.getMagasinId())
                    .orElseThrow(() -> new ResourceNotFoundException("Magasin", "id", depotDTO.getMagasinId()));
            depot.setMagasin(magasin);
        }
        
        depot = depotRepository.save(depot);
        return depotMapper.toDTO(depot);
    }
    
    @Override
    public void delete(Long id) {
        if (!depotRepository.existsById(id)) {
            throw new ResourceNotFoundException("Dépôt", "id", id);
        }
        depotRepository.deleteById(id);
    }
}
