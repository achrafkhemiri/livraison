package com.example.backend.repository;

import com.example.backend.model.Tva;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface TvaRepository extends JpaRepository<Tva, Long> {
    Optional<Tva> findByCode(String code);
    List<Tva> findByActifTrue();
}
