package com.example.backend.mapper;

import com.example.backend.dto.ClientDTO;
import com.example.backend.model.Client;
import org.springframework.stereotype.Component;

@Component
public class ClientMapper {
    
    public ClientDTO toDTO(Client client) {
        if (client == null) return null;
        
        return ClientDTO.builder()
                .id(client.getId())
                .nom(client.getNom())
                .prenom(client.getPrenom())
                .email(client.getEmail())
                .telephone(client.getTelephone())
                .adresse(client.getAdresse())
                .ville(client.getVille())
                .codePostal(client.getCodePostal())
                .latitude(client.getLatitude())
                .longitude(client.getLongitude())
                .createdAt(client.getCreatedAt())
                .updatedAt(client.getUpdatedAt())
                .build();
    }
    
    public Client toEntity(ClientDTO dto) {
        if (dto == null) return null;
        
        return Client.builder()
                .id(dto.getId())
                .nom(dto.getNom())
                .prenom(dto.getPrenom())
                .email(dto.getEmail())
                .telephone(dto.getTelephone())
                .adresse(dto.getAdresse())
                .ville(dto.getVille())
                .codePostal(dto.getCodePostal())
                .latitude(dto.getLatitude())
                .longitude(dto.getLongitude())
                .build();
    }
    
    public void updateEntity(Client client, ClientDTO dto) {
        if (dto.getNom() != null) client.setNom(dto.getNom());
        if (dto.getPrenom() != null) client.setPrenom(dto.getPrenom());
        if (dto.getEmail() != null) client.setEmail(dto.getEmail());
        if (dto.getTelephone() != null) client.setTelephone(dto.getTelephone());
        if (dto.getAdresse() != null) client.setAdresse(dto.getAdresse());
        if (dto.getVille() != null) client.setVille(dto.getVille());
        if (dto.getCodePostal() != null) client.setCodePostal(dto.getCodePostal());
        if (dto.getLatitude() != null) client.setLatitude(dto.getLatitude());
        if (dto.getLongitude() != null) client.setLongitude(dto.getLongitude());
    }
}
