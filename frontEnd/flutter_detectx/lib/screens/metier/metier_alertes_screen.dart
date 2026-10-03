import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/alertes_provider.dart';
import '../../providers/simulation_provider.dart';
import '../../providers/auth_provider.dart';
import 'export_dialog.dart';

class MetierAlertesScreen extends StatefulWidget {
  const MetierAlertesScreen({super.key});

  static List<Map<String, dynamic>> fusionnerAlertes(
    List<Map<String, dynamic>> simulationAlertes,
    List<Map<String, dynamic>> alertesHistorique,
  ) {
    final result = <Map<String, dynamic>>[];
    final vus = <String>{};

    for (final alerte in <Map<String, dynamic>>[
      ...simulationAlertes,
      ...alertesHistorique,
    ]) {
      final cle = _cleAlerte(alerte);
      if (cle.isEmpty || vus.contains(cle)) {
        continue;
      }
      vus.add(cle);
      result.add(Map<String, dynamic>.from(alerte));
    }

    return result;
  }

  static String _cleAlerte(Map<String, dynamic> alerte) {
    final id = alerte['id'];
    if (id != null) {
      return 'id:$id';
    }

    final horodatage = alerte['horodatage']?.toString() ?? '';
    final regle = alerte['regleNom']?.toString() ?? '';
    final type = alerte['type']?.toString() ?? '';
    final client = alerte['nomClient']?.toString() ?? '';
    final montant = alerte['montant']?.toString() ?? '';

    return '$horodatage|$regle|$type|$client|$montant';
  }

  @override
  State<MetierAlertesScreen> createState() => _MetierAlertesScreenState();
}

class _MetierAlertesScreenState extends State<MetierAlertesScreen> {
  String _filtreCriticite = 'TOUS';
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.token != null) {
        context.read<AlertesProvider>().charger(auth.token!);
      }
    });
  }

  List<Map<String, dynamic>> _filtrer(List<Map<String, dynamic>> alertes) {
    return alertes.where((a) {
      final q = _searchCtrl.text.toLowerCase();
      final matchSearch = q.isEmpty ||
          a['regleNom'].toString().toLowerCase().contains(q) ||
          (a['nomClient']?.toString().toLowerCase().contains(q) ?? false) ||
          a['type'].toString().toLowerCase().contains(q);
      final matchCriticite =
          _filtreCriticite == 'TOUS' || a['criticite'] == _filtreCriticite;
      return matchSearch && matchCriticite;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final simulationProvider = context.watch<SimulationProvider>();
    final simulationActive = simulationProvider.simulationActive;
    final alertesProvider = context.watch<AlertesProvider>();
    final alertes = MetierAlertesScreen.fusionnerAlertes(
      simulationProvider.alertes,
      alertesProvider.alertes,
    );
    final liste = _filtrer(alertes);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildTopbar(simulationActive, alertes.length, alertes),
          _buildBarreOutils(),
          Expanded(
            child: alertesProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : alertes.isEmpty
                    ? _buildEtatVide(simulationActive)
                    : _buildListe(liste),
          ),
        ],
      ),
    );
  }

  // ─── Topbar ───────────────────────────────────────────────────────────────

  Widget _buildTopbar(bool simulationActive, int nbAlertes,
      List<Map<String, dynamic>> alertes) {
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
              Text('Alertes en temps réel',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text('$nbAlertes alerte(s) reçue(s)',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),

          // Indicateur statut simulation
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: simulationActive
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: simulationActive
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (simulationActive)
                  const _PulseDot(color: AppColors.success)
                else
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.textHint,
                    ),
                  ),
                const SizedBox(width: 7),
                Text(
                  simulationActive ? 'Simulation active' : 'Simulation arrêtée',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      color: simulationActive
                          ? AppColors.success
                          : AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Bouton Démarrer / Arrêter
          if (simulationActive)
            OutlinedButton.icon(
              onPressed: () async {
                final auth = context.read<AuthProvider>();
                await context
                    .read<SimulationProvider>()
                    .arreterSimulation(auth.token ?? '');
              },
              icon: const Icon(Icons.stop_rounded, size: 15),
              label: const Text('Arrêter simulation'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger, width: 0.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 12),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                context
                    .read<SimulationProvider>()
                    .demarrerSimulation(auth.token ?? '');
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 15),
              label: const Text('Démarrer simulation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 12),
                elevation: 0,
              ),
            ),

          if (nbAlertes > 0) ...[
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  context.read<SimulationProvider>().viderAlertes(),
              icon: const Icon(Icons.clear_all_rounded, size: 15),
              label: const Text('Vider'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border, width: 0.5),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => ExportDialog(alertes: alertes),
              ),
              icon: const Icon(Icons.download_rounded, size: 15),
              label: const Text('Exporter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueImf,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: GoogleFonts.inter(fontSize: 12),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Barre outils ─────────────────────────────────────────────────────────

  Widget _buildBarreOutils() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Rechercher dans les alertes...',
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
            label: 'Toutes',
            actif: _filtreCriticite == 'TOUS',
            onTap: () => setState(() => _filtreCriticite = 'TOUS'),
          ),
          const SizedBox(width: 6),
          _FiltreChip(
            label: 'Élevée',
            actif: _filtreCriticite == 'ELEVE',
            color: AppColors.danger,
            onTap: () => setState(() => _filtreCriticite = 'ELEVE'),
          ),
          const SizedBox(width: 6),
          _FiltreChip(
            label: 'Moyenne',
            actif: _filtreCriticite == 'MOYEN',
            color: AppColors.warning,
            onTap: () => setState(() => _filtreCriticite = 'MOYEN'),
          ),
          const SizedBox(width: 6),
          _FiltreChip(
            label: 'Faible',
            actif: _filtreCriticite == 'FAIBLE',
            color: AppColors.info,
            onTap: () => setState(() => _filtreCriticite = 'FAIBLE'),
          ),
        ],
      ),
    );
  }

  // ─── État vide ────────────────────────────────────────────────────────────

  Widget _buildEtatVide(bool simulationActive) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: const Icon(Icons.notifications_outlined,
                size: 30, color: AppColors.textHint),
          ),
          const SizedBox(height: 16),
          Text(
            simulationActive
                ? 'En attente d\'alertes...'
                : 'Aucune alerte pour le moment',
            style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            simulationActive
                ? 'Le moteur Drools analyse les transactions en temps réel.'
                : 'Démarrez la simulation pour recevoir des alertes.',
            style:
                GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (!simulationActive) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                final auth = context.read<AuthProvider>();
                context
                    .read<SimulationProvider>()
                    .demarrerSimulation(auth.token ?? '');
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 16),
              label: const Text('Démarrer la simulation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: GoogleFonts.inter(fontSize: 13),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Liste alertes ────────────────────────────────────────────────────────

  Widget _buildListe(List<Map<String, dynamic>> liste) {
    if (liste.isEmpty) {
      return Center(
        child: Text('Aucune alerte pour ce filtre.',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textSecondary)),
      );
    }

    // Grouper par date
    final groupes = <String, List<Map<String, dynamic>>>{};
    for (final a in liste) {
      final horodatage = a['horodatage'] is String
          ? DateTime.tryParse(a['horodatage'] as String)
          : null;
      final cle = horodatage != null
          ? DateFormat('yyyy-MM-dd').format(horodatage)
          : 'inconnu';
      groupes.putIfAbsent(cle, () => []).add(a);
    }

    // Trier les dates du plus récent au plus ancien
    final datesTriees = groupes.keys.toList()..sort((a, b) => b.compareTo(a));

    // Construire la liste d'items (séparateurs + alertes)
    final items = <dynamic>[];
    for (final date in datesTriees) {
      items.add(_DateSeparateur(dateKey: date));
      items.addAll(groupes[date]!);
    }

    return Column(
      children: [
        // En-tête colonnes
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border:
                Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
          ),
          child: const Row(
            children: [
              SizedBox(width: 12),
              Expanded(flex: 3, child: _EnTete('Règle déclenchée')),
              Expanded(flex: 2, child: _EnTete('Client')),
              Expanded(flex: 2, child: _EnTete('Montant')),
              Expanded(flex: 1, child: _EnTete('Type')),
              Expanded(flex: 2, child: _EnTete('Criticité')),
              Expanded(flex: 2, child: _EnTete('Heure')),
            ],
          ),
        ),
        // Liste avec séparateurs
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              if (item is _DateSeparateur) {
                return _buildSeparateurDate(item.dateKey);
              }
              return _LigneAlerte(alerte: item as Map<String, dynamic>);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSeparateurDate(String dateKey) {
    String label;
    try {
      final date = DateTime.parse(dateKey);
      final now = DateTime.now();
      final hier = DateTime.now().subtract(const Duration(days: 1));

      if (DateFormat('yyyy-MM-dd').format(date) ==
          DateFormat('yyyy-MM-dd').format(now)) {
        label =
            "Aujourd'hui · ${DateFormat('d MMMM yyyy', 'fr_FR').format(date)}";
      } else if (DateFormat('yyyy-MM-dd').format(date) ==
          DateFormat('yyyy-MM-dd').format(hier)) {
        label = "Hier · ${DateFormat('d MMMM yyyy', 'fr_FR').format(date)}";
      } else {
        label = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
      }
    } catch (_) {
      label = dateKey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              color: AppColors.border,
              height: 1,
              thickness: 0.5,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.navy.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Divider(
              color: AppColors.border,
              height: 1,
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ligne alerte ─────────────────────────────────────────────────────────────

class _LigneAlerte extends StatelessWidget {
  final Map<String, dynamic> alerte;
  const _LigneAlerte({required this.alerte});

  Color get _couleur {
    switch (alerte['criticite']) {
      case 'ELEVE':
        return AppColors.danger;
      case 'MOYEN':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estNouveau = alerte['nouveau'] == true;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: estNouveau ? _couleur.withValues(alpha: 0.04) : Colors.white,
        border: const Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: estNouveau ? _couleur : Colors.transparent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              alerte['regleNom'] ?? '-',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              alerte['nomClient'] ?? '-',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${NumberFormat('#,###', 'fr_FR').format(alerte['montant'] ?? 0)} FCFA',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 12, fontWeight: FontWeight.w500, color: _couleur),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              alerte['type'] ?? '-',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _couleur.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                alerte['criticite'] ?? '-',
                style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w500, color: _couleur),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              (alerte['horodatage'] is String
                          ? DateTime.tryParse(alerte['horodatage'] as String)
                          : null) !=
                      null
                  ? DateFormat('HH:mm:ss')
                      .format(DateTime.parse(alerte['horodatage'] as String))
                  : '-',
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Composants ───────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final Color color;
  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.5 + 0.5 * _ctrl.value),
        ),
      ),
    );
  }
}

class _EnTete extends StatelessWidget {
  final String label;
  const _EnTete(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(),
        style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
            letterSpacing: 0.8));
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
          border: Border.all(color: actif ? c : AppColors.border, width: 0.5),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: actif ? c : AppColors.textSecondary,
                fontWeight: actif ? FontWeight.w500 : FontWeight.w400)),
      ),
    );
  }
}

// ─── Séparateur date ──────────────────────────────────────────────────────────

class _DateSeparateur {
  final String dateKey;
  const _DateSeparateur({required this.dateKey});
}
