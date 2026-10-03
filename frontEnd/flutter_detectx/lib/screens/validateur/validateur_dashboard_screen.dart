import '../../providers/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/evaluations_provider.dart';
import '../../theme/app_theme.dart';

class ValidateurDashboardScreen extends StatefulWidget {
  const ValidateurDashboardScreen({super.key});

  @override
  State<ValidateurDashboardScreen> createState() =>
      _ValidateurDashboardScreenState();
}

class _ValidateurDashboardScreenState extends State<ValidateurDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      if (auth.token != null) {
        await context
            .read<DashboardProvider>()
            .chargerTout(auth.token!, role: 'VALIDATEUR');
      }
    });
  }

  Future<void> _refreshDashboard() async {
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      await context
          .read<DashboardProvider>()
          .chargerTout(auth.token!, role: 'VALIDATEUR');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildTopbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildKpiRow(dashboard),
                  const SizedBox(height: 20),
                  const PerformancesMoteurWidget(),
                  const SizedBox(height: 20),
                  _buildDemandes(dashboard),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopbar() {
    final now = DateTime.now();
    final dateStr = DateFormat("EEEE d MMMM yyyy", 'fr_FR').format(now);
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
              Text('Dashboard validateur',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text(dateStr,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh_rounded, size: 15),
            label: const Text('Actualiser'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              side: const BorderSide(color: AppColors.border, width: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              textStyle: GoogleFonts.inter(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(DashboardProvider dashboard) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            icon: Icons.pending_actions_outlined,
            label: 'Demandes en attente',
            value: '${dashboard.reglesEnAttente}',
            accentColor: AppColors.warning,
            sous: 'En attente du validateur',
            onTap: () => context.go('/validateur/regles'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            icon: Icons.history_rounded,
            label: 'Demandes récentes',
            value: '${dashboard.demandesRecentes.length}',
            accentColor: AppColors.info,
            sous: 'Chargées depuis la base',
            onTap: () => context.go('/validateur/historique'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            icon: Icons.rule_rounded,
            label: 'Règles actives',
            value: '${dashboard.reglesActives}',
            accentColor: AppColors.success,
            sous: 'Total depuis le moteur',
            onTap: () => context.go('/validateur/catalogue-regles'),
          ),
        ),
      ],
    );
  }

  Widget _buildDemandes(DashboardProvider dashboard) {
    final demandesLimitees = dashboard.demandesRecentes.take(10).toList();
    return _Panel(
      title: 'Mes approbations récentes',
      icon: Icons.pending_actions_outlined,
      actionLabel: 'Voir tout',
      onAction: () => context.go('/validateur/historique'),
      child: Column(
        children:
            demandesLimitees.map((d) => _CarteDemande(demande: d)).toList(),
      ),
    );
  }
}

// ─── Composants ───────────────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final String sous;
  final VoidCallback? onTap;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.sous,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: accentColor),
                ),
                const Spacer(),
                Container(
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(sous,
                style: GoogleFonts.inter(
                    fontSize: 10, color: AppColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title,
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                ),
                if (actionLabel != null && onAction != null)
                  GestureDetector(
                    onTap: onAction,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(actionLabel!,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 11, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(4), child: child),
        ],
      ),
    );
  }
}

class _CarteDemande extends StatelessWidget {
  final Map<String, dynamic> demande;
  const _CarteDemande({required this.demande});

  Color get _couleurStatut {
    switch (demande['statut']) {
      case 'APPROUVEE':
        return AppColors.success;
      case 'REJETEE':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  Color get _couleurType {
    switch (demande['type']) {
      case 'CREATION':
        return AppColors.success;
      case 'MODIFICATION':
        return AppColors.info;
      case 'SUPPRESSION':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatTemps(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _couleurType.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              demande['type'] == 'CREATION'
                  ? Icons.add_rounded
                  : demande['type'] == 'MODIFICATION'
                      ? Icons.edit_outlined
                      : Icons.delete_outline_rounded,
              size: 14,
              color: _couleurType,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(demande['nom'],
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis),
                Text(_formatTemps(demande['soumisLe']),
                    style: GoogleFonts.inter(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: _couleurStatut.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              demande['statut'] == 'EN_ATTENTE'
                  ? 'En attente'
                  : demande['statut'] == 'APPROUVEE'
                      ? 'Approuvée'
                      : 'Rejetée',
              style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: _couleurStatut),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget performances moteur (réutilisable) ────────────────────────────────

class PerformancesMoteurWidget extends StatefulWidget {
  const PerformancesMoteurWidget({super.key});

  @override
  State<PerformancesMoteurWidget> createState() =>
      _PerformancesMoteurWidgetState();
}

class _PerformancesMoteurWidgetState extends State<PerformancesMoteurWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.token != null) {
        context.read<EvaluationsProvider>().charger(auth.token!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EvaluationsProvider>();
    final precision = provider.precision;
    final rappel = provider.rappel;
    final f1Score = provider.f1Score;
    final tauxFauxPositifs = provider.tauxFauxPositifs;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Performances du moteur Drools',
                      style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                ),
                Text('EvaluationsService',
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 10, color: AppColors.textSecondary)),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Métriques principales
                Row(
                  children: [
                    Expanded(
                      child: _MetriqueCard(
                        label: 'Précision',
                        valeur: precision,
                        couleur: _couleurMetrique(precision),
                        description: 'VP / (VP + FP)',
                        tooltip:
                            'Parmi les alertes levées, ${(precision * 100).toStringAsFixed(1)}% étaient de vraies fraudes.',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetriqueCard(
                        label: 'Rappel',
                        valeur: rappel,
                        couleur: _couleurMetrique(rappel),
                        description: 'VP / (VP + FN)',
                        tooltip:
                            'Le moteur a détecté ${(rappel * 100).toStringAsFixed(1)}% de toutes les fraudes réelles.',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetriqueCard(
                        label: 'F1-Score',
                        valeur: f1Score,
                        couleur: _couleurMetrique(f1Score),
                        description: '2 × (P × R) / (P + R)',
                        tooltip: 'Équilibre global entre précision et rappel.',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MetriqueCard(
                        label: 'Taux FP',
                        valeur: tauxFauxPositifs,
                        couleur: tauxFauxPositifs < 0.05
                            ? AppColors.success
                            : tauxFauxPositifs < 0.10
                                ? AppColors.warning
                                : AppColors.danger,
                        description: 'FP / (FP + VN)',
                        tooltip:
                            '${(tauxFauxPositifs * 100).toStringAsFixed(1)}% des transactions normales ont été signalées à tort.',
                        inverse: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(
                    color: AppColors.borderLight, height: 1, thickness: 0.5),
                const SizedBox(height: 14),

                // Compteurs bruts
                Row(
                  children: [
                    _CompteurBrut(
                      label: 'Vrais Positifs',
                      valeur: provider.vraisPositifs,
                      couleur: AppColors.success,
                      icon: Icons.check_circle_outline_rounded,
                      description: 'Fraudes correctement détectées',
                    ),
                    _Separateur(),
                    _CompteurBrut(
                      label: 'Faux Positifs',
                      valeur: provider.fauxPositifs,
                      couleur: AppColors.warning,
                      icon: Icons.warning_amber_rounded,
                      description: 'Transactions normales signalées à tort',
                    ),
                    _Separateur(),
                    _CompteurBrut(
                      label: 'Faux Négatifs',
                      valeur: provider.fauxNegatifs,
                      couleur: AppColors.danger,
                      icon: Icons.cancel_outlined,
                      description: 'Fraudes non détectées par le moteur',
                    ),
                    _Separateur(),
                    _CompteurBrut(
                      label: 'Vrais Négatifs',
                      valeur: provider.vraisNegatifs,
                      couleur: AppColors.blueImf,
                      icon: Icons.shield_outlined,
                      description:
                          'Transactions normales correctement ignorées',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _couleurMetrique(double val) {
    if (val >= 0.90) return AppColors.success;
    if (val >= 0.75) return AppColors.warning;
    return AppColors.danger;
  }
}

class _MetriqueCard extends StatelessWidget {
  final String label;
  final double valeur;
  final Color couleur;
  final String description;
  final String tooltip;
  final bool inverse;

  const _MetriqueCard({
    required this.label,
    required this.valeur,
    required this.couleur,
    required this.description,
    required this.tooltip,
    this.inverse = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: couleur.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: couleur.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                ),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: couleur,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${(valeur * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 22, fontWeight: FontWeight.w600, color: couleur),
            ),
            const SizedBox(height: 6),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: valeur,
                minHeight: 4,
                backgroundColor: couleur.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(couleur),
              ),
            ),
            const SizedBox(height: 6),
            Text(description,
                style: GoogleFonts.jetBrainsMono(
                    fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _CompteurBrut extends StatelessWidget {
  final String label;
  final int valeur;
  final Color couleur;
  final IconData icon;
  final String description;

  const _CompteurBrut({
    required this.label,
    required this.valeur,
    required this.couleur,
    required this.icon,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: couleur),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$valeur',
                      style: GoogleFonts.jetBrainsMono(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary),
                      overflow: TextOverflow.ellipsis),
                  Text(description,
                      style: GoogleFonts.inter(
                          fontSize: 10, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Separateur extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 48,
      color: AppColors.borderLight,
    );
  }
}
