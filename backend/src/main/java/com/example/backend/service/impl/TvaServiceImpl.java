package com.example.backend.service.impl;

import com.example.backend.dto.TvaDTO;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.mapper.TvaMapper;
import com.example.backend.model.Tva;
import com.example.backend.repository.TvaRepository;
import com.example.backend.service.TvaService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class TvaServiceImpl implements TvaService {
    
    private final TvaRepository tvaRepository;
    private final TvaMapper tvaMapper;
    
    @Override
    @Transactional(readOnly = true)
    public List<TvaDTO> findAll() {
        return tvaRepository.findAll().stream()
                .map(tvaMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<TvaDTO> findAllActive() {
        return tvaRepository.findByActifTrue().stream()
                .map(tvaMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public TvaDTO findById(Long id) {
        Tva tva = tvaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("TVA", "id", id));
        return tvaMapper.toDTO(tva);
    }
    
    @Override
    @Transactional(readOnly = true)
    public TvaDTO findByCode(String code) {
        Tva tva = tvaRepository.findByCode(code)
                .orElseThrow(() -> new ResourceNotFoundException("TVA", "code", code));
        return tvaMapper.toDTO(tva);
    }
    
    @Override
    public TvaDTO create(TvaDTO tvaDTO) {
        Tva tva = tvaMapper.toEntity(tvaDTO);
        tva = tvaRepository.save(tva);
        return tvaMapper.toDTO(tva);
    }
    
    @Override
    public TvaDTO update(Long id, TvaDTO tvaDTO) {
        Tva tva = tvaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("TVA", "id", id));
        
        tvaMapper.updateEntity(tva, tvaDTO);
        tva = tvaRepository.save(tva);
        return tvaMapper.toDTO(tva);
    }
    
    @Override
    public void delete(Long id) {
        if (!tvaRepository.existsById(id)) {
            throw new ResourceNotFoundException("TVA", "id", id);
        }
        tvaRepository.deleteById(id);
    }
}
