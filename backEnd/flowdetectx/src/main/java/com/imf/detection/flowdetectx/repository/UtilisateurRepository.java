package com.imf.detection.flowdetectx.repository;

import com.imf.detection.flowdetectx.model.Utilisateur;
import com.imf.detection.flowdetectx.model.enums.RoleEnum;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UtilisateurRepository extends JpaRepository<Utilisateur, Long> {

    Optional<Utilisateur> findByEmail(String email);

    Optional<Utilisateur> findByIdentifiant(String identifiant);

    boolean existsByEmail(String email);

    boolean existsByIdentifiant(String identifiant);

    boolean existsByCreePar(Long creePar);

    List<Utilisateur> findByRole(RoleEnum role);
}
