package com.imf.detection.flowdetectx.repository;

import com.imf.detection.flowdetectx.model.DemandeValidation;
import com.imf.detection.flowdetectx.model.enums.StatutDemandeEnum;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface DemandeValidationRepository extends JpaRepository<DemandeValidation, Long> {

    List<DemandeValidation> findByStatut(StatutDemandeEnum statut);

    List<DemandeValidation> findBySoumisePar(Long utilisateurId);

    List<DemandeValidation> findBySoumiseParOrderByDateCreationDesc(Long utilisateurId);

    void deleteBySoumisePar(Long utilisateurId);

    void deleteByTraiteePar(Long utilisateurId);
}
