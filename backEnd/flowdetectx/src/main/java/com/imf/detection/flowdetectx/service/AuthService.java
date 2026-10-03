package com.imf.detection.flowdetectx.service;

import com.imf.detection.flowdetectx.dto.request.ActivationCompteRequest;
import com.imf.detection.flowdetectx.dto.request.ChangementMotDePasseRequest;
import com.imf.detection.flowdetectx.dto.request.CreationCompteRequest;
import com.imf.detection.flowdetectx.dto.request.LoginRequest;
import com.imf.detection.flowdetectx.dto.request.ModificationProfilRequest;
import com.imf.detection.flowdetectx.dto.request.MotDePasseOublieRequest;
import com.imf.detection.flowdetectx.dto.request.ReinitialisationMotDePasseRequest;
import com.imf.detection.flowdetectx.dto.response.AuthResponse;
import com.imf.detection.flowdetectx.dto.response.UtilisateurResponse;
import com.imf.detection.flowdetectx.exception.AuthentificationException;
import com.imf.detection.flowdetectx.exception.CompteException;
import com.imf.detection.flowdetectx.exception.ConflitDonneesException;
import com.imf.detection.flowdetectx.exception.RessourceNotFoundException;
import com.imf.detection.flowdetectx.exception.TokenInvalideException;
import com.imf.detection.flowdetectx.model.TokenActivation;
import com.imf.detection.flowdetectx.model.Utilisateur;
import com.imf.detection.flowdetectx.model.enums.StatutCompteEnum;
import com.imf.detection.flowdetectx.model.enums.TypeTokenEnum;
import com.imf.detection.flowdetectx.repository.TokenActivationRepository;
import com.imf.detection.flowdetectx.repository.UtilisateurRepository;
import com.imf.detection.flowdetectx.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UtilisateurRepository utilisateurRepository;
    private final TokenActivationRepository tokenActivationRepository;
    private final PasswordEncoder passwordEncoder;
    private final EmailService emailService;
    private final JwtUtil jwtUtil;

    @Value("${app.token.activation-validity-hours}")
    private long activationValidityHours;

    @Value("${app.token.reinitialisation-validity-hours}")
    private long reinitialisationValidityHours;

    @Transactional
    public UtilisateurResponse creerCompte(CreationCompteRequest dto, Long adminId) {
        if (utilisateurRepository.existsByEmail(dto.getEmail())) {
            throw new ConflitDonneesException("Un compte existe deja avec cet email.");
        }

        Utilisateur utilisateur = Utilisateur.builder()
                .nom(dto.getNom())
                .prenom(dto.getPrenom())
                .email(dto.getEmail())
                .role(dto.getRole())
                .statut(StatutCompteEnum.INACTIF)
                .creePar(adminId)
                .build();
        utilisateur = utilisateurRepository.save(utilisateur);

        genererEtEnvoyerTokenActivation(utilisateur);

        return UtilisateurResponse.fromEntity(utilisateur);
    }

    @Transactional
    public void renvoyerInvitation(Long utilisateurId) {
        Utilisateur utilisateur = utilisateurRepository.findById(utilisateurId)
                .orElseThrow(() -> new RessourceNotFoundException("Utilisateur introuvable."));

        if (utilisateur.getStatut() != StatutCompteEnum.INACTIF) {
            throw new CompteException("Ce compte est deja active.");
        }

        invaliderTokenNonUtilise(utilisateurId);
        genererEtEnvoyerTokenActivation(utilisateur);
    }

    private void genererEtEnvoyerTokenActivation(Utilisateur utilisateur) {
    TokenActivation token = TokenActivation.builder()
            .token(UUID.randomUUID().toString())
            .typeToken(TypeTokenEnum.ACTIVATION)
            .dateExpiration(LocalDateTime.now().plusHours(activationValidityHours))
            .estUtilise(false)
            .utilisateurId(utilisateur.getId())
            .build();
    tokenActivationRepository.save(token);

    try {
        emailService.envoyerEmailActivation(
                utilisateur.getEmail(), utilisateur.getPrenom(), token.getToken());
    } catch (Exception e) {
        log.warn("[AuthService] Email non envoye pour {} : {}",
                utilisateur.getEmail(), e.getMessage());
                log.warn("[AuthService] Cause : {}", e.getCause() != null ? e.getCause().getMessage() : "inconnue");
    }
}

    @Transactional
    public AuthResponse activerCompte(ActivationCompteRequest dto) {
        if (!dto.getMotDePasse().equals(dto.getConfirmationMotDePasse())) {
            throw new CompteException("Les mots de passe ne correspondent pas.");
        }

        TokenActivation token = tokenActivationRepository
                .findByTokenAndTypeTokenAndEstUtiliseFalse(dto.getToken(), TypeTokenEnum.ACTIVATION)
                .orElseThrow(() -> new TokenInvalideException("Lien d'activation invalide ou deja utilise."));

        if (token.estExpire()) {
            throw new TokenInvalideException("Lien d'activation expire. Demandez un nouvel envoi.");
        }

        if (utilisateurRepository.existsByIdentifiant(dto.getIdentifiant())) {
            throw new ConflitDonneesException("Cet identifiant est deja utilise.");
        }

        Utilisateur utilisateur = utilisateurRepository.findById(token.getUtilisateurId())
                .orElseThrow(() -> new RessourceNotFoundException("Utilisateur introuvable."));

        utilisateur.setIdentifiant(dto.getIdentifiant());
        utilisateur.setMotDePasse(passwordEncoder.encode(dto.getMotDePasse()));
        utilisateur.setStatut(StatutCompteEnum.ACTIF);
        utilisateurRepository.save(utilisateur);

        token.setEstUtilise(true);
        tokenActivationRepository.save(token);

        String jwt = jwtUtil.genererToken(utilisateur.getId(), utilisateur.getIdentifiant(), utilisateur.getRole());
        return construireAuthResponse(utilisateur, jwt);
    }

    public AuthResponse login(LoginRequest dto) {
        Utilisateur utilisateur = utilisateurRepository.findByIdentifiant(dto.getIdentifiant())
                .orElseThrow(() -> new AuthentificationException("Identifiant ou mot de passe incorrect."));

        if (utilisateur.getStatut() == StatutCompteEnum.INACTIF) {
            throw new CompteException("Ce compte n'a pas encore ete active.");
        }
        if (utilisateur.getStatut() == StatutCompteEnum.SUSPENDU) {
            throw new CompteException("Ce compte a ete suspendu.");
        }

        if (!passwordEncoder.matches(dto.getMotDePasse(), utilisateur.getMotDePasse())) {
            throw new AuthentificationException("Identifiant ou mot de passe incorrect.");
        }

        String jwt = jwtUtil.genererToken(utilisateur.getId(), utilisateur.getIdentifiant(), utilisateur.getRole());
        return construireAuthResponse(utilisateur, jwt);
    }

    @Transactional
    public void demanderReinitialisation(MotDePasseOublieRequest dto) {
        utilisateurRepository.findByEmail(dto.getEmail())
                .filter(u -> u.getStatut() == StatutCompteEnum.ACTIF)
                .ifPresent(utilisateur -> {
                    invaliderTokenNonUtilise(utilisateur.getId());

                    TokenActivation token = TokenActivation.builder()
                            .token(UUID.randomUUID().toString())
                            .typeToken(TypeTokenEnum.REINITIALISATION)
                            .dateExpiration(LocalDateTime.now().plusHours(reinitialisationValidityHours))
                            .estUtilise(false)
                            .utilisateurId(utilisateur.getId())
                            .build();
                    tokenActivationRepository.save(token);

                    emailService.envoyerEmailReinitialisation(
                            utilisateur.getEmail(), utilisateur.getPrenom(), token.getToken());
                });
    }

    @Transactional
    public void reinitialiserMotDePasse(ReinitialisationMotDePasseRequest dto) {
        if (!dto.getNouveauMotDePasse().equals(dto.getConfirmationMotDePasse())) {
            throw new CompteException("Les mots de passe ne correspondent pas.");
        }

        TokenActivation token = tokenActivationRepository
                .findByTokenAndTypeTokenAndEstUtiliseFalse(dto.getToken(), TypeTokenEnum.REINITIALISATION)
                .orElseThrow(() -> new TokenInvalideException("Lien de reinitialisation invalide ou deja utilise."));

        if (token.estExpire()) {
            throw new TokenInvalideException("Lien de reinitialisation expire. Refaites une demande.");
        }

        Utilisateur utilisateur = utilisateurRepository.findById(token.getUtilisateurId())
                .orElseThrow(() -> new RessourceNotFoundException("Utilisateur introuvable."));

        utilisateur.setMotDePasse(passwordEncoder.encode(dto.getNouveauMotDePasse()));
        utilisateurRepository.save(utilisateur);

        token.setEstUtilise(true);
        tokenActivationRepository.save(token);
    }

    private void invaliderTokenNonUtilise(Long utilisateurId) {
        tokenActivationRepository.findByUtilisateurIdAndEstUtiliseFalse(utilisateurId)
                .ifPresent(ancien -> {
                    ancien.setEstUtilise(true);
                    tokenActivationRepository.save(ancien);
                });
    }

    private AuthResponse construireAuthResponse(Utilisateur utilisateur, String jwt) {
        return AuthResponse.builder()
                .token(jwt)
                .id(utilisateur.getId())
                .nom(utilisateur.getNom())
                .prenom(utilisateur.getPrenom())
                .identifiant(utilisateur.getIdentifiant())
                .email(utilisateur.getEmail())
                .role(utilisateur.getRole())
                .build();
    }

    @Transactional
public UtilisateurResponse modifierProfil(Long utilisateurId, ModificationProfilRequest dto) {
    Utilisateur utilisateur = utilisateurRepository.findById(utilisateurId)
            .orElseThrow(() -> new RessourceNotFoundException("Utilisateur introuvable."));

    if (!utilisateur.getEmail().equals(dto.getEmail())
            && utilisateurRepository.existsByEmail(dto.getEmail())) {
        throw new ConflitDonneesException("Cet email est deja utilise par un autre compte.");
    }

    utilisateur.setNom(dto.getNom());
    utilisateur.setPrenom(dto.getPrenom());
    utilisateur.setEmail(dto.getEmail());
    utilisateurRepository.save(utilisateur);

    return UtilisateurResponse.fromEntity(utilisateur);
}

@Transactional
public void changerMotDePasse(Long utilisateurId, ChangementMotDePasseRequest dto) {
    if (!dto.getNouveauMotDePasse().equals(dto.getConfirmationMotDePasse())) {
        throw new CompteException("Les mots de passe ne correspondent pas.");
    }

    Utilisateur utilisateur = utilisateurRepository.findById(utilisateurId)
            .orElseThrow(() -> new RessourceNotFoundException("Utilisateur introuvable."));

    if (!passwordEncoder.matches(dto.getAncienMotDePasse(), utilisateur.getMotDePasse())) {
        throw new AuthentificationException("Mot de passe actuel incorrect.");
    }

    utilisateur.setMotDePasse(passwordEncoder.encode(dto.getNouveauMotDePasse()));
    utilisateurRepository.save(utilisateur);
}
}