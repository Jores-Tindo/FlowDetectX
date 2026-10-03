package com.imf.detection.flowdetectx.security;

import com.imf.detection.flowdetectx.model.enums.RoleEnum;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
public class JwtUtil {

    @Value("${app.jwt.secret}")
    private String secret;

    @Value("${app.jwt.expiration-ms}")
    private long expirationMs;

    private SecretKey getSigningKey() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    public String genererToken(Long id, String identifiant, RoleEnum role) {
        Date maintenant = new Date();
        Date expiration = new Date(maintenant.getTime() + expirationMs);

        return Jwts.builder()
                .subject(String.valueOf(id))
                .claim("identifiant", identifiant)
                .claim("role", role.name())
                .issuedAt(maintenant)
                .expiration(expiration)
                .signWith(getSigningKey())
                .compact();
    }

    public Claims extraireClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    public Long extraireId(String token) {
        return Long.parseLong(extraireClaims(token).getSubject());
    }

    public String extraireIdentifiant(String token) {
        return extraireClaims(token).get("identifiant", String.class);
    }

    public String extraireRole(String token) {
        return extraireClaims(token).get("role", String.class);
    }

    public boolean estValide(String token) {
        try {
            Claims claims = extraireClaims(token);
            return claims.getExpiration().after(new Date());
        } catch (Exception e) {
            return false;
        }
    }
}