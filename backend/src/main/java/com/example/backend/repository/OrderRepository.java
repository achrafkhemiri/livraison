package com.example.backend.repository;

import com.example.backend.model.Order;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {
    Optional<Order> findByNumero(String numero);
    
    // Find by ID with items, products and user
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.id = :id")
    Optional<Order> findByIdWithItems(@Param("id") Long id);
    
    // Utilise user_id (clients consommateurs) au lieu de client_id
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.user.id = :userId")
    List<Order> findByUserId(@Param("userId") Long userId);
    
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.livreur.id = :livreurId")
    List<Order> findByLivreurId(@Param("livreurId") Long livreurId);
    
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.status = :status")
    List<Order> findByStatus(@Param("status") String status);
    
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.depot.id = :depotId")
    List<Order> findByDepotId(@Param("depotId") Long depotId);
    
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.livreur.id = :livreurId AND o.status IN :statuses")
    List<Order> findByLivreurIdAndStatusIn(@Param("livreurId") Long livreurId, @Param("statuses") List<String> statuses);
    
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.dateCommande BETWEEN :start AND :end")
    List<Order> findByDateCommandeBetween(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);
    
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.status = :status AND o.depot.id = :depotId")
    List<Order> findByStatusAndDepotId(@Param("status") String status, @Param("depotId") Long depotId);
    
    // Filter by societe (orders where livreur belongs to societe)
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.livreur.societe.id = :societeId")
    List<Order> findByLivreurSocieteId(@Param("societeId") Long societeId);
    
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.depot.magasin.societe.id = :societeId")
    List<Order> findByDepotSocieteId(@Param("societeId") Long societeId);
    
    // Filter by direct societe_id on order
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.societeId = :societeId")
    List<Order> findBySocieteId(@Param("societeId") Long societeId);
    
    // Find all orders for livreur (pending orders that can be accepted)
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.status = 'pending' AND o.livreur IS NULL")
    List<Order> findPendingOrdersForLivreur();
    
    // Find all with items
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user")
    List<Order> findAllWithItems();

    // Batch load multiple orders by IDs with items
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.id IN :ids")
    List<Order> findByIdsWithItems(@Param("ids") List<Long> ids);
    
    // Find orders proposed (assigned but not yet accepted) for a livreur
    @Query("SELECT DISTINCT o FROM Order o LEFT JOIN FETCH o.items i LEFT JOIN FETCH i.produit LEFT JOIN FETCH o.user WHERE o.proposedLivreurId = :livreurId AND o.assignmentStatus = 'proposed'")
    List<Order> findProposedOrdersForLivreur(@Param("livreurId") Long livreurId);
}
