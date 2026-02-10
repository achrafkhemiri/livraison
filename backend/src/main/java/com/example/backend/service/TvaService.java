package com.example.backend.service;

import com.example.backend.dto.TvaDTO;
import java.util.List;

public interface TvaService {
    List<TvaDTO> findAll();
    List<TvaDTO> findAllActive();
    TvaDTO findById(Long id);
    TvaDTO findByCode(String code);
    TvaDTO create(TvaDTO tvaDTO);
    TvaDTO update(Long id, TvaDTO tvaDTO);
    void delete(Long id);
}
