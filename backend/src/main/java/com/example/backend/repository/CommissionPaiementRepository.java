package com.example.backend.repository;

import com.example.backend.model.CommissionPaiement;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

@Repository
public interface CommissionPaiementRepository extends JpaRepository<CommissionPaiement, Long>, JpaSpecificationExecutor<CommissionPaiement> {

    List<CommissionPaiement> findByLivreurIdOrderByCreatedAtDesc(Long livreurId);

    Optional<CommissionPaiement> findByOrderId(Long orderId);

    List<CommissionPaiement> findByLivreurPayeFalse();

    List<CommissionPaiement> findByAdminValideFalse();

    List<CommissionPaiement> findByLivreurPayeTrueAndAdminValideFalse();

    @Query("SELECT cp FROM CommissionPaiement cp WHERE cp.livreur.societe.id = :societeId ORDER BY cp.createdAt DESC")
    List<CommissionPaiement> findBySocieteId(@Param("societeId") Long societeId);

    @Query("SELECT COALESCE(SUM(cp.montantTotal), 0) FROM CommissionPaiement cp WHERE cp.livreur.id = :livreurId")
    BigDecimal sumTotalByLivreurId(@Param("livreurId") Long livreurId);

    @Query("SELECT COALESCE(SUM(cp.montantTotal), 0) FROM CommissionPaiement cp WHERE cp.livreur.id = :livreurId AND cp.livreurPaye = true AND cp.adminValide = true")
    BigDecimal sumPayeByLivreurId(@Param("livreurId") Long livreurId);

    @Query("SELECT COALESCE(SUM(cp.montantTotal), 0) FROM CommissionPaiement cp WHERE cp.livreur.id = :livreurId AND (cp.livreurPaye = false OR cp.adminValide = false)")
    BigDecimal sumNonPayeByLivreurId(@Param("livreurId") Long livreurId);

    @Query("SELECT COUNT(cp) FROM CommissionPaiement cp WHERE cp.livreur.id = :livreurId AND cp.livreurPaye = true AND cp.adminValide = true")
    Long countValidesByLivreurId(@Param("livreurId") Long livreurId);

    @Query("SELECT COUNT(cp) FROM CommissionPaiement cp WHERE cp.livreur.id = :livreurId AND (cp.livreurPaye = false OR cp.adminValide = false)")
    Long countEnAttenteByLivreurId(@Param("livreurId") Long livreurId);

    @Query("SELECT COUNT(cp) FROM CommissionPaiement cp WHERE cp.livreur.id = :livreurId")
    Long countByLivreurId(@Param("livreurId") Long livreurId);
}
