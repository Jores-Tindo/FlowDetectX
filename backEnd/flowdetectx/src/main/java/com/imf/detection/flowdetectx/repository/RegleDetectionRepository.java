package com.imf.detection.flowdetectx.repository;

import com.imf.detection.flowdetectx.model.RegleDetection;
import com.imf.detection.flowdetectx.model.enums.StatutRegleEnum;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RegleDetectionRepository extends JpaRepository<RegleDetection, Long> {

    List<RegleDetection> findByStatut(StatutRegleEnum statut);

    List<RegleDetection> findByEstReglementaireTrue();

    boolean existsByCreePar(Long creePar);
}
