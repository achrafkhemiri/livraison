package com.example.backend.repository;

import com.example.backend.model.Depot;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface DepotRepository extends JpaRepository<Depot, Long> {
    Optional<Depot> findByCode(String code);
    List<Depot> findByMagasinId(Long magasinId);
    List<Depot> findByActifTrue();
    
    // Filter by societe (depots of magasins belonging to a societe)
    @Query("SELECT d FROM Depot d WHERE d.magasin.societe.id = :societeId")
    List<Depot> findBySocieteId(@Param("societeId") Long societeId);
    
    @Query("SELECT d FROM Depot d WHERE d.magasin.societe.id = :societeId AND d.actif = true")
    List<Depot> findBySocieteIdAndActifTrue(@Param("societeId") Long societeId);
}
