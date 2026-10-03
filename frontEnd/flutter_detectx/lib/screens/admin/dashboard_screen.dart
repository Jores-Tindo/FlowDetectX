import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../metier/metier_dashboard_screen.dart' show PerformancesMoteurWidget;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  Future<void> _chargerDonnees() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      if (!mounted) return;
      await context.read<DashboardProvider>().chargerAdminStats(auth.token!);
      if (!mounted) return;
      await context.read<DashboardProvider>().chargerAlertes(auth.token!);
      if (!mounted) return;
      await context.read<DashboardProvider>().chargerJournaux(auth.token!);
      if (!mounted) return;
      await context
          .read<DashboardProvider>()
          .chargerUtilisateurs(auth.token!); // <-- AJOUTE CETTE LIGNE
    }
  }

  void _actualiser() {
    _chargerDonnees();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<DashboardProvider>();

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
                  // ── Section transactions ──────────────────────────
                  const _SectionLabel(label: 'Transactions'),
                  const SizedBox(height: 10),
                  _buildKpiTransactions(dashboardProvider),
                  const SizedBox(height: 20),

                  // ── Graphes ───────────────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 6, child: _buildGrapheLigne(dashboardProvider)),
                      const SizedBox(width: 16),
                      Expanded(
                          flex: 4, child: _buildGraphePie(dashboardProvider)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 4,
                          child: _buildGrapheBarres(dashboardProvider)),
                      const SizedBox(width: 16),
                      Expanded(
                          flex: 6,
                          child: _buildJournauxPanel(dashboardProvider)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Performances moteur ───────────────────────────
                  const PerformancesMoteurWidget(),
                  const SizedBox(height: 20),

                  // ── Section utilisateurs ──────────────────────────
                  const _SectionLabel(label: 'Comptes & Système'),
                  const SizedBox(height: 10),
                  _buildKpiUtilisateurs(dashboardProvider),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Topbar ───────────────────────────────────────────────────────────────

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
              Text('Dashboard',
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
            onPressed: _actualiser,
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

  // ─── KPI Transactions ─────────────────────────────────────────────────────

  Widget _buildKpiTransactions(DashboardProvider dashboard) {
    final alertesElevees = dashboard.alertesByCriticite.isNotEmpty
        ? dashboard.alertesByCriticite[0]
        : 0;
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            icon: Icons.notifications_active_outlined,
            label: 'Total alertes',
            value: NumberFormat('#,###', 'fr_FR').format(dashboard.alertes),
            accentColor: AppColors.blueImf,
            sous: 'Toutes simulations confondues',
            iconBg: AppColors.blueImf.withValues(alpha: 0.08),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            icon: Icons.gpp_bad_outlined,
            label: 'Alertes élevées',
            value: NumberFormat('#,###', 'fr_FR').format(alertesElevees),
            accentColor: AppColors.danger,
            sous: 'Criticité ÉLEVÉE',
            iconBg: AppColors.danger.withValues(alpha: 0.08),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            icon: Icons.rule_outlined,
            label: 'Règles actives',
            value: '${dashboard.reglesActives}',
            accentColor: AppColors.success,
            sous: 'Dans le moteur Drools',
            iconBg: AppColors.success.withValues(alpha: 0.08),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            icon: Icons.check_circle_outline_rounded,
            label: 'Précision du moteur',
            value:
                '${(dashboard.dernierePrecision ?? 0 * 100).toStringAsFixed(1)}%',
            accentColor: AppColors.info,
            sous: 'Dernière simulation',
            iconBg: AppColors.info.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  // ─── KPI Utilisateurs ─────────────────────────────────────────────────────

  Widget _buildKpiUtilisateurs(DashboardProvider dashboard) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            icon: Icons.group_outlined,
            label: 'Utilisateurs actifs',
            value:
                '${dashboard.totalUtilisateurs - dashboard.comptesSuspendus}',
            accentColor: AppColors.blueImf,
            sous: 'Sur ${dashboard.totalUtilisateurs} comptes',
            iconBg: AppColors.blueImf.withValues(alpha: 0.08),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            icon: Icons.block_outlined,
            label: 'Comptes suspendus',
            value: '${dashboard.comptesSuspendus}',
            accentColor: AppColors.warning,
            sous: 'En attente de réactivation',
            iconBg: AppColors.warning.withValues(alpha: 0.08),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            icon: Icons.history_outlined,
            label: "Activités aujourd'hui",
            value: '${dashboard.journauxAujourdhui}',
            accentColor: AppColors.info,
            sous: 'Actions enregistrées',
            iconBg: AppColors.info.withValues(alpha: 0.08),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            icon: Icons.manage_accounts_outlined,
            label: 'Rôles attribués',
            value: '${dashboard.totalUtilisateurs}',
            accentColor: AppColors.success,
            sous: 'Validateurs + Métier',
            iconBg: AppColors.success.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  // ─── Graphe ligne — transactions / jour ──────────────────────────────────

  Widget _buildGrapheLigne(DashboardProvider dashboard) {
    final jours = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

    // Convertir les données du provider en FlSpot
    final txByDay = dashboard.transactionsByDay;
    final spots = txByDay
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value['valeur'] as double))
        .toList();

    // Trouver la valeur max pour l'échelle
    double maxY = spots.isEmpty
        ? 100
        : spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;
    if (maxY == 0) maxY = 100;

    return _Panel(
      title: 'Transactions par jour',
      icon: Icons.show_chart_rounded,
      child: SizedBox(
        height: 200,
        child: spots.isEmpty
            ? Center(
                child: Text('Pas de données',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: LineChart(
                  LineChartData(
                    gridData: () {
                      double _gridInterval = (maxY / 5).ceil().toDouble();
                      if (_gridInterval == 0) _gridInterval = 1.0;
                      return FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _gridInterval,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.borderLight,
                          strokeWidth: 0.5,
                        ),
                      );
                    }(),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: (() {
                            double _interval = (maxY / 5).ceil().toDouble();
                            if (_interval == 0) _interval = 1.0;
                            return _interval;
                          })(),
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}',
                            style: GoogleFonts.inter(
                                fontSize: 9, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              jours[v.toInt() % 7],
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.blueImf,
                        barWidth: 2,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (_, __, ___, ____) =>
                              FlDotCirclePainter(
                            radius: 3,
                            color: AppColors.blueImf,
                            strokeWidth: 1.5,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.blueImf.withValues(alpha: 0.06),
                        ),
                      ),
                    ],
                    minY: 0,
                    maxY: maxY,
                  ),
                ),
              ),
      ),
    );
  }

  // ─── Graphe Pie — répartition types ──────────────────────────────────────

  Widget _buildGraphePie(DashboardProvider dashboard) {
    final typesTransaction = dashboard.transactionsByType;
    final total = typesTransaction.fold<double>(
        0, (sum, t) => sum + (t['valeur'] as double));

    return _Panel(
      title: 'Types de transactions',
      icon: Icons.pie_chart_outline_rounded,
      child: SizedBox(
        height: 200,
        child: typesTransaction.isEmpty
            ? Center(
                child: Text('Pas de données',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              )
            : Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 36,
                        sections: typesTransaction.map((t) {
                          final pct = total > 0
                              ? (t['valeur'] as double) / total * 100
                              : 0;
                          return PieChartSectionData(
                            value: t['valeur'] as double,
                            color: t['couleur'] as Color,
                            radius: 40,
                            title: '${pct.toStringAsFixed(0)}%',
                            titleStyle: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: typesTransaction
                        .map((t) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: t['couleur'] as Color,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    t['label'],
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
      ),
    );
  }

  // ─── Graphe barres — alertes par criticité ────────────────────────────────

  Widget _buildGrapheBarres(DashboardProvider dashboard) {
    final labels = ['Élevée', 'Moyenne', 'Faible'];
    final couleurs = [AppColors.danger, AppColors.warning, AppColors.info];
    final alertesData = dashboard.alertesByCriticite;

    // Trouver la valeur max
    double maxY = alertesData.isEmpty
        ? 30
        : alertesData.reduce((a, b) => a > b ? a : b).toDouble() * 1.2;

    return _Panel(
      title: 'Alertes par criticité',
      icon: Icons.bar_chart_rounded,
      child: SizedBox(
        height: 200,
        child: alertesData.isEmpty
            ? Center(
                child: Text('Pas de données',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textSecondary)),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                child: BarChart(
                  BarChartData(
                    gridData: () {
                      double _gridInterval = (maxY / 5).ceil().toDouble();
                      if (_gridInterval == 0) _gridInterval = 1.0;
                      return FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _gridInterval,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.borderLight,
                          strokeWidth: 0.5,
                        ),
                      );
                    }(),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) => Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              labels[v.toInt()],
                              style: GoogleFonts.inter(
                                  fontSize: 10, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, _) => Text(
                            '${v.toInt()}',
                            style: GoogleFonts.inter(
                                fontSize: 9, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: alertesData.asMap().entries.map((e) {
                      return BarChartGroupData(
                        x: e.key,
                        barRods: [
                          BarChartRodData(
                            toY: e.value.toDouble(),
                            color: couleurs[e.key],
                            width: 32,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ],
                      );
                    }).toList(),
                    maxY: maxY,
                  ),
                ),
              ),
      ),
    );
  }

  // ─── Journaux récents ─────────────────────────────────────────────────────

  Widget _buildJournauxPanel(DashboardProvider dashboard) {
    final listeAffichee = dashboard.journauxRecents.length > 10
        ? dashboard.journauxRecents.sublist(0, 10)
        : dashboard.journauxRecents;

    return _Panel(
      title: 'Journaux récents',
      icon: Icons.history_outlined,
      actionLabel: 'Voir tout',
      onAction: () => GoRouter.of(context).push('/admin/journaux'),
      child: Column(
        children: listeAffichee.map((j) => _JournalItem(journal: j)).toList(),
      ),
    );
  }
}

// ─── Composants ───────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Divider(color: AppColors.border, height: 1, thickness: 0.5),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final Color iconBg;
  final String sous;

  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.iconBg,
    required this.sous,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  color: iconBg,
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
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sous,
            style:
                GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
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

class _JournalItem extends StatelessWidget {
  final Map<String, dynamic> journal;
  const _JournalItem({required this.journal});

  Color get _color {
    switch (journal['type']) {
      case 'success':
        return AppColors.success;
      case 'warning':
        return AppColors.warning;
      case 'info':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData get _icon {
    switch (journal['action']) {
      case 'CREATION_COMPTE':
        return Icons.person_add_outlined;
      case 'ATTRIBUTION_ROLE':
        return Icons.manage_accounts_outlined;
      case 'SUSPENSION_COMPTE':
        return Icons.block_outlined;
      case 'CONNEXION':
        return Icons.login_rounded;
      case 'MODIF_PARAMETRES':
        return Icons.settings_outlined;
      default:
        return Icons.history_outlined;
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return DateFormat('dd/MM HH:mm').format(dt);
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
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(_icon, size: 14, color: _color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  journal['action'].toString().replaceAll('_', ' '),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  journal['details'],
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatTime(journal['horodatage']),
            style:
                GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
