package com.example.backend.repository;

import com.example.backend.model.Stock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface StockRepository extends JpaRepository<Stock, Long> {
    
    @Query("SELECT s FROM Stock s LEFT JOIN FETCH s.produit LEFT JOIN FETCH s.depot WHERE s.depot.id = :depotId")
    List<Stock> findByDepotId(@Param("depotId") Long depotId);
    
    @Query("SELECT s FROM Stock s LEFT JOIN FETCH s.produit LEFT JOIN FETCH s.depot WHERE s.produit.id = :produitId")
    List<Stock> findByProduitId(@Param("produitId") Long produitId);
    
    @Query("SELECT s FROM Stock s LEFT JOIN FETCH s.produit LEFT JOIN FETCH s.depot WHERE s.produit.id = :produitId AND s.depot.id = :depotId")
    Optional<Stock> findByProduitIdAndDepotId(@Param("produitId") Long produitId, @Param("depotId") Long depotId);
    
    @Query("SELECT s FROM Stock s LEFT JOIN FETCH s.produit LEFT JOIN FETCH s.depot WHERE s.quantiteDisponible <= s.quantiteMinimum")
    List<Stock> findLowStock();
    
    @Query("SELECT s FROM Stock s LEFT JOIN FETCH s.produit LEFT JOIN FETCH s.depot WHERE s.depot.id = :depotId AND s.quantiteDisponible > 0")
    List<Stock> findAvailableStockByDepot(@Param("depotId") Long depotId);
    
    // Filter by societe
    @Query("SELECT s FROM Stock s LEFT JOIN FETCH s.produit LEFT JOIN FETCH s.depot d LEFT JOIN FETCH d.magasin m WHERE m.societe.id = :societeId")
    List<Stock> findBySocieteId(@Param("societeId") Long societeId);
    
    @Query("SELECT s FROM Stock s LEFT JOIN FETCH s.produit LEFT JOIN FETCH s.depot d LEFT JOIN FETCH d.magasin m WHERE m.societe.id = :societeId AND s.quantiteDisponible <= s.quantiteMinimum")
    List<Stock> findLowStockBySocieteId(@Param("societeId") Long societeId);
    
    @Query("SELECT s FROM Stock s LEFT JOIN FETCH s.produit LEFT JOIN FETCH s.depot")
    List<Stock> findAllWithProducts();
    
    // Find stocks by societe where quantity > 0
    @Query("SELECT s FROM Stock s LEFT JOIN FETCH s.produit p LEFT JOIN FETCH s.depot d LEFT JOIN FETCH d.magasin m WHERE m.societe.id = :societeId AND (s.quantiteDisponible > 0 OR s.quantity > 0)")
    List<Stock> findAvailableStockBySocieteId(@Param("societeId") Long societeId);
    
    // Find stocks for a specific product across all depots of a societe
    @Query("SELECT s FROM Stock s LEFT JOIN FETCH s.produit p LEFT JOIN FETCH s.depot d LEFT JOIN FETCH d.magasin m WHERE p.id = :produitId AND m.societe.id = :societeId AND (s.quantiteDisponible > 0 OR s.quantity > 0)")
    List<Stock> findByProduitIdAndSocieteId(@Param("produitId") Long produitId, @Param("societeId") Long societeId);
}
