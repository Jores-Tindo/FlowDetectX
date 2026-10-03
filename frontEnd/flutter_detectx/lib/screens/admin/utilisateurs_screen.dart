import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/utilisateurs_provider.dart';
import '../../providers/journaux_provider.dart';
import 'dart:async';

class UtilisateursScreen extends StatefulWidget {
  const UtilisateursScreen({super.key});

  @override
  State<UtilisateursScreen> createState() => _UtilisateursScreenState();
}

class _UtilisateursScreenState extends State<UtilisateursScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filtreStatut = 'TOUS';
  bool _showFormulaire = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    // Rafraichit automatiquement toutes les 8 secondes tant que cet
    // ecran est ouvert, pour refleter les activations faites ailleurs
    // (navigateur) sans avoir a redemarrer l'app.
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      context.read<UtilisateursProvider>().charger(auth.token ?? '');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _toggleStatut(Map<String, dynamic> u) {
    final provider = context.read<UtilisateursProvider>();
    final auth = context.read<AuthProvider>();
    final journaux = context.read<JournauxProvider>();
    final token = auth.token ?? '';

    if (u['statut'] == 'ACTIF') {
      provider.suspendre(token, u['id']);
      journaux.enregistrer(
        action: 'SUSPENSION_COMPTE',
        details: 'Compte de ${u['prenom']} ${u['nom']} suspendu',
        utilisateur: auth.nomComplet,
        type: 'warning',
      );
    } else {
      provider.reactiver(token, u['id']);
      journaux.enregistrer(
        action: 'SUSPENSION_COMPTE',
        details: 'Compte de ${u['prenom']} ${u['nom']} réactivé',
        utilisateur: auth.nomComplet,
        type: 'success',
      );
    }
  }

  void _supprimerUtilisateur(Map<String, dynamic> u) {
    showDialog(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        titre: 'Supprimer le compte',
        message:
            'Voulez-vous supprimer le compte de ${u['prenom']} ${u['nom']} ? Cette action est irréversible.',
        labelConfirm: 'Supprimer',
        couleurConfirm: AppColors.danger,
        onConfirm: () async {
          final messenger = ScaffoldMessenger.of(ctx);
          final provider =
              Provider.of<UtilisateursProvider>(ctx, listen: false);
          final auth = Provider.of<AuthProvider>(ctx, listen: false);
          final journaux = Provider.of<JournauxProvider>(ctx, listen: false);
          final success = await provider.supprimer(auth.token ?? '', u['id']);
          if (success) {
            journaux.enregistrer(
              action: 'SUPPRESSION_COMPTE',
              details: 'Compte de ${u['prenom']} ${u['nom']} supprimé',
              utilisateur: auth.nomComplet,
              type: 'warning',
            );
          } else {
            messenger.showSnackBar(const SnackBar(
              content:
                  Text('Impossible de supprimer ce compte pour le moment.'),
              backgroundColor: AppColors.danger,
            ));
          }
        },
      ),
    );
  }

  String _labelRole(String role) {
    switch (role) {
      case 'VALIDATEUR':
        return 'Validateur';
      case 'UTILISATEUR_METIER':
        return 'Utilisateur métier';
      default:
        return role;
    }
  }

  Color _couleurRole(String role) {
    return role == 'VALIDATEUR' ? AppColors.blueImf : AppColors.info;
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UtilisateursProvider>();
    final auth = context.read<AuthProvider>();

    if (provider.utilisateurs.isEmpty && !provider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.charger(auth.token ?? '');
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildTopbar(provider),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildBarreOutils(),
                      Expanded(child: _buildListe(provider)),
                    ],
                  ),
                ),
                if (_showFormulaire)
                  _FormulaireCreation(
                    onFermer: () => setState(() => _showFormulaire = false),
                    onCreer: (data) async {
                      final journaux = context.read<JournauxProvider>();
                      final messenger = ScaffoldMessenger.of(context);

                      if (!provider.canCreateCompte(data['role'])) {
                        messenger.showSnackBar(SnackBar(
                          content:
                              Text(provider.quotaErreurPourRole(data['role'])),
                          backgroundColor: AppColors.danger,
                        ));
                        return;
                      }

                      final success = await provider.creerCompte(
                        token: auth.token ?? '',
                        nom: data['nom'],
                        prenom: data['prenom'],
                        email: data['email'],
                        role: data['role'],
                      );

                      if (!mounted) return;

                      if (!success) {
                        messenger.showSnackBar(SnackBar(
                          content:
                              Text(provider.quotaErreurPourRole(data['role'])),
                          backgroundColor: AppColors.danger,
                        ));
                        return;
                      }
                      journaux.enregistrer(
                        action: 'CREATION_COMPTE',
                        details:
                            'Compte créé pour ${data['email']} — rôle ${data['role']}',
                        utilisateur: auth.nomComplet,
                        type: 'success',
                      );
                      setState(() => _showFormulaire = false);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Topbar ───────────────────────────────────────────────────────────────

  Widget _buildTopbar(UtilisateursProvider provider) {
    final actifs = provider.totalActifs;
    final suspendus = provider.totalSuspendus;
    final enAttente = provider.totalEnAttente;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comptes utilisateurs',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Row(
                children: [
                  Text('${provider.utilisateurs.length} compte(s)',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                  Text(
                      '  ·  $actifs actif(s)  ·  $suspendus suspendu(s)  ·  $enAttente en attente',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showFormulaire = !_showFormulaire),
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('Nouveau compte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: GoogleFonts.inter(fontSize: 13),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Barre outils ─────────────────────────────────────────────────────────

  Widget _buildBarreOutils() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom, email, identifiant...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 17, color: AppColors.textSecondary),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.border, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.border, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.blueImf, width: 1),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _FiltreChip(
            label: 'Tous',
            actif: _filtreStatut == 'TOUS',
            onTap: () => setState(() => _filtreStatut = 'TOUS'),
          ),
          const SizedBox(width: 6),
          _FiltreChip(
            label: 'Actifs',
            actif: _filtreStatut == 'ACTIF',
            onTap: () => setState(() => _filtreStatut = 'ACTIF'),
            color: AppColors.success,
          ),
          const SizedBox(width: 6),
          _FiltreChip(
            label: 'En attente',
            actif: _filtreStatut == 'EN_ATTENTE',
            onTap: () => setState(() => _filtreStatut = 'EN_ATTENTE'),
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          _FiltreChip(
            label: 'Suspendus',
            actif: _filtreStatut == 'SUSPENDU',
            onTap: () => setState(() => _filtreStatut = 'SUSPENDU'),
            color: AppColors.warning,
          ),
        ],
      ),
    );
  }

  // ─── Liste ────────────────────────────────────────────────────────────────

  Widget _buildListe(UtilisateursProvider provider) {
    final liste = provider.filtrer(
      statut: _filtreStatut,
      recherche: _searchController.text,
    );

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.group_off_outlined,
                size: 40, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('Aucun utilisateur trouvé',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // En-tête tableau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _EnTeteCol(label: 'Utilisateur')),
                Expanded(flex: 2, child: _EnTeteCol(label: 'Email')),
                Expanded(flex: 1, child: _EnTeteCol(label: 'Rôle')),
                Expanded(flex: 1, child: _EnTeteCol(label: 'Statut')),
                Expanded(flex: 2, child: _EnTeteCol(label: 'Date création')),
                SizedBox(width: 80),
              ],
            ),
          ),
          // Lignes
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
              border: Border(
                left: BorderSide(color: AppColors.border, width: 0.5),
                right: BorderSide(color: AppColors.border, width: 0.5),
                bottom: BorderSide(color: AppColors.border, width: 0.5),
              ),
            ),
            child: Column(
              children: liste
                  .map((u) => _LigneUtilisateur(
                        utilisateur: u,
                        labelRole: _labelRole(u['role']),
                        couleurRole: _couleurRole(u['role']),
                        onToggleStatut: () => _toggleStatut(u),
                        onSupprimer: () => _supprimerUtilisateur(u),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ligne tableau ────────────────────────────────────────────────────────────

class _LigneUtilisateur extends StatelessWidget {
  final Map<String, dynamic> utilisateur;
  final String labelRole;
  final Color couleurRole;
  final VoidCallback onToggleStatut;
  final VoidCallback onSupprimer;

  const _LigneUtilisateur({
    required this.utilisateur,
    required this.labelRole,
    required this.couleurRole,
    required this.onToggleStatut,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final String statut = utilisateur['statut'];
    final bool actif = statut == 'ACTIF';
    final bool suspendu = statut == 'SUSPENDU';
    final bool enAttente = statut == 'EN_ATTENTE';
    final initiale =
        utilisateur['prenom'].toString().substring(0, 1).toUpperCase();

    String labelStatut;
    Color couleurStatut;
    if (actif) {
      labelStatut = 'Actif';
      couleurStatut = AppColors.success;
    } else if (suspendu) {
      labelStatut = 'Suspendu';
      couleurStatut = AppColors.warning;
    } else {
      labelStatut = 'En attente';
      couleurStatut = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 0.5)),
      ),
      child: Row(
        children: [
          // Nom + prénom
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.blueImf.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initiale,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blueImf,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${utilisateur['prenom']} ${utilisateur['nom']}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Email
          Expanded(
            flex: 2,
            child: Text(
              utilisateur['email'],
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Rôle
          Expanded(
            flex: 1,
            child: _Badge(label: labelRole, color: couleurRole),
          ),
          // Statut
          Expanded(
            flex: 1,
            child: _Badge(label: labelStatut, color: couleurStatut),
          ),
          // Date
          Expanded(
            flex: 2,
            child: Text(
              '${utilisateur['dateCreation'].day.toString().padLeft(2, '0')}/'
              '${utilisateur['dateCreation'].month.toString().padLeft(2, '0')}/'
              '${utilisateur['dateCreation'].year}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // Actions
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!enAttente)
                  Tooltip(
                    message: actif ? 'Suspendre' : 'Réactiver',
                    child: IconButton(
                      icon: Icon(
                        actif
                            ? Icons.block_outlined
                            : Icons.check_circle_outline_rounded,
                        size: 18,
                        color: actif ? AppColors.warning : AppColors.success,
                      ),
                      onPressed: onToggleStatut,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ),
                Tooltip(
                  message: 'Supprimer',
                  child: IconButton(
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: AppColors.danger,
                    ),
                    onPressed: onSupprimer,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Formulaire création latéral ──────────────────────────────────────────────

class _FormulaireCreation extends StatefulWidget {
  final VoidCallback onFermer;
  final Function(Map<String, dynamic>) onCreer;

  const _FormulaireCreation({
    required this.onFermer,
    required this.onCreer,
  });

  @override
  State<_FormulaireCreation> createState() => _FormulaireCreationState();
}

class _FormulaireCreationState extends State<_FormulaireCreation> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _role = 'VALIDATEUR';
  bool _envoi = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _soumettre() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _envoi = true);
    widget.onCreer({
      'nom': _nomCtrl.text.trim(),
      'prenom': _prenomCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'role': _role,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Nouveau compte',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textSecondary),
                  onPressed: widget.onFermer,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                ),
              ],
            ),
          ),

          // Formulaire
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info token
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.infoLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.info.withValues(alpha: 0.2),
                            width: 0.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              size: 15, color: AppColors.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Un lien d\'activation sera envoyé par email. L\'utilisateur définira lui-même son identifiant et mot de passe.',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.info,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _ChampFormulaire(
                      label: 'Prénom',
                      controller: _prenomCtrl,
                      hint: 'Prénom',
                      validateur: (v) =>
                          v!.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 14),
                    _ChampFormulaire(
                      label: 'Nom',
                      controller: _nomCtrl,
                      hint: 'Nom de famille',
                      validateur: (v) =>
                          v!.trim().isEmpty ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 14),
                    _ChampFormulaire(
                      label: 'Email',
                      controller: _emailCtrl,
                      hint: 'adresse@imf.bj',
                      clavier: TextInputType.emailAddress,
                      validateur: (v) {
                        if (v!.trim().isEmpty) return 'Champ requis';
                        if (!v.contains('@')) return 'Email invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Rôle
                    Text(
                      'Rôle',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border, width: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        color: AppColors.surface,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _role,
                          isExpanded: true,
                          style: GoogleFonts.inter(
                              fontSize: 13, color: AppColors.textPrimary),
                          items: const [
                            DropdownMenuItem(
                                value: 'VALIDATEUR', child: Text('Validateur')),
                            DropdownMenuItem(
                                value: 'UTILISATEUR_METIER',
                                child: Text('Utilisateur Métier')),
                          ],
                          onChanged: (v) => setState(() => _role = v!),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _envoi ? null : _soumettre,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          textStyle: GoogleFonts.inter(fontSize: 13),
                        ),
                        child: _envoi
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Créer le compte'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog confirmation ──────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String titre;
  final String message;
  final String labelConfirm;
  final Color couleurConfirm;
  final VoidCallback onConfirm;

  const _ConfirmDialog({
    required this.titre,
    required this.message,
    required this.labelConfirm,
    required this.couleurConfirm,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        titre,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        message,
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler',
              style: GoogleFonts.inter(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: couleurConfirm,
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.inter(fontSize: 13),
          ),
          child: Text(labelConfirm),
        ),
      ],
    );
  }
}

// ─── Petits composants ────────────────────────────────────────────────────────

class _EnTeteCol extends StatelessWidget {
  final String label;
  const _EnTeteCol({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _FiltreChip extends StatelessWidget {
  final String label;
  final bool actif;
  final VoidCallback onTap;
  final Color? color;

  const _FiltreChip({
    required this.label,
    required this.actif,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.blueImf;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: actif ? c.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: actif ? c : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: actif ? c : AppColors.textSecondary,
            fontWeight: actif ? FontWeight.w500 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ChampFormulaire extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validateur;
  final TextInputType? clavier;

  const _ChampFormulaire({
    required this.label,
    required this.controller,
    required this.hint,
    this.validateur,
    this.clavier,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: clavier,
          validator: validateur,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
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
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.danger, width: 1),
            ),
            fillColor: AppColors.surface,
            filled: true,
          ),
        ),
      ],
    );
  }
}
