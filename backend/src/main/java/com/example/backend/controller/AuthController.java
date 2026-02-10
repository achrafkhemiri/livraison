package com.example.backend.controller;

import com.example.backend.dto.CreateUtilisateurDTO;
import com.example.backend.dto.UtilisateurDTO;
import com.example.backend.dto.auth.LoginRequest;
import com.example.backend.dto.auth.LoginResponse;
import com.example.backend.model.Utilisateur;
import com.example.backend.repository.UtilisateurRepository;
import com.example.backend.security.JwtTokenProvider;
import com.example.backend.service.UtilisateurService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
@CrossOrigin(origins = "*")
public class AuthController {
    
    private final AuthenticationManager authenticationManager;
    private final JwtTokenProvider jwtTokenProvider;
    private final UtilisateurRepository utilisateurRepository;
    private final UtilisateurService utilisateurService;
    
    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest loginRequest) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        loginRequest.getEmail(),
                        loginRequest.getPassword()
                )
        );
        
        SecurityContextHolder.getContext().setAuthentication(authentication);
        String token = jwtTokenProvider.generateToken(authentication);
        
        Utilisateur utilisateur = utilisateurRepository.findByEmail(loginRequest.getEmail())
                .orElseThrow();
        
        LoginResponse.LoginResponseBuilder responseBuilder = LoginResponse.builder()
                .token(token)
                .type("Bearer")
                .id(utilisateur.getId())
                .email(utilisateur.getEmail())
                .nom(utilisateur.getNom())
                .prenom(utilisateur.getPrenom())
                .role(utilisateur.getRole());
        
        // Include societe info for admin/gerant
        if (utilisateur.getSociete() != null) {
            responseBuilder.societeId(utilisateur.getSociete().getId())
                           .societeNom(utilisateur.getSociete().getRaisonSociale());
        }
        
        LoginResponse response = responseBuilder.build();
        
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/register")
    public ResponseEntity<UtilisateurDTO> register(@Valid @RequestBody CreateUtilisateurDTO createDTO) {
        UtilisateurDTO created = utilisateurService.create(createDTO);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }
    
    @GetMapping("/me")
    public ResponseEntity<UtilisateurDTO> getCurrentUser(Authentication authentication) {
        String email = authentication.getName();
        return ResponseEntity.ok(utilisateurService.findByEmail(email));
    }
}
