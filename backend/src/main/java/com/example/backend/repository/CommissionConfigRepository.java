package com.example.backend.repository;

import com.example.backend.model.CommissionConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CommissionConfigRepository extends JpaRepository<CommissionConfig, Long>, JpaSpecificationExecutor<CommissionConfig> {

    Optional<CommissionConfig> findByLivreurIdAndActifTrue(@Param("livreurId") Long livreurId);

    List<CommissionConfig> findByLivreurIdOrderByDateDebutDesc(Long livreurId);

    List<CommissionConfig> findByActifTrue();

    @Query("SELECT cc FROM CommissionConfig cc WHERE cc.livreur.societe.id = :societeId AND cc.actif = true")
    List<CommissionConfig> findActiveBySocieteId(@Param("societeId") Long societeId);
}
