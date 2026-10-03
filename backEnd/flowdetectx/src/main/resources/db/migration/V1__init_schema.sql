-- ====================================================================
-- RuleDetect-IMF - V1 : Creation du schema initial (MySQL 8)
-- ====================================================================

CREATE TABLE utilisateurs (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    nom             VARCHAR(100) NOT NULL,
    prenom          VARCHAR(100) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    identifiant     VARCHAR(50) UNIQUE,
    mot_de_passe    VARCHAR(255),
    role            VARCHAR(30) NOT NULL,
    statut          VARCHAR(20) NOT NULL DEFAULT 'INACTIF',
    cree_par        BIGINT NULL,
    date_creation   DATETIME NOT NULL,
    CONSTRAINT fk_utilisateur_cree_par FOREIGN KEY (cree_par) REFERENCES utilisateurs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE tokens_activation (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    token           VARCHAR(100) NOT NULL UNIQUE,
    type_token      VARCHAR(30) NOT NULL,
    date_expiration DATETIME NOT NULL,
    est_utilise     BOOLEAN NOT NULL DEFAULT FALSE,
    utilisateur_id  BIGINT NOT NULL,
    CONSTRAINT fk_token_utilisateur FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE regles_detection (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    nom                 VARCHAR(200) NOT NULL,
    description         TEXT NOT NULL,
    criticite           VARCHAR(20) NOT NULL,
    statut              VARCHAR(20) NOT NULL,
    est_reglementaire   BOOLEAN NOT NULL DEFAULT FALSE,
    cree_par            BIGINT NOT NULL,
    date_creation       DATETIME NOT NULL,
    CONSTRAINT fk_regle_cree_par FOREIGN KEY (cree_par) REFERENCES utilisateurs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE versions_regle (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    regle_id        BIGINT NOT NULL,
    numero_version  INT NOT NULL,
    conditions      TEXT NOT NULL,
    contenu_drl     LONGTEXT,
    est_active      BOOLEAN NOT NULL DEFAULT FALSE,
    statut          VARCHAR(20) NOT NULL,
    date_creation   DATETIME NOT NULL,
    CONSTRAINT fk_version_regle FOREIGN KEY (regle_id) REFERENCES regles_detection(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE demandes_validation (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    type                VARCHAR(20) NOT NULL,
    regle_id            BIGINT NULL,
    nom_regle_historique VARCHAR(255) NOT NULL,
    version_regle_id    BIGINT NULL,
    statut              VARCHAR(20) NOT NULL DEFAULT 'EN_ATTENTE',
    motif_rejet         TEXT,
    soumise_par         BIGINT NOT NULL,
    traitee_par         BIGINT NULL,
    date_creation       DATETIME NOT NULL,
    date_traitement     DATETIME NULL,
    CONSTRAINT fk_demande_regle FOREIGN KEY (regle_id) REFERENCES regles_detection(id), ON DELETE SET NULL,
    CONSTRAINT fk_demande_version FOREIGN KEY (version_regle_id) REFERENCES versions_regle(id), ON DELETE SET NULL,
    CONSTRAINT fk_demande_soumise_par FOREIGN KEY (soumise_par) REFERENCES utilisateurs(id),
    CONSTRAINT fk_demande_traitee_par FOREIGN KEY (traitee_par) REFERENCES utilisateurs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE simulations (
    id                          BIGINT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id              BIGINT NOT NULL,
    date_debut                  DATETIME NOT NULL,
    date_fin                    DATETIME NULL,
    nb_transactions_traitees    BIGINT NOT NULL DEFAULT 0,
    nb_alertes                  BIGINT NOT NULL DEFAULT 0,
    vrais_positifs              BIGINT NOT NULL DEFAULT 0,
    faux_positifs               BIGINT NOT NULL DEFAULT 0,
    faux_negatifs               BIGINT NOT NULL DEFAULT 0,
    precision_score             DOUBLE NULL,
    rappel_score                DOUBLE NULL,
    f1_score                    DOUBLE NULL,
    statut                      VARCHAR(20) NOT NULL DEFAULT 'EN_COURS',
    CONSTRAINT fk_simulation_utilisateur FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Seules les transactions ayant declenche au moins une alerte sont persistees
CREATE TABLE transactions (
    id                  BIGINT AUTO_INCREMENT PRIMARY KEY,
    simulation_id       BIGINT NOT NULL,
    step                INT NOT NULL,
    type                VARCHAR(20) NOT NULL,
    montant             DOUBLE NOT NULL,
    nom_client          VARCHAR(50) NOT NULL,
    solde_avant_client  DOUBLE NOT NULL,
    solde_apres_client  DOUBLE NOT NULL,
    nom_destinataire    VARCHAR(50),
    solde_avant_dest    DOUBLE NULL,
    solde_apres_dest    DOUBLE NULL,
    est_fraude          BOOLEAN NOT NULL DEFAULT FALSE,
    date_enregistrement DATETIME NOT NULL,
    CONSTRAINT fk_transaction_simulation FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE alertes (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    simulation_id   BIGINT NOT NULL,
    transaction_id  BIGINT NOT NULL,
    regle_nom       VARCHAR(200) NOT NULL,
    criticite       VARCHAR(20) NOT NULL,
    description     TEXT NOT NULL,
    horodatage      DATETIME NOT NULL,
    CONSTRAINT fk_alerte_simulation FOREIGN KEY (simulation_id) REFERENCES simulations(id) ON DELETE CASCADE,
    CONSTRAINT fk_alerte_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE journal_activite (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id  BIGINT NOT NULL,
    action          VARCHAR(100) NOT NULL,
    details         TEXT,
    horodatage      DATETIME NOT NULL,
    CONSTRAINT fk_journal_utilisateur FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ==================== INDEX ====================
CREATE INDEX idx_versions_regle_id ON versions_regle(regle_id);
CREATE INDEX idx_demandes_statut ON demandes_validation(statut);
CREATE INDEX idx_alertes_simulation ON alertes(simulation_id);
CREATE INDEX idx_alertes_criticite ON alertes(criticite);
CREATE INDEX idx_journal_utilisateur ON journal_activite(utilisateur_id);
CREATE INDEX idx_simulations_utilisateur ON simulations(utilisateur_id);
