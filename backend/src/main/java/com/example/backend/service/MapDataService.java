package com.example.backend.service;

import com.example.backend.dto.MapDataDTO;
import com.example.backend.dto.ProductStockInfoDTO;

import java.util.List;
import java.util.Map;

public interface MapDataService {
    MapDataDTO getMapData(Long societeId);
    List<ProductStockInfoDTO> getProductsWithStockBySociete(Long societeId);
    Map<String, Object> generateCollectionPlan(Long orderId, Long societeId);
    Map<String, Object> generateOptimalCollectionPlan(List<Long> orderIds, Long societeId, Double livreurLat, Double livreurLon);
}
