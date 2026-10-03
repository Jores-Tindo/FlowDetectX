package com.imf.detection.flowdetectx.service;

import com.imf.detection.flowdetectx.repository.VersionRegleRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.kie.api.KieServices;
import org.kie.api.builder.KieBuilder;
import org.kie.api.builder.KieFileSystem;
import org.kie.api.builder.Message;
import org.kie.api.builder.model.KieBaseModel;
import org.kie.api.builder.model.KieModuleModel;
import org.kie.api.conf.EventProcessingOption;
import org.kie.api.runtime.KieContainer;
import org.kie.api.runtime.KieSession;
import org.springframework.stereotype.Service;

import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class MoteurDroolsService {

    private final VersionRegleRepository versionRegleRepository;

    private volatile KieContainer kieContainer;

    @PostConstruct
    public void initialiserMoteur() {
        log.info("[MoteurDrools] Initialisation depuis la base de donnees...");
        rechargerMoteur();
    }

    public synchronized void rechargerMoteur() {
        List<String> contenus = chargerContenusActifs();

        if (contenus.isEmpty()) {
            log.warn("[MoteurDrools] Aucune regle active en base — moteur non charge.");
            this.kieContainer = null;
            return;
        }

        try {
            KieServices ks = KieServices.Factory.get();
            KieFileSystem kfs = ks.newKieFileSystem();

            for (int i = 0; i < contenus.size(); i++) {
                kfs.write("src/main/resources/rules/regle_" + i + ".drl", contenus.get(i));
            }

            KieModuleModel kmm = ks.newKieModuleModel();
            KieBaseModel kbm = kmm.newKieBaseModel("ruledetectKBase")
                    .setDefault(true)
                    .setEventProcessingMode(EventProcessingOption.STREAM);
            kbm.newKieSessionModel("ruledetectKSession").setDefault(true);
            kfs.writeKModuleXML(kmm.toXML());

            KieBuilder kb = ks.newKieBuilder(kfs);
            kb.buildAll();

            if (kb.getResults().hasMessages(Message.Level.ERROR)) {
                log.error("[MoteurDrools] Erreurs de compilation : {}", kb.getResults().getMessages());
                return;
            }

            this.kieContainer = ks.newKieContainer(kb.getKieModule().getReleaseId());
            log.info("[MoteurDrools] Moteur recharge avec {} regle(s) active(s).", contenus.size());

        } catch (Exception e) {
            log.error("[MoteurDrools] Echec du rechargement : {}", e.getMessage(), e);
        }
    }

    public boolean estPret() {
        return this.kieContainer != null;
    }

    public KieSession ouvrirSession() {
        if (this.kieContainer == null)
            throw new IllegalStateException(
                    "Le moteur Drools n'est pas initialise : aucune regle active en base.");
        return this.kieContainer.newKieSession();
    }

    /**
     * En-tete commun requis par chaque regle DRL pour compiler : package,
     * imports des entites utilisees dans les regles, et declaration de
     * Transaction comme evenement (necessaire aux fenetres temporelles
     * type "over window:time(24h)" utilisees par certaines regles).
     *
     * Le champ contenuDrl stocke en base ne contient QUE le bloc
     * "rule ... when ... then ... end" (voir V2__seed_regles_defaut.sql) ;
     * cet en-tete doit donc etre prefixe avant compilation.
     */
    private static final String ENTETE_DRL = """
            package com.imf.detection.flowdetectx.rules;

            import com.imf.detection.flowdetectx.model.Transaction;
            import com.imf.detection.flowdetectx.model.Alerte;
            import com.imf.detection.flowdetectx.model.ProfilClient;
            import com.imf.detection.flowdetectx.model.enums.CriticiteEnum;
            import java.time.LocalDateTime;
            import java.time.temporal.ChronoUnit;

            declare Transaction
                @role(event)
                @timestamp(dateEnregistrement)
            end

            """;

    private List<String> chargerContenusActifs() {
List<String> versionsActives = versionRegleRepository.findByEstActiveTrueEtRegleActive()
                .stream()
                .map(v -> ENTETE_DRL + v.getContenuDrl())
                .toList();

        log.info("[MoteurDrools] {} version(s) de regle active(s) chargee(s) depuis la base.",
                versionsActives.size());
        return versionsActives;
    }
}