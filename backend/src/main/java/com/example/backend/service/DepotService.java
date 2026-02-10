package com.example.backend.service;

import com.example.backend.dto.DepotDTO;
import java.util.List;

public interface DepotService {
    List<DepotDTO> findAll();
    List<DepotDTO> findAllActive();
    List<DepotDTO> findByMagasinId(Long magasinId);
    List<DepotDTO> findBySocieteId(Long societeId);
    List<DepotDTO> findActiveBySocieteId(Long societeId);
    DepotDTO findById(Long id);
    DepotDTO findByCode(String code);
    DepotDTO create(DepotDTO depotDTO);
    DepotDTO update(Long id, DepotDTO depotDTO);
    void delete(Long id);
}
