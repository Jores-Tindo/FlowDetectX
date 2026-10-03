package com.imf.detection.flowdetectx.repository;

import com.imf.detection.flowdetectx.model.TokenActivation;
import com.imf.detection.flowdetectx.model.enums.TypeTokenEnum;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface TokenActivationRepository extends JpaRepository<TokenActivation, Long> {

    Optional<TokenActivation> findByToken(String token);

    Optional<TokenActivation> findByUtilisateurIdAndEstUtiliseFalse(Long utilisateurId);

    Optional<TokenActivation> findByTokenAndTypeTokenAndEstUtiliseFalse(String token, TypeTokenEnum typeToken);

    void deleteByUtilisateurId(Long utilisateurId);
}
