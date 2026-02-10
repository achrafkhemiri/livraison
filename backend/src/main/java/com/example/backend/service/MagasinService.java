package com.example.backend.service;

import com.example.backend.dto.MagasinDTO;
import java.util.List;

public interface MagasinService {
    List<MagasinDTO> findAll();
    List<MagasinDTO> findAllActive();
    List<MagasinDTO> findBySocieteId(Long societeId);
    MagasinDTO findById(Long id);
    MagasinDTO findByNom(String nom);
    MagasinDTO create(MagasinDTO magasinDTO);
    MagasinDTO update(Long id, MagasinDTO magasinDTO);
    void delete(Long id);
}
