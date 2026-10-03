package com.imf.detection.flowdetectx.repository;

import com.imf.detection.flowdetectx.model.Simulation;
import com.imf.detection.flowdetectx.model.enums.StatutSimulationEnum;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SimulationRepository extends JpaRepository<Simulation, Long> {

    List<Simulation> findByUtilisateurIdOrderByDateDebutDesc(Long utilisateurId);

    Optional<Simulation> findByStatut(StatutSimulationEnum statut);

    boolean existsByStatut(StatutSimulationEnum statut);

    void deleteByUtilisateurId(Long utilisateurId);
}
