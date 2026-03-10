package com.example.backend.service;

import com.example.backend.dto.CommissionConfigDTO;
import com.example.backend.dto.CommissionPaiementDTO;
import com.example.backend.dto.LivreurCommissionSummaryDTO;
import com.example.backend.dto.BilanDTO;
import com.example.backend.dto.PageResponse;

import java.math.BigDecimal;
import java.util.List;

public interface CommissionService {

    // ── Commission Config ──────────────────────────────────
    CommissionConfigDTO createConfig(CommissionConfigDTO dto);
    CommissionConfigDTO updateConfig(Long id, CommissionConfigDTO dto);
    CommissionConfigDTO getConfigById(Long id);
    CommissionConfigDTO getActiveConfigByLivreurId(Long livreurId);
    List<CommissionConfigDTO> getConfigsByLivreurId(Long livreurId);
    List<CommissionConfigDTO> getAllActiveConfigs();
    PageResponse<CommissionConfigDTO> searchConfigs(String search, int page, int size);
    void deactivateConfig(Long id);

    // ── Commission Paiement ────────────────────────────────
    CommissionPaiementDTO generateCommission(Long orderId, BigDecimal distanceKm);
    CommissionPaiementDTO getPaiementById(Long id);
    CommissionPaiementDTO getPaiementByOrderId(Long orderId);
    List<CommissionPaiementDTO> getPaiementsByLivreurId(Long livreurId);
    List<CommissionPaiementDTO> getAllPaiements();
    PageResponse<CommissionPaiementDTO> searchPaiements(String search, String status, int page, int size);
    PageResponse<CommissionPaiementDTO> searchPaiementsByLivreur(Long livreurId, String search, String status, int page, int size);
    CommissionPaiementDTO markLivreurPaye(Long paiementId);
    CommissionPaiementDTO markAdminValide(Long paiementId);
    CommissionPaiementDTO unmarkLivreurPaye(Long paiementId);
    CommissionPaiementDTO unmarkAdminValide(Long paiementId);

    // ── Summaries ──────────────────────────────────────────
    LivreurCommissionSummaryDTO getLivreurSummary(Long livreurId);
    List<LivreurCommissionSummaryDTO> getAllLivreurSummaries();

    // ── Recalculate ────────────────────────────────────────
    int recalculateAllDistances();

    // ── Bilan ──────────────────────────────────────────────
    BilanDTO getBilan(Long societeId, Integer annee, Integer mois);
    List<Integer> getAnneesDisponibles(Long societeId);
}
