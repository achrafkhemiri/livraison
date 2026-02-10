package com.example.backend.service;

import com.example.backend.dto.ClientDTO;
import java.util.List;

public interface ClientService {
    List<ClientDTO> findAll();
    ClientDTO findById(Long id);
    ClientDTO findByEmail(String email);
    ClientDTO create(ClientDTO clientDTO);
    ClientDTO update(Long id, ClientDTO clientDTO);
    void delete(Long id);
}
