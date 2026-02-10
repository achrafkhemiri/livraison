package com.example.backend.service.impl;

import com.example.backend.dto.ClientDTO;
import com.example.backend.exception.DuplicateResourceException;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.mapper.ClientMapper;
import com.example.backend.model.Client;
import com.example.backend.repository.ClientRepository;
import com.example.backend.service.ClientService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class ClientServiceImpl implements ClientService {
    
    private final ClientRepository clientRepository;
    private final ClientMapper clientMapper;
    
    @Override
    @Transactional(readOnly = true)
    public List<ClientDTO> findAll() {
        return clientRepository.findAll().stream()
                .map(clientMapper::toDTO)
                .collect(Collectors.toList());
    }
    
    @Override
    @Transactional(readOnly = true)
    public ClientDTO findById(Long id) {
        Client client = clientRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Client", "id", id));
        return clientMapper.toDTO(client);
    }
    
    @Override
    @Transactional(readOnly = true)
    public ClientDTO findByEmail(String email) {
        Client client = clientRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Client", "email", email));
        return clientMapper.toDTO(client);
    }
    
    @Override
    public ClientDTO create(ClientDTO clientDTO) {
        if (clientDTO.getEmail() != null && clientRepository.existsByEmail(clientDTO.getEmail())) {
            throw new DuplicateResourceException("Client", "email", clientDTO.getEmail());
        }
        
        Client client = clientMapper.toEntity(clientDTO);
        client = clientRepository.save(client);
        return clientMapper.toDTO(client);
    }
    
    @Override
    public ClientDTO update(Long id, ClientDTO clientDTO) {
        Client client = clientRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Client", "id", id));
        
        if (clientDTO.getEmail() != null && !clientDTO.getEmail().equals(client.getEmail())
                && clientRepository.existsByEmail(clientDTO.getEmail())) {
            throw new DuplicateResourceException("Client", "email", clientDTO.getEmail());
        }
        
        clientMapper.updateEntity(client, clientDTO);
        client = clientRepository.save(client);
        return clientMapper.toDTO(client);
    }
    
    @Override
    public void delete(Long id) {
        if (!clientRepository.existsById(id)) {
            throw new ResourceNotFoundException("Client", "id", id);
        }
        clientRepository.deleteById(id);
    }
}
