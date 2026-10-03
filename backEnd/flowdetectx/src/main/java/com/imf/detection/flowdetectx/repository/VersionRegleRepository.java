package com.imf.detection.flowdetectx.repository;

import com.imf.detection.flowdetectx.model.VersionRegle;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.Query;

public interface VersionRegleRepository extends JpaRepository<VersionRegle, Long> {

    Optional<VersionRegle> findByRegleIdAndEstActiveTrue(Long regleId);

    List<VersionRegle> findByRegleIdOrderByNumeroVersionDesc(Long regleId);

    /** Toutes les versions actuellement actives, utilisees pour charger le moteur Drools. */
    List<VersionRegle> findByEstActiveTrue();

    @Query("SELECT v FROM VersionRegle v WHERE v.estActive = true AND v.regle.statut = com.imf.detection.flowdetectx.model.enums.StatutRegleEnum.ACTIVE")
List<VersionRegle> findByEstActiveTrueEtRegleActive();
}
