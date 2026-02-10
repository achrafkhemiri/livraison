package com.example.backend.service;

import com.example.backend.dto.SocieteDTO;
import java.util.List;

public interface SocieteService {
    List<SocieteDTO> findAll();
    SocieteDTO findById(Long id);
    SocieteDTO create(SocieteDTO societeDTO);
    SocieteDTO update(Long id, SocieteDTO societeDTO);
    void delete(Long id);
}
