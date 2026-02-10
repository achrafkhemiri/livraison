package com.example.backend.config;

import com.example.backend.model.Role;
import com.example.backend.model.Utilisateur;
import com.example.backend.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
@Slf4j
public class DataInitializer implements CommandLineRunner {
    
    private final UtilisateurRepository utilisateurRepository;
    private final PasswordEncoder passwordEncoder;
    
    @Override
    public void run(String... args) {
        // Create or update default admin user
        Utilisateur admin = utilisateurRepository.findByEmail("admin@livraison.tn")
                .orElse(Utilisateur.builder()
                        .nom("Admin")
                        .prenom("System")
                        .email("admin@livraison.tn")
                        .telephone("00000000")
                        .role(Role.GERANT)
                        .actif(true)
                        .build());
        
        // Always update password to ensure it's properly encoded
        admin.setPassword(passwordEncoder.encode("admin123"));
        utilisateurRepository.save(admin);
        log.info("Utilisateur admin prêt: admin@livraison.tn / admin123");
        
        // Create or update default delivery user
        Utilisateur livreur = utilisateurRepository.findByEmail("livreur@livraison.tn")
                .orElse(Utilisateur.builder()
                        .nom("Livreur")
                        .prenom("Test")
                        .email("livreur@livraison.tn")
                        .telephone("11111111")
                        .role(Role.LIVREUR)
                        .actif(true)
                        .build());
        
        // Always update password to ensure it's properly encoded
        livreur.setPassword(passwordEncoder.encode("livreur123"));
        utilisateurRepository.save(livreur);
        log.info("Utilisateur livreur prêt: livreur@livraison.tn / livreur123");
    }
}
