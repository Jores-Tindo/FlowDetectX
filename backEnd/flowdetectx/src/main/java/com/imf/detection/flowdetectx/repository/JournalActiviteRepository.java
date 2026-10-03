package com.imf.detection.flowdetectx.repository;

import com.imf.detection.flowdetectx.model.JournalActivite;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface JournalActiviteRepository extends JpaRepository<JournalActivite, Long> {

    List<JournalActivite> findByUtilisateurIdOrderByHorodatageDesc(Long utilisateurId);

    void deleteByUtilisateurId(Long utilisateurId);

    List<JournalActivite> findAllByOrderByHorodatageDesc();
}
