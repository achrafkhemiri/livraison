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

    // ═══ Bilan aggregation queries ═══

    // Totaux globaux (all-time) pour une société
    @Query("SELECT COUNT(cp), COALESCE(SUM(cp.montantTotal), 0) FROM CommissionPaiement cp WHERE cp.livreur.societe.id = :societeId")
    List<Object[]> getTotauxAllTime(@Param("societeId") Long societeId);

    // Totaux pour une année
    @Query("SELECT COUNT(cp), COALESCE(SUM(cp.montantTotal), 0) FROM CommissionPaiement cp WHERE cp.livreur.societe.id = :societeId AND YEAR(cp.createdAt) = :annee")
    List<Object[]> getTotauxPourAnnee(@Param("societeId") Long societeId, @Param("annee") int annee);

    // Totaux pour un mois précis
    @Query("SELECT COUNT(cp), COALESCE(SUM(cp.montantTotal), 0) FROM CommissionPaiement cp WHERE cp.livreur.societe.id = :societeId AND YEAR(cp.createdAt) = :annee AND MONTH(cp.createdAt) = :mois")
    List<Object[]> getTotauxPourMois(@Param("societeId") Long societeId, @Param("annee") int annee, @Param("mois") int mois);

    // Bilan par mois (all-time) → année, mois, count, sum
    @Query("SELECT YEAR(cp.createdAt), MONTH(cp.createdAt), COUNT(cp), COALESCE(SUM(cp.montantTotal), 0) FROM CommissionPaiement cp WHERE cp.livreur.societe.id = :societeId GROUP BY YEAR(cp.createdAt), MONTH(cp.createdAt) ORDER BY YEAR(cp.createdAt) DESC, MONTH(cp.createdAt) DESC")
    List<Object[]> findBilanParMoisAllTime(@Param("societeId") Long societeId);

    // Bilan par mois pour une année
    @Query("SELECT YEAR(cp.createdAt), MONTH(cp.createdAt), COUNT(cp), COALESCE(SUM(cp.montantTotal), 0) FROM CommissionPaiement cp WHERE cp.livreur.societe.id = :societeId AND YEAR(cp.createdAt) = :annee GROUP BY YEAR(cp.createdAt), MONTH(cp.createdAt) ORDER BY MONTH(cp.createdAt) DESC")
    List<Object[]> findBilanParMois(@Param("societeId") Long societeId, @Param("annee") int annee);

    // Bilan par livreur (all-time) → livreurId, nom, prenom, count, sum
    @Query("SELECT cp.livreur.id, cp.livreur.nom, cp.livreur.prenom, COUNT(cp), COALESCE(SUM(cp.montantTotal), 0) FROM CommissionPaiement cp WHERE cp.livreur.societe.id = :societeId GROUP BY cp.livreur.id, cp.livreur.nom, cp.livreur.prenom ORDER BY SUM(cp.montantTotal) ASC")
    List<Object[]> findBilanParLivreurAllTime(@Param("societeId") Long societeId);

    // Bilan par livreur pour une année
    @Query("SELECT cp.livreur.id, cp.livreur.nom, cp.livreur.prenom, COUNT(cp), COALESCE(SUM(cp.montantTotal), 0) FROM CommissionPaiement cp WHERE cp.livreur.societe.id = :societeId AND YEAR(cp.createdAt) = :annee GROUP BY cp.livreur.id, cp.livreur.nom, cp.livreur.prenom ORDER BY SUM(cp.montantTotal) ASC")
    List<Object[]> findBilanParLivreurPourAnnee(@Param("societeId") Long societeId, @Param("annee") int annee);

    // Bilan par livreur pour un mois précis
    @Query("SELECT cp.livreur.id, cp.livreur.nom, cp.livreur.prenom, COUNT(cp), COALESCE(SUM(cp.montantTotal), 0) FROM CommissionPaiement cp WHERE cp.livreur.societe.id = :societeId AND YEAR(cp.createdAt) = :annee AND MONTH(cp.createdAt) = :mois GROUP BY cp.livreur.id, cp.livreur.nom, cp.livreur.prenom ORDER BY SUM(cp.montantTotal) ASC")
    List<Object[]> findBilanParLivreurPourMois(@Param("societeId") Long societeId, @Param("annee") int annee, @Param("mois") int mois);

    // Années disponibles pour une société
    @Query("SELECT DISTINCT YEAR(cp.createdAt) FROM CommissionPaiement cp WHERE cp.livreur.societe.id = :societeId ORDER BY YEAR(cp.createdAt) DESC")
    List<Integer> findAnneesDisponibles(@Param("societeId") Long societeId);
}
