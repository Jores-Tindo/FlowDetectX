package com.imf.detection.flowdetectx.config;

import org.kie.api.KieServices;
import org.kie.api.builder.KieBuilder;
import org.kie.api.builder.KieFileSystem;
import org.kie.api.builder.Message;
import org.kie.api.builder.model.KieModuleModel;
import org.kie.api.builder.model.KieBaseModel;
import org.kie.api.builder.model.KieSessionModel;
import org.kie.api.conf.EventProcessingOption;
import org.kie.api.runtime.KieContainer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

/**
 * Configuration du moteur Drools 10.1.0 (PHREAK).
 *
 * Charge au demarrage l'ensemble des fichiers .drl presents dans
 * classpath:rules/ et construit un KieContainer unique, partage par
 * le MoteurDroolsService.
 *
 * Le mode EventProcessingOption.STREAM est active car le systeme
 * traite un flux continu de transactions (simulation temps reel
 * PaySim) et utilise des fenetres temporelles (window:time) dans
 * plusieurs regles (R001, R003, R004).
 */
@Configuration
public class DroolsConfig {

    @Value("${app.drools.rules-path:classpath:rules/}")
    private String rulesPath;

    private final ResourcePatternResolver resourceResolver = new PathMatchingResourcePatternResolver();

    @Bean
    public KieContainer kieContainer() throws IOException {
        KieServices kieServices = KieServices.Factory.get();
        KieFileSystem kieFileSystem = kieServices.newKieFileSystem();

        Resource[] resources = resourceResolver.getResources(rulesPath + "*.drl");
        for (Resource resource : resources) {
            String content = readResource(resource);
            String path = "src/main/resources/rules/" + resource.getFilename();
            kieFileSystem.write(path, content);
        }

        KieModuleModel kieModuleModel = kieServices.newKieModuleModel();
        KieBaseModel kieBaseModel = kieModuleModel.newKieBaseModel("ruledetectKBase")
                .setDefault(true)
                .setEventProcessingMode(EventProcessingOption.STREAM);

        KieSessionModel kieSessionModel = kieBaseModel.newKieSessionModel("ruledetectKSession")
                .setDefault(true);

        kieFileSystem.writeKModuleXML(kieModuleModel.toXML());

        KieBuilder kieBuilder = kieServices.newKieBuilder(kieFileSystem);
        kieBuilder.buildAll();

        if (kieBuilder.getResults().hasMessages(Message.Level.ERROR)) {
            throw new IllegalStateException(
                "Erreur de compilation des regles Drools : " + kieBuilder.getResults().getMessages());
        }

        return kieServices.newKieContainer(kieBuilder.getKieModule().getReleaseId());
    }

    private String readResource(Resource resource) throws IOException {
        try (InputStream is = resource.getInputStream()) {
            return new String(is.readAllBytes(), StandardCharsets.UTF_8);
        }
    }
}