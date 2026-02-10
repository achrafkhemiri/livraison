package com.example.backend.repository;

import com.example.backend.model.Role;
import com.example.backend.model.Utilisateur;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UtilisateurRepository extends JpaRepository<Utilisateur, Long> {
    Optional<Utilisateur> findByEmail(String email);
    List<Utilisateur> findByRole(Role role);
    List<Utilisateur> findByActifTrue();
    List<Utilisateur> findByRoleAndActifTrue(Role role);
    boolean existsByEmail(String email);
}
