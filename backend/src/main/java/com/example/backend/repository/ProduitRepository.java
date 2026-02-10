package com.example.backend.repository;

import com.example.backend.model.Produit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProduitRepository extends JpaRepository<Produit, Long> {
    Optional<Produit> findByReference(String reference);
    List<Produit> findByCategoryId(Long categoryId);
    boolean existsByReference(String reference);
}
