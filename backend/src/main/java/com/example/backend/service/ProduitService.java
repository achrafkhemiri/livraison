package com.example.backend.service;

import com.example.backend.dto.ProduitDTO;
import java.util.List;

public interface ProduitService {
    List<ProduitDTO> findAll();
    ProduitDTO findById(Long id);
    ProduitDTO findByReference(String reference);
    ProduitDTO create(ProduitDTO produitDTO);
    ProduitDTO update(Long id, ProduitDTO produitDTO);
    void delete(Long id);
}
