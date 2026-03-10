package com.example.backend.service.impl;

import com.example.backend.dto.CommissionConfigDTO;
import com.example.backend.dto.CommissionPaiementDTO;
import com.example.backend.dto.LivreurCommissionSummaryDTO;
import com.example.backend.dto.BilanDTO;
import com.example.backend.dto.BilanPeriodeDTO;
import com.example.backend.dto.BilanLivreurDTO;
import com.example.backend.dto.PageResponse;
import com.example.backend.exception.BadRequestException;
import com.example.backend.exception.ResourceNotFoundException;
import com.example.backend.mapper.CommissionMapper;
import com.example.backend.model.*;
import com.example.backend.repository.*;
import com.example.backend.service.CommissionService;
import com.example.backend.service.OsrmService;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class CommissionServiceImpl implements CommissionService {

    private final CommissionConfigRepository configRepository;
    private final CommissionPaiementRepository paiementRepository;
    private final UtilisateurRepository utilisateurRepository;
    private final OrderRepository orderRepository;
    private final SocieteRepository societeRepository;
    private final CommissionMapper mapper;
    private final OsrmService osrmService;

    // ═══════════════════════════════════════════════════════
    //  Commission Config
    // ═══════════════════════════════════════════════════════

    @Override
    @Transactional
    public CommissionConfigDTO createConfig(CommissionConfigDTO dto) {
        Utilisateur livreur = utilisateurRepository.findById(dto.getLivreurId())
                .orElseThrow(() -> new ResourceNotFoundException("Livreur non trouvé avec l'id: " + dto.getLivreurId()));

        if (livreur.getRole() != Role.LIVREUR) {
            throw new BadRequestException("L'utilisateur n'est pas un livreur");
        }

        // Deactivate current active config for this livreur
        configRepository.findByLivreurIdAndActifTrue(dto.getLivreurId())
                .ifPresent(existingConfig -> {
                    existingConfig.setActif(false);
                    existingConfig.setDateFin(LocalDateTime.now());
                    configRepository.save(existingConfig);
                });

        CommissionConfig config = CommissionConfig.builder()
                .livreur(livreur)
                .montantFixe(dto.getMontantFixe() != null ? dto.getMontantFixe() : BigDecimal.ZERO)
                .prixParKm(dto.getPrixParKm() != null ? dto.getPrixParKm() : BigDecimal.ZERO)
                .bonus(dto.getBonus() != null ? dto.getBonus() : BigDecimal.ZERO)
                .inclureDistanceCollection(dto.getInclureDistanceCollection() != null ? dto.getInclureDistanceCollection() : false)
                .actif(true)
                .dateDebut(LocalDateTime.now())
                .build();

        config = configRepository.save(config);
        return mapper.toConfigDTO(config);
    }

    @Override
    @Transactional
    public CommissionConfigDTO updateConfig(Long id, CommissionConfigDTO dto) {
        CommissionConfig config = configRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Commission config non trouvée avec l'id: " + id));

        if (dto.getMontantFixe() != null) config.setMontantFixe(dto.getMontantFixe());
        if (dto.getPrixParKm() != null) config.setPrixParKm(dto.getPrixParKm());
        if (dto.getBonus() != null) config.setBonus(dto.getBonus());
        if (dto.getInclureDistanceCollection() != null) config.setInclureDistanceCollection(dto.getInclureDistanceCollection());
        if (dto.getActif() != null) config.setActif(dto.getActif());

        config = configRepository.save(config);
        return mapper.toConfigDTO(config);
    }

    @Override
    public CommissionConfigDTO getConfigById(Long id) {
        CommissionConfig config = configRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Commission config non trouvée avec l'id: " + id));
        return mapper.toConfigDTO(config);
    }

    @Override
    public CommissionConfigDTO getActiveConfigByLivreurId(Long livreurId) {
        return configRepository.findByLivreurIdAndActifTrue(livreurId)
                .map(mapper::toConfigDTO)
                .orElse(null);
    }

    @Override
    public List<CommissionConfigDTO> getConfigsByLivreurId(Long livreurId) {
        return configRepository.findByLivreurIdOrderByDateDebutDesc(livreurId).stream()
                .map(mapper::toConfigDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<CommissionConfigDTO> getAllActiveConfigs() {
        return configRepository.findByActifTrue().stream()
                .map(mapper::toConfigDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<CommissionConfigDTO> searchConfigs(String search, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "dateDebut"));

        Specification<CommissionConfig> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.isTrue(root.get("actif")));

            if (search != null && !search.isBlank()) {
                String pattern = "%" + search.toLowerCase() + "%";
                Join<CommissionConfig, Utilisateur> livreurJoin = root.join("livreur", JoinType.LEFT);
                Predicate nomPred = cb.like(cb.lower(livreurJoin.get("nom")), pattern);
                Predicate prenomPred = cb.like(cb.lower(livreurJoin.get("prenom")), pattern);
                predicates.add(cb.or(nomPred, prenomPred));
            }

            query.distinct(true);
            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<CommissionConfig> resultPage = configRepository.findAll(spec, pageable);
        List<CommissionConfigDTO> content = resultPage.getContent().stream()
                .map(mapper::toConfigDTO)
                .collect(Collectors.toList());

        return PageResponse.<CommissionConfigDTO>builder()
                .content(content)
                .page(resultPage.getNumber())
                .size(resultPage.getSize())
                .totalElements(resultPage.getTotalElements())
                .totalPages(resultPage.getTotalPages())
                .first(resultPage.isFirst())
                .last(resultPage.isLast())
                .build();
    }

    @Override
    @Transactional
    public void deactivateConfig(Long id) {
        CommissionConfig config = configRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Commission config non trouvée avec l'id: " + id));
        config.setActif(false);
        config.setDateFin(LocalDateTime.now());
        configRepository.save(config);
    }

    // ═══════════════════════════════════════════════════════
    //  Commission Paiement
    // ═══════════════════════════════════════════════════════

    @Override
    @Transactional
    public CommissionPaiementDTO generateCommission(Long orderId, BigDecimal distanceKm) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Commande non trouvée avec l'id: " + orderId));

        if (order.getLivreur() == null) {
            throw new BadRequestException("Cette commande n'a pas de livreur assigné");
        }

        // Check if commission already exists for this order
        if (paiementRepository.findByOrderId(orderId).isPresent()) {
            throw new BadRequestException("Une commission existe déjà pour la commande: " + orderId);
        }

        Utilisateur livreur = order.getLivreur();

        // Get active config for this livreur (or use defaults)
        CommissionConfig activeConfig = configRepository.findByLivreurIdAndActifTrue(livreur.getId())
                .orElse(null);

        BigDecimal montantFixe;
        BigDecimal prixParKm;
        BigDecimal bonus;
        boolean inclureCollection;

        if (activeConfig != null) {
            montantFixe = activeConfig.getMontantFixe();
            prixParKm = activeConfig.getPrixParKm();
            bonus = activeConfig.getBonus();
            inclureCollection = Boolean.TRUE.equals(activeConfig.getInclureDistanceCollection());
        } else {
            montantFixe = BigDecimal.ZERO;
            prixParKm = BigDecimal.ZERO;
            bonus = BigDecimal.ZERO;
            inclureCollection = false;
        }

        // Calculate delivery distance (always) - depot → client delivery address
        // If Flutter provided OSRM distance, use it; otherwise calculate via backend OSRM
        BigDecimal distanceLivraison;
        if (distanceKm != null && distanceKm.compareTo(BigDecimal.ZERO) > 0) {
            distanceLivraison = distanceKm;
        } else {
            distanceLivraison = calculateDeliveryDistance(order);
        }

        // Calculate collection distance (optional) - depot(s) for collection
        BigDecimal distanceCollection = BigDecimal.ZERO;
        if (inclureCollection) {
            distanceCollection = calculateCollectionDistance(order);
        }

        BigDecimal totalDistance = distanceLivraison.add(distanceCollection);

        // Formula: montantFixe + (totalDistance × prixParKm) + bonus
        BigDecimal montantTotal = montantFixe
                .add(totalDistance.multiply(prixParKm))
                .add(bonus)
                .setScale(3, RoundingMode.HALF_UP);

        CommissionPaiement paiement = CommissionPaiement.builder()
                .order(order)
                .livreur(livreur)
                .commissionConfig(activeConfig)
                .montantFixe(montantFixe)
                .prixParKm(prixParKm)
                .distanceKm(totalDistance)
                .distanceCollectionKm(distanceCollection)
                .distanceLivraisonKm(distanceLivraison)
                .bonus(bonus)
                .montantTotal(montantTotal)
                .livreurPaye(false)
                .adminValide(false)
                .build();

        paiement = paiementRepository.save(paiement);
        return mapper.toPaiementDTO(paiement);
    }

    @Override
    public CommissionPaiementDTO getPaiementById(Long id) {
        CommissionPaiement paiement = paiementRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Commission paiement non trouvé avec l'id: " + id));
        return mapper.toPaiementDTO(paiement);
    }

    @Override
    public CommissionPaiementDTO getPaiementByOrderId(Long orderId) {
        return paiementRepository.findByOrderId(orderId)
                .map(mapper::toPaiementDTO)
                .orElse(null);
    }

    @Override
    public List<CommissionPaiementDTO> getPaiementsByLivreurId(Long livreurId) {
        return paiementRepository.findByLivreurIdOrderByCreatedAtDesc(livreurId).stream()
                .map(mapper::toPaiementDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<CommissionPaiementDTO> getAllPaiements() {
        return paiementRepository.findAll().stream()
                .map(mapper::toPaiementDTO)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<CommissionPaiementDTO> searchPaiements(String search, String status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));

        Specification<CommissionPaiement> spec = buildPaiementSpec(search, status, null);
        Page<CommissionPaiement> resultPage = paiementRepository.findAll(spec, pageable);

        List<CommissionPaiementDTO> content = resultPage.getContent().stream()
                .map(mapper::toPaiementDTO)
                .collect(Collectors.toList());

        return PageResponse.<CommissionPaiementDTO>builder()
                .content(content)
                .page(resultPage.getNumber())
                .size(resultPage.getSize())
                .totalElements(resultPage.getTotalElements())
                .totalPages(resultPage.getTotalPages())
                .first(resultPage.isFirst())
                .last(resultPage.isLast())
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<CommissionPaiementDTO> searchPaiementsByLivreur(Long livreurId, String search, String status, int page, int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));

        Specification<CommissionPaiement> spec = buildPaiementSpec(search, status, livreurId);
        Page<CommissionPaiement> resultPage = paiementRepository.findAll(spec, pageable);

        List<CommissionPaiementDTO> content = resultPage.getContent().stream()
                .map(mapper::toPaiementDTO)
                .collect(Collectors.toList());

        return PageResponse.<CommissionPaiementDTO>builder()
                .content(content)
                .page(resultPage.getNumber())
                .size(resultPage.getSize())
                .totalElements(resultPage.getTotalElements())
                .totalPages(resultPage.getTotalPages())
                .first(resultPage.isFirst())
                .last(resultPage.isLast())
                .build();
    }

    private Specification<CommissionPaiement> buildPaiementSpec(String search, String status, Long livreurId) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (livreurId != null) {
                predicates.add(cb.equal(root.get("livreur").get("id"), livreurId));
            }

            if (search != null && !search.isBlank()) {
                String pattern = "%" + search.toLowerCase() + "%";
                Join<CommissionPaiement, Utilisateur> livreurJoin = root.join("livreur", JoinType.LEFT);
                Join<CommissionPaiement, Order> orderJoin = root.join("order", JoinType.LEFT);
                Predicate nomPred = cb.like(cb.lower(livreurJoin.get("nom")), pattern);
                Predicate prenomPred = cb.like(cb.lower(livreurJoin.get("prenom")), pattern);
                Predicate orderIdPred = cb.like(cb.lower(cb.function("CAST", String.class, orderJoin.get("id"))), pattern);
                predicates.add(cb.or(nomPred, prenomPred, orderIdPred));
            }

            if (status != null && !status.isBlank()) {
                switch (status.toLowerCase()) {
                    case "paye":
                        predicates.add(cb.isTrue(root.get("livreurPaye")));
                        predicates.add(cb.isTrue(root.get("adminValide")));
                        break;
                    case "en_attente":
                        predicates.add(cb.or(
                                cb.isFalse(root.get("livreurPaye")),
                                cb.isFalse(root.get("adminValide"))
                        ));
                        break;
                }
            }

            query.distinct(true);
            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    @Override
    @Transactional
    public CommissionPaiementDTO markLivreurPaye(Long paiementId) {
        CommissionPaiement paiement = paiementRepository.findById(paiementId)
                .orElseThrow(() -> new ResourceNotFoundException("Commission paiement non trouvé avec l'id: " + paiementId));
        paiement.setLivreurPaye(true);
        paiement.setDatePaiementLivreur(LocalDateTime.now());
        paiement = paiementRepository.save(paiement);
        return mapper.toPaiementDTO(paiement);
    }

    @Override
    @Transactional
    public CommissionPaiementDTO markAdminValide(Long paiementId) {
        CommissionPaiement paiement = paiementRepository.findById(paiementId)
                .orElseThrow(() -> new ResourceNotFoundException("Commission paiement non trouvé avec l'id: " + paiementId));
        paiement.setAdminValide(true);
        paiement.setDateValidationAdmin(LocalDateTime.now());
        paiement = paiementRepository.save(paiement);
        return mapper.toPaiementDTO(paiement);
    }

    @Override
    @Transactional
    public CommissionPaiementDTO unmarkLivreurPaye(Long paiementId) {
        CommissionPaiement paiement = paiementRepository.findById(paiementId)
                .orElseThrow(() -> new ResourceNotFoundException("Commission paiement non trouvé avec l'id: " + paiementId));
        paiement.setLivreurPaye(false);
        paiement.setDatePaiementLivreur(null);
        paiement = paiementRepository.save(paiement);
        return mapper.toPaiementDTO(paiement);
    }

    @Override
    @Transactional
    public CommissionPaiementDTO unmarkAdminValide(Long paiementId) {
        CommissionPaiement paiement = paiementRepository.findById(paiementId)
                .orElseThrow(() -> new ResourceNotFoundException("Commission paiement non trouvé avec l'id: " + paiementId));
        paiement.setAdminValide(false);
        paiement.setDateValidationAdmin(null);
        paiement = paiementRepository.save(paiement);
        return mapper.toPaiementDTO(paiement);
    }

    // ═══════════════════════════════════════════════════════
    //  Summaries
    // ═══════════════════════════════════════════════════════

    @Override
    public LivreurCommissionSummaryDTO getLivreurSummary(Long livreurId) {
        Utilisateur livreur = utilisateurRepository.findById(livreurId)
                .orElseThrow(() -> new ResourceNotFoundException("Livreur non trouvé avec l'id: " + livreurId));

        String nom = ((livreur.getPrenom() != null ? livreur.getPrenom() : "") + " "
                + (livreur.getNom() != null ? livreur.getNom() : "")).trim();

        // Count orders
        List<Order> livreurOrders = orderRepository.findByLivreurId(livreurId);
        long totalCommandes = livreurOrders.size();
        long commandesLivrees = livreurOrders.stream()
                .filter(o -> "delivered".equals(o.getStatus()) || "done".equals(o.getStatus()))
                .count();

        // Commission stats
        BigDecimal totalCommission = paiementRepository.sumTotalByLivreurId(livreurId);
        BigDecimal totalPaye = paiementRepository.sumPayeByLivreurId(livreurId);
        BigDecimal totalNonPaye = paiementRepository.sumNonPayeByLivreurId(livreurId);
        Long paiementsValides = paiementRepository.countValidesByLivreurId(livreurId);
        Long paiementsEnAttente = paiementRepository.countEnAttenteByLivreurId(livreurId);

        // Active config
        CommissionConfigDTO configActuelle = getActiveConfigByLivreurId(livreurId);

        // Paiements list
        List<CommissionPaiementDTO> paiements = getPaiementsByLivreurId(livreurId);

        return LivreurCommissionSummaryDTO.builder()
                .livreurId(livreurId)
                .livreurNom(nom)
                .totalCommandes(totalCommandes)
                .commandesLivrees(commandesLivrees)
                .totalCommission(totalCommission)
                .totalPaye(totalPaye)
                .totalNonPaye(totalNonPaye)
                .paiementsValides(paiementsValides)
                .paiementsEnAttente(paiementsEnAttente)
                .configActuelle(configActuelle)
                .paiements(paiements)
                .build();
    }

    @Override
    public List<LivreurCommissionSummaryDTO> getAllLivreurSummaries() {
        List<Utilisateur> livreurs = utilisateurRepository.findByRole(Role.LIVREUR);
        List<LivreurCommissionSummaryDTO> summaries = new ArrayList<>();
        for (Utilisateur livreur : livreurs) {
            summaries.add(getLivreurSummary(livreur.getId()));
        }
        return summaries;
    }

    // ═══════════════════════════════════════════════════════
    //  Recalculate
    // ═══════════════════════════════════════════════════════

    @Override
    @Transactional
    public int recalculateAllDistances() {
        List<CommissionPaiement> allPaiements = paiementRepository.findAll();
        int updated = 0;
        for (CommissionPaiement paiement : allPaiements) {
            Order order = paiement.getOrder();
            if (order == null) continue;

            // Recalculate delivery distance
            BigDecimal distanceLivraison = calculateDeliveryDistance(order);

            // Recalculate collection distance (if config says so)
            BigDecimal distanceCollection = BigDecimal.ZERO;
            CommissionConfig config = paiement.getCommissionConfig();
            if (config != null && Boolean.TRUE.equals(config.getInclureDistanceCollection())) {
                distanceCollection = calculateCollectionDistance(order);
            }

            BigDecimal totalDistance = distanceLivraison.add(distanceCollection);

            // Recalculate total amount
            BigDecimal montantFixe = paiement.getMontantFixe() != null ? paiement.getMontantFixe() : BigDecimal.ZERO;
            BigDecimal prixParKm = paiement.getPrixParKm() != null ? paiement.getPrixParKm() : BigDecimal.ZERO;
            BigDecimal bonus = paiement.getBonus() != null ? paiement.getBonus() : BigDecimal.ZERO;

            BigDecimal montantTotal = montantFixe
                    .add(totalDistance.multiply(prixParKm))
                    .add(bonus)
                    .setScale(3, RoundingMode.HALF_UP);

            paiement.setDistanceLivraisonKm(distanceLivraison);
            paiement.setDistanceCollectionKm(distanceCollection);
            paiement.setDistanceKm(totalDistance);
            paiement.setMontantTotal(montantTotal);
            paiementRepository.save(paiement);
            updated++;
        }
        return updated;
    }

    // ═══════════════════════════════════════════════════════
    //  Utilities
    // ═══════════════════════════════════════════════════════

    /**
     * Calculate delivery distance: last collection depot (or main depot) → client delivery address.
     * Always calculated.
     */
    private BigDecimal calculateDeliveryDistance(Order order) {
        if (order.getLatitudeLivraison() == null || order.getLongitudeLivraison() == null) {
            return BigDecimal.ZERO;
        }

        // Try to get the starting point (last depot in collection plan, or main depot)
        Double startLat = null;
        Double startLng = null;

        // 1. Try collectionPlan JSON — use last depot coordinates
        if (order.getCollectionPlan() != null && !order.getCollectionPlan().isBlank()) {
            try {
                com.fasterxml.jackson.databind.ObjectMapper objectMapper = new com.fasterxml.jackson.databind.ObjectMapper();
                com.fasterxml.jackson.databind.JsonNode planNode = objectMapper.readTree(order.getCollectionPlan());
                if (planNode.isArray() && planNode.size() > 0) {
                    // Get last depot in the plan
                    com.fasterxml.jackson.databind.JsonNode lastStop = planNode.get(planNode.size() - 1);
                    if (lastStop.has("depotLatitude") && !lastStop.get("depotLatitude").isNull()
                            && lastStop.has("depotLongitude") && !lastStop.get("depotLongitude").isNull()) {
                        startLat = lastStop.get("depotLatitude").asDouble();
                        startLng = lastStop.get("depotLongitude").asDouble();
                    }
                }
            } catch (Exception ignored) {
                // Fall through
            }
        }

        // 2. Fallback to main depot
        if (startLat == null && order.getDepot() != null
                && order.getDepot().getLatitude() != null
                && order.getDepot().getLongitude() != null) {
            startLat = order.getDepot().getLatitude();
            startLng = order.getDepot().getLongitude();
        }

        if (startLat == null || startLng == null) {
            return BigDecimal.ZERO;
        }

        return osrmDistance(startLat, startLng,
                order.getLatitudeLivraison(), order.getLongitudeLivraison());
    }

    /**
     * Calculate collection distance: livreur goes to collection depot(s) to pick up products.
     * If collectionPlan JSON is present, parse depot coords and sum distances between stops.
     */
    private BigDecimal calculateCollectionDistance(Order order) {
        if (order.getCollectionPlan() != null && !order.getCollectionPlan().isBlank()) {
            try {
                com.fasterxml.jackson.databind.ObjectMapper objectMapper = new com.fasterxml.jackson.databind.ObjectMapper();
                com.fasterxml.jackson.databind.JsonNode planNode = objectMapper.readTree(order.getCollectionPlan());

                if (planNode.isArray() && planNode.size() > 0) {
                    BigDecimal totalCollDistance = BigDecimal.ZERO;
                    Double prevLat = null;
                    Double prevLng = null;

                    // If livreur has a known position, start from there
                    if (order.getLivreur() != null
                            && order.getLivreur().getLatitude() != null
                            && order.getLivreur().getLongitude() != null) {
                        prevLat = order.getLivreur().getLatitude();
                        prevLng = order.getLivreur().getLongitude();
                    } else if (order.getDepot() != null && order.getDepot().getLatitude() != null) {
                        prevLat = order.getDepot().getLatitude();
                        prevLng = order.getDepot().getLongitude();
                    }

                    for (com.fasterxml.jackson.databind.JsonNode stop : planNode) {
                        Double stopLat = stop.has("depotLatitude") && !stop.get("depotLatitude").isNull()
                                ? stop.get("depotLatitude").asDouble() : null;
                        Double stopLng = stop.has("depotLongitude") && !stop.get("depotLongitude").isNull()
                                ? stop.get("depotLongitude").asDouble() : null;

                        if (stopLat != null && stopLng != null && prevLat != null && prevLng != null) {
                            totalCollDistance = totalCollDistance.add(osrmDistance(prevLat, prevLng, stopLat, stopLng));
                        }

                        if (stopLat != null && stopLng != null) {
                            prevLat = stopLat;
                            prevLng = stopLng;
                        }
                    }
                    return totalCollDistance;
                }
            } catch (Exception ignored) {
            }
        }
        return BigDecimal.ZERO;
    }

    /**
     * Get road distance via OSRM. Falls back to haversine if OSRM is unavailable.
     * Returns distance in km, rounded to 3 decimal places.
     */
    private BigDecimal osrmDistance(double lat1, double lon1, double lat2, double lon2) {
        try {
            List<double[]> coords = List.of(
                    new double[]{lat1, lon1},
                    new double[]{lat2, lon2}
            );
            OsrmService.RouteResult result = osrmService.getRoute(coords);
            if (result != null && result.totalDistanceMeters() > 0) {
                double km = result.totalDistanceMeters() / 1000.0;
                return BigDecimal.valueOf(km).setScale(3, RoundingMode.HALF_UP);
            }
        } catch (Exception e) {
            log.warn("OSRM distance call failed, falling back to haversine: {}", e.getMessage());
        }
        // Fallback to haversine
        return haversine(lat1, lon1, lat2, lon2);
    }

    /**
     * Haversine formula (straight-line) — used only as fallback when OSRM is unavailable.
     */
    private BigDecimal haversine(double lat1Deg, double lon1Deg, double lat2Deg, double lon2Deg) {
        double lat1 = Math.toRadians(lat1Deg);
        double lon1 = Math.toRadians(lon1Deg);
        double lat2 = Math.toRadians(lat2Deg);
        double lon2 = Math.toRadians(lon2Deg);

        double dLat = lat2 - lat1;
        double dLon = lon2 - lon1;

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(lat1) * Math.cos(lat2)
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        double earthRadius = 6371.0; // km
        double distance = earthRadius * c;

        return BigDecimal.valueOf(distance).setScale(3, RoundingMode.HALF_UP);
    }

    // ═══════════════════════════════════════════════════════
    //  Bilan Financier
    // ═══════════════════════════════════════════════════════

    private static final String[] MOIS_LABELS = {
            "", "Janvier", "Février", "Mars", "Avril", "Mai", "Juin",
            "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"
    };

    @Override
    @Transactional(readOnly = true)
    public BilanDTO getBilan(Long societeId, Integer annee, Integer mois) {
        Societe societe = societeRepository.findById(societeId)
                .orElseThrow(() -> new ResourceNotFoundException("Société non trouvée"));

        BigDecimal frais = societe.getFraisLivraison() != null
                ? societe.getFraisLivraison() : BigDecimal.ZERO;

        boolean hasAnnee = annee != null && annee > 0;
        boolean validMois = mois != null && mois >= 1 && mois <= 12;

        // Totaux globaux selon le filtre
        Object[] totaux;
        String periodeLabel;
        if (hasAnnee && validMois) {
            totaux = paiementRepository.getTotauxPourMois(societeId, annee, mois).get(0);
            periodeLabel = MOIS_LABELS[mois] + " " + annee;
        } else if (hasAnnee) {
            totaux = paiementRepository.getTotauxPourAnnee(societeId, annee).get(0);
            periodeLabel = "Année " + annee;
        } else {
            totaux = paiementRepository.getTotauxAllTime(societeId).get(0);
            periodeLabel = "Toutes périodes";
        }

        long totalCommandes = ((Number) totaux[0]).longValue();
        BigDecimal totalCommissions = (BigDecimal) totaux[1];
        BigDecimal totalRevenu = frais.multiply(BigDecimal.valueOf(totalCommandes));
        BigDecimal resultatNet = totalRevenu.subtract(totalCommissions);

        // Bilan par mois
        List<BilanPeriodeDTO> bilanParMois = buildBilanParMois(societeId, annee, hasAnnee, frais);

        // Bilan par livreur
        List<BilanLivreurDTO> bilanParLivreur = buildBilanParLivreur(
                societeId, annee, mois, hasAnnee, validMois, frais);

        return BilanDTO.builder()
                .fraisLivraisonUnitaire(frais)
                .periodeLabel(periodeLabel)
                .totalCommandesLivrees(totalCommandes)
                .totalRevenu(totalRevenu)
                .totalCommissions(totalCommissions)
                .resultatNet(resultatNet)
                .rentable(resultatNet.compareTo(BigDecimal.ZERO) >= 0)
                .bilanParMois(bilanParMois)
                .bilanParLivreur(bilanParLivreur)
                .build();
    }

    @Override
    @Transactional(readOnly = true)
    public List<Integer> getAnneesDisponibles(Long societeId) {
        return paiementRepository.findAnneesDisponibles(societeId);
    }

    private List<BilanPeriodeDTO> buildBilanParMois(Long societeId, Integer annee,
                                                     boolean hasAnnee, BigDecimal frais) {
        List<Object[]> rows = hasAnnee
                ? paiementRepository.findBilanParMois(societeId, annee)
                : paiementRepository.findBilanParMoisAllTime(societeId);

        List<BilanPeriodeDTO> result = new ArrayList<>();
        for (Object[] r : rows) {
            int y = ((Number) r[0]).intValue();
            int m = ((Number) r[1]).intValue();
            long cnt = ((Number) r[2]).longValue();
            BigDecimal comm = (BigDecimal) r[3];
            BigDecimal rev = frais.multiply(BigDecimal.valueOf(cnt));
            BigDecimal res = rev.subtract(comm);

            result.add(BilanPeriodeDTO.builder()
                    .annee(y).mois(m)
                    .periodeLabel(MOIS_LABELS[m] + " " + y)
                    .commandesLivrees(cnt)
                    .revenu(rev)
                    .commissions(comm)
                    .resultat(res)
                    .rentable(res.compareTo(BigDecimal.ZERO) >= 0)
                    .build());
        }
        return result;
    }

    private List<BilanLivreurDTO> buildBilanParLivreur(Long societeId, Integer annee,
                                                        Integer mois, boolean hasAnnee,
                                                        boolean validMois, BigDecimal frais) {
        List<Object[]> rows;
        if (hasAnnee && validMois) {
            rows = paiementRepository.findBilanParLivreurPourMois(societeId, annee, mois);
        } else if (hasAnnee) {
            rows = paiementRepository.findBilanParLivreurPourAnnee(societeId, annee);
        } else {
            rows = paiementRepository.findBilanParLivreurAllTime(societeId);
        }

        List<BilanLivreurDTO> result = new ArrayList<>();
        int rang = 1;
        for (Object[] r : rows) {
            Long livreurId = ((Number) r[0]).longValue();
            String nom = (String) r[1];
            String prenom = (String) r[2];
            long cnt = ((Number) r[3]).longValue();
            BigDecimal comm = (BigDecimal) r[4];
            BigDecimal rev = frais.multiply(BigDecimal.valueOf(cnt));
            BigDecimal res = rev.subtract(comm);

            String fullName = ((prenom != null ? prenom : "") + " " + (nom != null ? nom : "")).trim();

            result.add(BilanLivreurDTO.builder()
                    .rang(rang++)
                    .livreurId(livreurId)
                    .livreurNom(fullName)
                    .commandesLivrees(cnt)
                    .revenuGenere(rev)
                    .commissionPayee(comm)
                    .resultatNet(res)
                    .rentable(res.compareTo(BigDecimal.ZERO) >= 0)
                    .build());
        }
        return result;
    }
}
