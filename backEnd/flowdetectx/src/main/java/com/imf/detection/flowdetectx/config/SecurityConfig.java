package com.imf.detection.flowdetectx.config;

import com.imf.detection.flowdetectx.security.JwtAuthFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;

    @Value("${app.cors.allowed-origins}")
    private String allowedOrigins;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(AbstractHttpConfigurer::disable)
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .sessionManagement(session ->
                    session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                    .securityContext(context -> context.requireExplicitSave(false))
            .authorizeHttpRequests(auth -> auth

                // Publics
                .requestMatchers(
                        "/api/auth/login",
                        "/api/auth/activation",
                        "/api/auth/mot-de-passe-oublie",
                        "/api/auth/reinitialisation"
                ).permitAll()

                // Pages statiques publiques (activation / reinitialisation de mot de passe)
                .requestMatchers(
                        "/activation.html",
                        "/reinitialisation.html",
                        "/css/**",
                        "/images/**"
                ).permitAll()

                // ADMINISTRATEUR
                .requestMatchers(
                        "/api/auth/creer-compte",
                        "/api/auth/renvoyer-invitation/**"
                ).hasRole("ADMINISTRATEUR")
                .requestMatchers("/api/utilisateurs/**").hasRole("ADMINISTRATEUR")
                .requestMatchers("/api/journal/**").hasRole("ADMINISTRATEUR")

                // VALIDATEUR
                .requestMatchers(
                        "/api/demandes/*/approuver",
                        "/api/demandes/*/rejeter"
                ).hasRole("VALIDATEUR")

                // UTILISATEUR_METIER
                .requestMatchers(HttpMethod.POST, "/api/regles/**")
                        .hasRole("UTILISATEUR_METIER")
                .requestMatchers(HttpMethod.POST, "/api/demandes/**")
                        .hasRole("UTILISATEUR_METIER")
                .requestMatchers("/api/simulation/**")
                        .authenticated()

                // Tous authentifies
                .requestMatchers(HttpMethod.GET, "/api/regles/**").authenticated()
                .requestMatchers(HttpMethod.GET, "/api/demandes/**").authenticated()
                .requestMatchers("/api/alertes/**").authenticated()
                .requestMatchers("/api/dashboard/**").authenticated()

                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        if ("*".equals(allowedOrigins)) {
            config.addAllowedOriginPattern("*");
        } else {
            for (String origin : allowedOrigins.split(",")) {
                config.addAllowedOrigin(origin.trim());
            }
        }
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(false);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}