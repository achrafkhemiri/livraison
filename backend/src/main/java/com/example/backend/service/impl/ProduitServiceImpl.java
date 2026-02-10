package com.example.backend.service.impl;

import com.example.backend.dto.ProduitDTO;
import com.example.backend.exception.DuplicateResourceException;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.mapper.ProduitMapper;
import com.example.backend.model.Produit;
import com.example.backend.model.Tva;
import com.example.backend.repository.ProduitRepository;
import com.example.backend.repository.TvaRepository;
import com.example.backend.service.ProduitService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class ProduitServiceImpl implements ProduitService {
    
    private final ProduitRepository produitRepository;
    private final TvaRepository tvaRepository;
    private final ProduitMapper produitMapper;
    
    @Override
    @Transactional(readOnly = true)
    public List<ProduitDTO> findAll() {
        return produitRepository.findAll().stream()
                .map(produitMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public ProduitDTO findById(Long id) {
        Produit produit = produitRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Produit", "id", id));
        return produitMapper.toDTO(produit);
    }
    
    @Override
    @Transactional(readOnly = true)
    public ProduitDTO findByReference(String reference) {
        Produit produit = produitRepository.findByReference(reference)
                .orElseThrow(() -> new ResourceNotFoundException("Produit", "reference", reference));
        return produitMapper.toDTO(produit);
    }
    
    @Override
    public ProduitDTO create(ProduitDTO produitDTO) {
        if (produitRepository.existsByReference(produitDTO.getCode())) {
            throw new DuplicateResourceException("Produit", "reference", produitDTO.getCode());
        }
        
        Produit produit = produitMapper.toEntity(produitDTO);
        
        if (produitDTO.getTvaId() != null) {
            Tva tva = tvaRepository.findById(produitDTO.getTvaId())
                    .orElseThrow(() -> new ResourceNotFoundException("TVA", "id", produitDTO.getTvaId()));
            produit.setIdTva(tva.getId());
        }
        
        produit = produitRepository.save(produit);
        return produitMapper.toDTO(produit);
    }
    
    @Override
    public ProduitDTO update(Long id, ProduitDTO produitDTO) {
        Produit produit = produitRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Produit", "id", id));
        
        if (produitDTO.getCode() != null && !produitDTO.getCode().equals(produit.getReference())
                && produitRepository.existsByReference(produitDTO.getCode())) {
            throw new DuplicateResourceException("Produit", "reference", produitDTO.getCode());
        }
        
        Tva tva = null;
        if (produitDTO.getTvaId() != null) {
            tva = tvaRepository.findById(produitDTO.getTvaId())
                    .orElseThrow(() -> new ResourceNotFoundException("TVA", "id", produitDTO.getTvaId()));
        }
        
        produitMapper.updateEntity(produit, produitDTO, tva);
        
        produit = produitRepository.save(produit);
        return produitMapper.toDTO(produit);
    }
    
    @Override
    public void delete(Long id) {
        if (!produitRepository.existsById(id)) {
            throw new ResourceNotFoundException("Produit", "id", id);
        }
        produitRepository.deleteById(id);
    }
}
