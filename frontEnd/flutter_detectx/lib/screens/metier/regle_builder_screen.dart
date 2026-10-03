import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

Map<String, dynamic> construirePayloadPourSoumission({
  required String nom,
  required String description,
  required String criticite,
  required String contenuDrl,
  required List<String> conditions,
}) {
  final conditionsValides =
      conditions.where((c) => c.trim().isNotEmpty).toList();
  return {
    'nom': nom.trim(),
    'description': description.trim(),
    'criticite': criticite.trim(),
    'contenuDrl': contenuDrl.trim(),
    'conditions': conditionsValides.join('; '),
  };
}

// ─── Modèles ──────────────────────────────────────────────────────────────────

enum TypeCondition {
  montantSuperieur,
  montantInferieur,
  montantRond,
  typeTransaction,
  heureEntre,
  nombreTransactions,
  soldeNegatif,
  beneficiaireInconnu,
  soldeAvantSuperieur,
  soldeAvantInferieur,
  ratioSoldeApres,
  ratioMontantSoldeAvant,
}

class ConditionRegle {
  TypeCondition type;
  Map<String, dynamic> params;

  ConditionRegle({required this.type, Map<String, dynamic>? params})
      : params = params ?? {};
}

// ─── Écran principal ──────────────────────────────────────────────────────────

class RegleBuilderScreen extends StatefulWidget {
  final Map<String, dynamic>? regleExistante;
  final Future<void> Function(Map<String, dynamic> data) onSoumettre;

  const RegleBuilderScreen({
    super.key,
    this.regleExistante,
    required this.onSoumettre,
  });

  @override
  State<RegleBuilderScreen> createState() => _RegleBuilderScreenState();
}

class _RegleBuilderScreenState extends State<RegleBuilderScreen> {
  final _nomCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _criticite = 'MOYEN';
  final List<ConditionRegle> _conditions = [];
  String _operateurLogique = 'ET'; // ET | OU
  bool _envoiEnCours = false;

  @override
  void initState() {
    super.initState();
    if (widget.regleExistante != null) {
      _nomCtrl.text = widget.regleExistante!['nom'] ?? '';
      _descCtrl.text = widget.regleExistante!['description'] ?? '';
      _criticite = widget.regleExistante!['criticite'] ?? 'MOYEN';
      _preremplirConditions(widget.regleExistante!['conditions']);
    }
    _nomCtrl.addListener(() => setState(() {}));
    _descCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─── Génération DRL ─────────────────────────────────────────────────────

  String get _drlGenere {
    final nom =
        _nomCtrl.text.trim().isEmpty ? 'Ma règle' : _nomCtrl.text.trim();
    final desc = _descCtrl.text.trim().isEmpty ? nom : _descCtrl.text.trim();

    if (_conditions.isEmpty) {
      return 'rule "$nom"\n'
          '  salience 50\n'
          'when\n'
          '    \$t : Transaction(\n'
          '      // Ajoutez des conditions ci-dessous\n'
          '    )\n'
          'then\n'
          '    Alerte alerte = new Alerte();\n'
          '    alerte.setRegleNom("$nom");\n'
          '    alerte.setCriticite(CriticiteEnum.$_criticite);\n'
          '    alerte.setDescription("$desc");\n'
          '    insertLogical(alerte);\n'
          'end';
    }

    final condLines = <String>[];
    for (final c in _conditions) {
      final line = _conditionEnDRL(c);
      if (line.isNotEmpty) condLines.add(line);
    }

    final sep = _operateurLogique == 'ET' ? ',\n      ' : '\n      || ';
    final condStr = condLines.join(sep);

    return 'rule "$nom"\n'
        '  salience 50\n'
        'when\n'
        '    \$t : Transaction(\n'
        '      $condStr\n'
        '    )\n'
        'then\n'
        '    Alerte alerte = new Alerte();\n'
        '    alerte.setRegleNom("$nom");\n'
        '    alerte.setCriticite(CriticiteEnum.$_criticite);\n'
        '    alerte.setDescription("$desc");\n'
        '    insertLogical(alerte);\n'
        'end';
  }

  String _conditionEnDRL(ConditionRegle c) {
    switch (c.type) {
      case TypeCondition.montantSuperieur:
        final val = c.params['montant'] ?? '0';
        return 'montant > $val';

      case TypeCondition.montantInferieur:
        final val = c.params['montant'] ?? '0';
        return 'montant < $val';

      case TypeCondition.montantRond:
        final div = c.params['diviseur'] ?? '100000';
        return 'montant % $div == 0';

      case TypeCondition.typeTransaction:
        // Supporte la sélection multiple : plusieurs types -> une SEULE
        // condition atomique avec OU interne, ex. (type == "A" || type == "B").
        // Combinée ensuite en ET avec les autres conditions de la règle,
        // indépendamment de l'opérateur ET/OU global.
        final types = (c.params['types'] as List?)?.cast<String>() ??
            [c.params['type']?.toString() ?? 'TRANSFER'];
        if (types.isEmpty) return 'type == "TRANSFER"';
        if (types.length == 1) return 'type == "${types.first}"';
        return '(${types.map((t) => 'type == "$t"').join(' || ')})';

      case TypeCondition.heureEntre:
        final debut = c.params['heureDebut'] ?? '22';
        final fin = c.params['heureFin'] ?? '5';
        return 'heure >= $debut || heure <= $fin';

      case TypeCondition.nombreTransactions:
        final nb = c.params['nombre'] ?? '5';
        final sec = c.params['secondes'] ?? '60';
        return '// Accumulation : > $nb transactions en $sec secondes\n'
            '    // (voir règle accumulate dans le DRL avancé)';

      case TypeCondition.soldeNegatif:
        // CORRIGÉ : le champ Transaction s'appelle soldeApresClient
        // (et non soldeApres, qui n'existe pas sur l'entité).
        return 'soldeApresClient < 0';

      case TypeCondition.beneficiaireInconnu:
        // CORRIGÉ : le champ s'appelle nomDestinataire (et non nomDest).
        // ATTENTION : la fonction historiqueContient(...) doit exister
        // comme fonction globale Drools (via une balise <function> dans
        // un des .drl, ou un global enregistré côté MoteurDroolsService).
        // Si elle n'existe pas encore, cette condition ne compilera pas —
        // retire-la du builder tant qu'elle n'est pas définie côté back.
        return '!historiqueContient(nomDestinataire)';

      case TypeCondition.soldeAvantSuperieur:
        final val = c.params['montant'] ?? '0';
        return 'soldeAvantClient > $val';

      case TypeCondition.soldeAvantInferieur:
        final val = c.params['montant'] ?? '0';
        return 'soldeAvantClient < $val';

      case TypeCondition.ratioSoldeApres:
        // Solde restant après transaction <= X% du solde avant.
        // Condition autonome (soldeAvantClient > 0 && ...) : combine
        // deux comparaisons SANS dépendre de l'opérateur ET/OU global,
        // pour éviter le bug de mélange OU/ET vu dans le builder.
        final pourcentage =
            double.tryParse(c.params['pourcentage'] ?? '10') ?? 10;
        final ratio = (pourcentage / 100).toStringAsFixed(2);
        return 'soldeAvantClient > 0 && soldeApresClient <= (soldeAvantClient * $ratio)';

      case TypeCondition.ratioMontantSoldeAvant:
        // Montant transféré >= X% du solde avant transaction.
        final pourcentage2 =
            double.tryParse(c.params['pourcentage'] ?? '90') ?? 90;
        final ratio2 = (pourcentage2 / 100).toStringAsFixed(2);
        return 'soldeAvantClient > 0 && montant >= (soldeAvantClient * $ratio2)';
    }
  }

  void _ajouterCondition(TypeCondition type) {
    setState(() {
      _conditions.add(ConditionRegle(type: type));
    });
  }

  void _supprimerCondition(int index) {
    setState(() => _conditions.removeAt(index));
  }

  void _preremplirConditions(dynamic conditionsRaw) {
    final conditionsStr = conditionsRaw?.toString() ?? '';
    if (conditionsStr.trim().isEmpty) return;

    final lignes = conditionsStr
        .split(';')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty);

    for (final ligne in lignes) {
      final condition = _parserLigneEnCondition(ligne);
      if (condition != null) {
        _conditions.add(condition);
      }
    }
  }

  ConditionRegle? _parserLigneEnCondition(String ligne) {
    RegExpMatch? m;

    // Ratio solde après <= X% du solde avant — testé avant les patterns
    // simples soldeAvantClient > / <, car son motif est composé.
    m = RegExp(
            r'^soldeAvantClient\s*>\s*0\s*&&\s*soldeApresClient\s*<=\s*\(soldeAvantClient\s*\*\s*([\d.]+)\)$')
        .firstMatch(ligne);
    if (m != null) {
      final ratio = double.tryParse(m.group(1)!) ?? 0.10;
      return ConditionRegle(
        type: TypeCondition.ratioSoldeApres,
        params: {'pourcentage': (ratio * 100).round().toString()},
      );
    }

    // Ratio montant >= X% du solde avant
    m = RegExp(
            r'^soldeAvantClient\s*>\s*0\s*&&\s*montant\s*>=\s*\(soldeAvantClient\s*\*\s*([\d.]+)\)$')
        .firstMatch(ligne);
    if (m != null) {
      final ratio = double.tryParse(m.group(1)!) ?? 0.90;
      return ConditionRegle(
        type: TypeCondition.ratioMontantSoldeAvant,
        params: {'pourcentage': (ratio * 100).round().toString()},
      );
    }

    // Solde avant supérieur à
    m = RegExp(r'^soldeAvantClient\s*>\s*(\d+)$').firstMatch(ligne);
    if (m != null) {
      return ConditionRegle(
        type: TypeCondition.soldeAvantSuperieur,
        params: {'montant': m.group(1)!},
      );
    }

    // Solde avant inférieur à
    m = RegExp(r'^soldeAvantClient\s*<\s*(\d+)$').firstMatch(ligne);
    if (m != null) {
      return ConditionRegle(
        type: TypeCondition.soldeAvantInferieur,
        params: {'montant': m.group(1)!},
      );
    }

    // Montant rond (multiple de X) — doit être testé avant montantSuperieur
    m = RegExp(r'^montant\s*%\s*(\d+)\s*==\s*0$').firstMatch(ligne);
    if (m != null) {
      return ConditionRegle(
        type: TypeCondition.montantRond,
        params: {'diviseur': m.group(1)!},
      );
    }

    // Montant supérieur à
    m = RegExp(r'^montant\s*>\s*(\d+)$').firstMatch(ligne);
    if (m != null) {
      return ConditionRegle(
        type: TypeCondition.montantSuperieur,
        params: {'montant': m.group(1)!},
      );
    }

    // Montant inférieur à
    m = RegExp(r'^montant\s*<\s*(\d+)$').firstMatch(ligne);
    if (m != null) {
      return ConditionRegle(
        type: TypeCondition.montantInferieur,
        params: {'montant': m.group(1)!},
      );
    }

    // Type de transaction (un seul type, ex. type == "TRANSFER", ou
    // plusieurs entre parenthèses avec OU, ex. (type == "A" || type == "B"))
    if (RegExp(r'^\(?type\s*==\s*"\w+"(\s*\|\|\s*type\s*==\s*"\w+")*\)?$')
        .hasMatch(ligne)) {
      final types = RegExp(r'type\s*==\s*"(\w+)"')
          .allMatches(ligne)
          .map((mm) => mm.group(1)!)
          .toList();
      return ConditionRegle(
        type: TypeCondition.typeTransaction,
        params: {'types': types},
      );
    }

    // Heure entre X et Y
    m = RegExp(r'^heure\s*>=\s*(\d+)\s*\|\|\s*heure\s*<=\s*(\d+)$')
        .firstMatch(ligne);
    if (m != null) {
      return ConditionRegle(
        type: TypeCondition.heureEntre,
        params: {'heureDebut': m.group(1)!, 'heureFin': m.group(2)!},
      );
    }

    // Solde négatif (regex mise à jour : soldeApresClient au lieu de
    // soldeApres, pour matcher ce que _conditionEnDRL génère désormais)
    if (RegExp(r'^soldeApresClient\s*<\s*0$').hasMatch(ligne)) {
      return ConditionRegle(type: TypeCondition.soldeNegatif);
    }

    // Bénéficiaire inconnu (regex mise à jour : nomDestinataire au lieu
    // de nomDest)
    if (RegExp(r'^!historiqueContient\(nomDestinataire\)$').hasMatch(ligne)) {
      return ConditionRegle(type: TypeCondition.beneficiaireInconnu);
    }

    // Nombre de transactions (accumulation)
    m = RegExp(
            r'Accumulation\s*:\s*>\s*(\d+)\s*transactions\s*en\s*(\d+)\s*secondes')
        .firstMatch(ligne);
    if (m != null) {
      return ConditionRegle(
        type: TypeCondition.nombreTransactions,
        params: {'nombre': m.group(1)!, 'secondes': m.group(2)!},
      );
    }

    // Ligne non reconnue (condition écrite manuellement en DRL avancé) → ignorée
    return null;
  }

  bool get _peutSoumettre =>
      _nomCtrl.text.trim().isNotEmpty && _conditions.isNotEmpty;

  Future<void> _soumettre() async {
    if (!_peutSoumettre || _envoiEnCours) return;

    final payload = construirePayloadPourSoumission(
      nom: _nomCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      criticite: _criticite,
      contenuDrl: _drlGenere,
      conditions: _conditions
          .map((c) => _conditionEnDRL(c))
          .where((line) => line.isNotEmpty)
          .toList(),
    );

    setState(() => _envoiEnCours = true);
    try {
      await widget.onSoumettre(payload);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Erreur lors de la soumission : $e')),
            ],
          ),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 900,
        height: MediaQuery.of(context).size.height * 0.88,
        child: Row(
          children: [
            // ── Panneau gauche : formulaire ──────────────────────────────
            Expanded(
              flex: 5,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfosGenerales(),
                            const SizedBox(height: 20),
                            _buildConditions(),
                          ],
                        ),
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            ),

            // ── Panneau droit : aperçu DRL ───────────────────────────────
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header aperçu
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.code_rounded,
                              size: 15, color: AppColors.success),
                          const SizedBox(width: 8),
                          Text('Aperçu DRL en temps réel',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white)),
                          const Spacer(),
                          // Copier DRL
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: _drlGenere));
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text('DRL copié',
                                    style: GoogleFonts.inter(fontSize: 12)),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                margin: const EdgeInsets.all(16),
                                duration: const Duration(seconds: 2),
                              ));
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.copy_rounded,
                                      size: 12,
                                      color:
                                          Colors.white.withValues(alpha: 0.6)),
                                  const SizedBox(width: 4),
                                  Text('Copier',
                                      style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: Colors.white
                                              .withValues(alpha: 0.6))),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Contenu DRL
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: _DRLViewer(drl: _drlGenere),
                      ),
                    ),
                    // Info bas
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Ce fichier DRL sera soumis au validateur pour compilation.',
                              style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.3),
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.blueImf.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.rule_outlined,
                size: 17, color: AppColors.blueImf),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.regleExistante != null
                      ? 'Modifier la règle'
                      : 'Créer une nouvelle règle',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
                Text(
                  'Sans écrire de code — le DRL est généré automatiquement',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded,
                size: 18, color: AppColors.textSecondary),
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }

  // ─── Infos générales ──────────────────────────────────────────────────────

  Widget _buildInfosGenerales() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Informations générales'),
        const SizedBox(height: 12),

        // Nom
        const _ChampLabel(
          label: 'Nom de la règle',
          required: true,
          aide: 'Un nom court et descriptif. Ex: "Transfert massif nocturne"',
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _nomCtrl,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: _inputDeco(
              hint: 'Ex : Transfert massif > 1 000 000 FCFA',
              icon: Icons.title_rounded),
        ),

        const SizedBox(height: 14),

        // Description
        const _ChampLabel(
          label: 'Description',
          aide: 'Expliquez en clair ce que cette règle détecte.',
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _descCtrl,
          maxLines: 2,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: _inputDeco(
              hint:
                  'Ex : Détecte tout transfert dépassant 1 000 000 FCFA vers un compte externe.',
              icon: Icons.description_outlined),
        ),

        const SizedBox(height: 14),

        // Criticité
        const _ChampLabel(
          label: 'Niveau de criticité',
          aide: 'Définit la priorité de l\'alerte générée par cette règle.',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _CriticiteCard(
              label: 'Élevée',
              description: 'Risque important\nà traiter rapidement',
              color: AppColors.danger,
              selected: _criticite == 'ELEVE',
              icon: Icons.warning_amber_rounded,
              onTap: () => setState(() => _criticite = 'ELEVE'),
            ),
            const SizedBox(width: 8),
            _CriticiteCard(
              label: 'Moyenne',
              description: 'Risque modéré\nà surveiller',
              color: AppColors.warning,
              selected: _criticite == 'MOYEN',
              icon: Icons.info_outline_rounded,
              onTap: () => setState(() => _criticite = 'MOYEN'),
            ),
            const SizedBox(width: 8),
            _CriticiteCard(
              label: 'Faible',
              description: 'Risque limité\nà surveiller',
              color: AppColors.info,
              selected: _criticite == 'FAIBLE',
              icon: Icons.info_outline_rounded,
              onTap: () => setState(() => _criticite = 'FAIBLE'),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Conditions ───────────────────────────────────────────────────────────

  Widget _buildConditions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Conditions de détection'),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.infoLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.info.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 13, color: AppColors.info),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Une transaction déclenchera l\'alerte si elle vérifie '
                  'toutes les conditions (ET) ou au moins une (OU).',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.info, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Opérateur logique
        if (_conditions.length > 1) ...[
          Row(
            children: [
              Text('Combiner les conditions avec :',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 10),
              _ToggleOperateur(
                valeur: _operateurLogique,
                onChanged: (v) => setState(() => _operateurLogique = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Liste conditions existantes
        ..._conditions.asMap().entries.map((e) => Padding(
              key: ValueKey(e.value),
              padding: const EdgeInsets.only(bottom: 8),
              child: _CarteCondition(
                key: ObjectKey(e.value),
                index: e.key,
                condition: e.value,
                onChanged: () => setState(() {}),
                onSupprimer: () => _supprimerCondition(e.key),
              ),
            )),

        const SizedBox(height: 8),

        // Boutons ajout condition
        Text('Ajouter une condition :',
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _BoutonAjout(
              label: 'Montant supérieur à',
              icon: Icons.arrow_upward_rounded,
              color: AppColors.danger,
              onTap: () => _ajouterCondition(TypeCondition.montantSuperieur),
            ),
            _BoutonAjout(
              label: 'Montant inférieur à',
              icon: Icons.arrow_downward_rounded,
              color: AppColors.info,
              onTap: () => _ajouterCondition(TypeCondition.montantInferieur),
            ),
            _BoutonAjout(
              label: 'Montant rond',
              icon: Icons.toll_rounded,
              color: AppColors.warning,
              onTap: () => _ajouterCondition(TypeCondition.montantRond),
            ),
            _BoutonAjout(
              label: 'Type de transaction',
              icon: Icons.swap_horiz_rounded,
              color: AppColors.blueImf,
              onTap: () => _ajouterCondition(TypeCondition.typeTransaction),
            ),
            _BoutonAjout(
              label: 'Heure de la journée',
              icon: Icons.access_time_rounded,
              color: AppColors.warning,
              onTap: () => _ajouterCondition(TypeCondition.heureEntre),
            ),
            _BoutonAjout(
              label: 'Nombre de transactions',
              icon: Icons.repeat_rounded,
              color: AppColors.danger,
              onTap: () => _ajouterCondition(TypeCondition.nombreTransactions),
            ),
            _BoutonAjout(
              label: 'Solde négatif après',
              icon: Icons.trending_down_rounded,
              color: AppColors.danger,
              onTap: () => _ajouterCondition(TypeCondition.soldeNegatif),
            ),
            _BoutonAjout(
              label: 'Bénéficiaire inconnu',
              icon: Icons.person_off_outlined,
              color: AppColors.warning,
              onTap: () => _ajouterCondition(TypeCondition.beneficiaireInconnu),
            ),
            _BoutonAjout(
              label: 'Solde avant supérieur à',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.info,
              onTap: () => _ajouterCondition(TypeCondition.soldeAvantSuperieur),
            ),
            _BoutonAjout(
              label: 'Solde avant inférieur à',
              icon: Icons.account_balance_wallet_outlined,
              color: AppColors.warning,
              onTap: () => _ajouterCondition(TypeCondition.soldeAvantInferieur),
            ),
            _BoutonAjout(
              label: 'Vidage (solde restant %)',
              icon: Icons.no_accounts_rounded,
              color: AppColors.danger,
              onTap: () => _ajouterCondition(TypeCondition.ratioSoldeApres),
            ),
            _BoutonAjout(
              label: 'Vidage (montant %)',
              icon: Icons.no_accounts_rounded,
              color: AppColors.danger,
              onTap: () =>
                  _ajouterCondition(TypeCondition.ratioMontantSoldeAvant),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Footer ───────────────────────────────────────────────────────────────

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          // Validation (largeur bornée + ellipsis : ne pousse jamais les
          // boutons hors de l'écran, tronque proprement si trop étroit)
          if (!_peutSoumettre)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 13, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _nomCtrl.text.trim().isEmpty
                          ? 'Saisissez un nom'
                          : 'Ajoutez au moins une condition',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          // Boutons : groupés ensemble, passent à la ligne suivante du Wrap
          // si l'espace manque, au lieu de déborder à droite.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler',
                    style: GoogleFonts.inter(color: AppColors.textSecondary)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed:
                    (_peutSoumettre && !_envoiEnCours) ? _soumettre : null,
                icon: _envoiEnCours
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_outlined, size: 15),
                label: _envoiEnCours
                    ? const Text('Envoi...')
                    : const Text('Soumettre au validateur'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                  textStyle: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w500),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 16, color: AppColors.textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.blueImf, width: 1),
      ),
    );
  }
}

// ─── Carte condition ──────────────────────────────────────────────────────────

class _CarteCondition extends StatefulWidget {
  final int index;
  final ConditionRegle condition;
  final VoidCallback onChanged;
  final VoidCallback onSupprimer;

  const _CarteCondition({
    super.key,
    required this.index,
    required this.condition,
    required this.onChanged,
    required this.onSupprimer,
  });

  @override
  State<_CarteCondition> createState() => _CarteConditionState();
}

class _CarteConditionState extends State<_CarteCondition> {
  late Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = {};
    _initCtrls();
  }

  void _initCtrls() {
    switch (widget.condition.type) {
      case TypeCondition.montantSuperieur:
      case TypeCondition.montantInferieur:
        _ctrls['montant'] = TextEditingController(
            text: widget.condition.params['montant'] ?? '');
        break;
      case TypeCondition.montantRond:
        _ctrls['diviseur'] = TextEditingController(
            text: widget.condition.params['diviseur'] ?? '100000');
        break;
      case TypeCondition.heureEntre:
        _ctrls['heureDebut'] = TextEditingController(
            text: widget.condition.params['heureDebut'] ?? '22');
        _ctrls['heureFin'] = TextEditingController(
            text: widget.condition.params['heureFin'] ?? '5');
        break;
      case TypeCondition.nombreTransactions:
        _ctrls['nombre'] = TextEditingController(
            text: widget.condition.params['nombre'] ?? '5');
        _ctrls['secondes'] = TextEditingController(
            text: widget.condition.params['secondes'] ?? '60');
        break;
      case TypeCondition.soldeAvantSuperieur:
      case TypeCondition.soldeAvantInferieur:
        _ctrls['montant'] = TextEditingController(
            text: widget.condition.params['montant'] ?? '');
        break;
      case TypeCondition.ratioSoldeApres:
        _ctrls['pourcentage'] = TextEditingController(
            text: widget.condition.params['pourcentage'] ?? '10');
        break;
      case TypeCondition.ratioMontantSoldeAvant:
        _ctrls['pourcentage'] = TextEditingController(
            text: widget.condition.params['pourcentage'] ?? '90');
        break;
      default:
        break;
    }
    for (final e in _ctrls.entries) {
      e.value.addListener(() {
        widget.condition.params[e.key] = e.value.text;
        widget.onChanged();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _titre {
    switch (widget.condition.type) {
      case TypeCondition.montantSuperieur:
        return 'Montant supérieur à';
      case TypeCondition.montantInferieur:
        return 'Montant inférieur à';
      case TypeCondition.montantRond:
        return 'Montant rond (multiple de)';
      case TypeCondition.typeTransaction:
        return 'Type de transaction';
      case TypeCondition.heureEntre:
        return 'Heure entre';
      case TypeCondition.nombreTransactions:
        return 'Nombre de transactions';
      case TypeCondition.soldeNegatif:
        return 'Solde négatif après transaction';
      case TypeCondition.beneficiaireInconnu:
        return 'Bénéficiaire inconnu';
      case TypeCondition.soldeAvantSuperieur:
        return 'Solde avant transaction supérieur à';
      case TypeCondition.soldeAvantInferieur:
        return 'Solde avant transaction inférieur à';
      case TypeCondition.ratioSoldeApres:
        return 'Solde restant ≤ X% du solde avant (vidage)';
      case TypeCondition.ratioMontantSoldeAvant:
        return 'Montant ≥ X% du solde avant (vidage)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          // Header condition
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.blueImf,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text('${widget.index + 1}',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Text(_titre,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: AppColors.danger),
                  onPressed: widget.onSupprimer,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Supprimer cette condition',
                ),
              ],
            ),
          ),
          // Corps condition
          Padding(
            padding: const EdgeInsets.all(14),
            child: _buildCorps(),
          ),
        ],
      ),
    );
  }

  Widget _buildCorps() {
    switch (widget.condition.type) {
      case TypeCondition.montantSuperieur:
        return _ChampMontant(
          ctrl: _ctrls['montant']!,
          label: 'Si le montant est supérieur à',
          hint: 'Ex: 1000000',
        );

      case TypeCondition.montantInferieur:
        return _ChampMontant(
          ctrl: _ctrls['montant']!,
          label: 'Si le montant est inférieur à',
          hint: 'Ex: 10000',
        );

      case TypeCondition.montantRond:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détecte les montants qui sont des multiples exacts de :',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            _ChampMontant(
              ctrl: _ctrls['diviseur']!,
              label: 'Multiple de (FCFA)',
              hint: 'Ex: 100000',
            ),
            const SizedBox(height: 6),
            Text(
              'Exemple : 100 000 → détecte 100 000, 200 000, 300 000...',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
        );

      case TypeCondition.typeTransaction:
        final List<String> typesSelectionnes =
            (widget.condition.params['types'] as List?)
                    ?.cast<String>()
                    .toList() ??
                <String>['TRANSFER'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Si le type de transaction est (un ou plusieurs) :',
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'TRANSFER',
                'CASH_OUT',
                'CASH_IN',
                'PAYMENT',
                'DEBIT',
              ].map((t) {
                final sel = typesSelectionnes.contains(t);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      final nouveauxTypes =
                          List<String>.from(typesSelectionnes);
                      if (sel) {
                        // Au moins 1 type doit rester sélectionné.
                        if (nouveauxTypes.length > 1) {
                          nouveauxTypes.remove(t);
                        }
                      } else {
                        nouveauxTypes.add(t);
                      }
                      widget.condition.params['types'] = nouveauxTypes;
                    });
                    widget.onChanged();
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.blueImf.withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sel ? AppColors.blueImf : AppColors.border,
                        width: sel ? 1 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (sel) ...[
                          const Icon(Icons.check_rounded,
                              size: 13, color: AppColors.blueImf),
                          const SizedBox(width: 4),
                        ],
                        Text(t,
                            style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                color: sel
                                    ? AppColors.blueImf
                                    : AppColors.textSecondary,
                                fontWeight:
                                    sel ? FontWeight.w600 : FontWeight.w400)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Text(
              'Coche plusieurs types pour un OU entre eux '
              '(ex : CASH_IN + CASH_OUT).',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
        );

      case TypeCondition.heureEntre:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détecte les transactions effectuées entre ces heures :',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ChampHeure(
                    ctrl: _ctrls['heureDebut']!,
                    label: 'De (heure)',
                    hint: 'Ex: 22',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('à',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textSecondary)),
                ),
                Expanded(
                  child: _ChampHeure(
                    ctrl: _ctrls['heureFin']!,
                    label: 'À (heure)',
                    hint: 'Ex: 5',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Exemple : De 22h à 5h → détecte les transactions nocturnes',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
        );

      case TypeCondition.nombreTransactions:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détecte si un même compte effectue trop de transactions en peu de temps :',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ChampNombre(
                    ctrl: _ctrls['nombre']!,
                    label: 'Plus de (transactions)',
                    hint: 'Ex: 5',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ChampNombre(
                    ctrl: _ctrls['secondes']!,
                    label: 'En moins de (secondes)',
                    hint: 'Ex: 60',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Exemple : Plus de 5 transactions en 60 secondes → rafale suspecte',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
        );

      case TypeCondition.soldeNegatif:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.dangerLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.danger.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.trending_down_rounded,
                  size: 16, color: AppColors.danger),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Déclenche une alerte si le solde du compte devient négatif après la transaction.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.danger, height: 1.4),
                ),
              ),
            ],
          ),
        );

      case TypeCondition.beneficiaireInconnu:
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warningLight,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.person_off_outlined,
                  size: 16, color: AppColors.warning),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Déclenche une alerte si le bénéficiaire n\'a jamais reçu d\'argent de ce compte auparavant.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.warning, height: 1.4),
                ),
              ),
            ],
          ),
        );

      case TypeCondition.soldeAvantSuperieur:
        return _ChampMontant(
          ctrl: _ctrls['montant']!,
          label: 'Si le solde avant la transaction est supérieur à',
          hint: 'Ex: 5000000',
        );

      case TypeCondition.soldeAvantInferieur:
        return _ChampMontant(
          ctrl: _ctrls['montant']!,
          label: 'Si le solde avant la transaction est inférieur à',
          hint: 'Ex: 10000',
        );

      case TypeCondition.ratioSoldeApres:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détecte si le solde restant après la transaction tombe à '
              'ce pourcentage (ou moins) du solde avant :',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 8),
            _ChampPourcentage(ctrl: _ctrls['pourcentage']!, hint: 'Ex: 10'),
            const SizedBox(height: 6),
            Text(
              'Exemple : 10% → le compte se retrouve avec 10% ou moins '
              'de ce qu\'il avait avant → vidage quasi-total.',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
        );

      case TypeCondition.ratioMontantSoldeAvant:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Détecte si le montant transféré atteint ce pourcentage '
              '(ou plus) du solde avant la transaction :',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 8),
            _ChampPourcentage(ctrl: _ctrls['pourcentage']!, hint: 'Ex: 90'),
            const SizedBox(height: 6),
            Text(
              'Exemple : 90% → le montant transféré représente 90% ou '
              'plus du solde disponible avant la transaction.',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ],
        );
    }
  }
}

// ─── Viewer DRL coloré ────────────────────────────────────────────────────────

class _DRLViewer extends StatelessWidget {
  final String drl;
  const _DRLViewer({required this.drl});

  @override
  Widget build(BuildContext context) {
    final lignes = drl.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lignes.asMap().entries.map((e) {
        final ligne = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Numéro de ligne
              SizedBox(
                width: 24,
                child: Text(
                  '${e.key + 1}',
                  style: GoogleFonts.jetBrainsMono(
                      fontSize: 11, color: Colors.white.withValues(alpha: 0.2)),
                ),
              ),
              const SizedBox(width: 8),
              // Ligne colorée
              Expanded(child: _colorerLigne(ligne)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _colorerLigne(String ligne) {
    // Commentaire
    if (ligne.trim().startsWith('//')) {
      return Text(ligne,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.35),
              fontStyle: FontStyle.italic,
              height: 1.6));
    }
    // Mots-clés Drools
    if (RegExp(r'^(rule|when|then|end)\b').hasMatch(ligne.trim())) {
      return Text(ligne,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: const Color(0xFFBB86FC),
              fontWeight: FontWeight.w600,
              height: 1.6));
    }
    // insert / new
    if (ligne.contains('insert') || ligne.contains('new Alerte')) {
      return Text(ligne,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 12, color: const Color(0xFF82AAFF), height: 1.6));
    }
    // Conditions (contiennent > < == %)
    if (RegExp(r'[><=!%]').hasMatch(ligne)) {
      return Text(ligne,
          style: GoogleFonts.jetBrainsMono(
              fontSize: 12, color: AppColors.success, height: 1.6));
    }
    // Défaut
    return Text(ligne,
        style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.75),
            height: 1.6));
  }
}

// ─── Petits composants ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0)),
          const SizedBox(width: 10),
          const Expanded(
              child: Divider(
                  color: AppColors.borderLight, height: 1, thickness: 0.5)),
        ],
      ),
    );
  }
}

class _ChampLabel extends StatelessWidget {
  final String label;
  final bool required;
  final String? aide;

  const _ChampLabel({required this.label, this.required = false, this.aide});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            if (required) ...[
              const SizedBox(width: 4),
              const Text('*',
                  style: TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
          ],
        ),
        if (aide != null) ...[
          const SizedBox(height: 2),
          Text(aide!,
              style: GoogleFonts.inter(
                  fontSize: 10, color: AppColors.textSecondary, height: 1.3)),
        ],
      ],
    );
  }
}

class _CriticiteCard extends StatelessWidget {
  final String label;
  final String description;
  final Color color;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _CriticiteCard({
    required this.label,
    required this.description,
    required this.color,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.08) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon,
                      size: 16,
                      color: selected ? color : AppColors.textSecondary),
                  const Spacer(),
                  if (selected)
                    Container(
                      width: 14,
                      height: 14,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: color),
                      child: const Icon(Icons.check_rounded,
                          size: 9, color: Colors.white),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? color : AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(description,
                  style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                      height: 1.4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BoutonAjout extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BoutonAjout({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 13, color: color),
            const SizedBox(width: 5),
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ToggleOperateur extends StatelessWidget {
  final String valeur;
  final ValueChanged<String> onChanged;

  const _ToggleOperateur({required this.valeur, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: ['ET', 'OU'].map((op) {
          final sel = valeur == op;
          return GestureDetector(
            onTap: () => onChanged(op),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.blueImf : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(op,
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : AppColors.textSecondary)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChampMontant extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;

  const _ChampMontant(
      {required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.jetBrainsMono(
              fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: 'FCFA',
            suffixStyle:
                GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.blueImf, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChampPourcentage extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;

  const _ChampPourcentage({required this.ctrl, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style:
          GoogleFonts.jetBrainsMono(fontSize: 13, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        suffixText: '%',
        suffixStyle:
            GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.blueImf, width: 1),
        ),
      ),
    );
  }
}

class _ChampHeure extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;

  const _ChampHeure(
      {required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          style: GoogleFonts.jetBrainsMono(
              fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: 'h',
            suffixStyle:
                GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.blueImf, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChampNombre extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;

  const _ChampNombre(
      {required this.ctrl, required this.label, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 5),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.jetBrainsMono(
              fontSize: 13, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.blueImf, width: 1),
            ),
          ),
        ),
      ],
    );
  }
}
