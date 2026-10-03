package com.imf.detection.flowdetectx.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ClassPathResource;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${app.mail.from}")
    private String from;

    @Value("${app.frontend.base-url}")
    private String frontendBaseUrl;

    public void envoyerEmailActivation(String destinataire, String prenom, String token) {
        String lien = frontendBaseUrl + "/activation.html?token=" + token;
        String contenu = chargerTemplate("templates/email_activation.html")
                .replace("{{PRENOM}}", prenom)
                .replace("{{LIEN}}", lien);
        envoyer(destinataire, "Activation de votre compte RuleDetect-IMF", contenu);
    }

    public void envoyerEmailReinitialisation(String destinataire, String prenom, String token) {
        String lien = frontendBaseUrl + "/reinitialisation.html?token=" + token;
        String contenu = chargerTemplate("templates/email_reinitialisation.html")
                .replace("{{PRENOM}}", prenom)
                .replace("{{LIEN}}", lien);
        envoyer(destinataire, "Reinitialisation de votre mot de passe RuleDetect-IMF", contenu);
    }

    private void envoyer(String destinataire, String sujet, String contenuHtml) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, StandardCharsets.UTF_8.name());
            helper.setFrom(from);
            helper.setTo(destinataire);
            helper.setSubject(sujet);
            helper.setText(contenuHtml, true);
            mailSender.send(message);
        } catch (MessagingException e) {
            throw new IllegalStateException("Echec de l'envoi de l'email a " + destinataire, e);
        }
    }

    private String chargerTemplate(String chemin) {
        try (InputStream is = new ClassPathResource(chemin).getInputStream()) {
            return new String(is.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new IllegalStateException("Template email introuvable : " + chemin, e);
        }
    }
}