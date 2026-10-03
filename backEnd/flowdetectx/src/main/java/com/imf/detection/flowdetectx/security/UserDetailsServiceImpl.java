package com.imf.detection.flowdetectx.security;

import com.imf.detection.flowdetectx.model.Utilisateur;
import com.imf.detection.flowdetectx.model.enums.StatutCompteEnum;
import com.imf.detection.flowdetectx.repository.UtilisateurRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UtilisateurRepository utilisateurRepository;

    @Override
    public UserDetails loadUserByUsername(String identifiant)
            throws UsernameNotFoundException {

        Utilisateur utilisateur = utilisateurRepository
                .findByIdentifiant(identifiant)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "Utilisateur introuvable : " + identifiant));

        if (utilisateur.getStatut() != StatutCompteEnum.ACTIF) {
            throw new UsernameNotFoundException("Compte non actif : " + identifiant);
        }

        return new User(
                utilisateur.getIdentifiant(),
                utilisateur.getMotDePasse(),
                List.of(new SimpleGrantedAuthority(
                        "ROLE_" + utilisateur.getRole().name()))
        );
    }
}