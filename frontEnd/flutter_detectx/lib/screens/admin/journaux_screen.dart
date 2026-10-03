import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/journaux_provider.dart';

class JournauxScreen extends StatefulWidget {
  const JournauxScreen({super.key});

  @override
  State<JournauxScreen> createState() => _JournauxScreenState();
}

class _JournauxScreenState extends State<JournauxScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtreAction = 'TOUS';
  DateTimeRange? _periodeFiltree;

  // TODO: GET /api/journaux?page=0&size=50
  final List<Map<String, dynamic>> _journaux = [
    {
      'id': 1,
      'action': 'CONNEXION',
      'details': 'Connexion réussie depuis 192.168.1.10',
      'utilisateur': 'Admin Principal',
      'horodatage': DateTime.now().subtract(const Duration(minutes: 5)),
      'type': 'success',
    },
    {
      'id': 2,
      'action': 'CREATION_COMPTE',
      'details': 'Compte créé pour k.brice@imf.bj — rôle VALIDATEUR',
      'utilisateur': 'Admin Principal',
      'horodatage': DateTime.now().subtract(const Duration(minutes: 22)),
      'type': 'success',
    },
    {
      'id': 3,
      'action': 'SUSPENSION_COMPTE',
      'details': 'Compte de Adjobi Marlène suspendu',
      'utilisateur': 'Admin Principal',
      'horodatage': DateTime.now().subtract(const Duration(hours: 1)),
      'type': 'warning',
    },
    {
      'id': 4,
      'action': 'MODIF_PARAMETRES',
      'details': 'Seuil de détection mis à jour : 500 000 → 750 000 FCFA',
      'utilisateur': 'Admin Principal',
      'horodatage': DateTime.now().subtract(const Duration(hours: 2)),
      'type': 'info',
    },
    {
      'id': 5,
      'action': 'MODIF_PROFIL',
      'details': 'Email mis à jour pour le compte Admin Principal',
      'utilisateur': 'Admin Principal',
      'horodatage': DateTime.now().subtract(const Duration(hours: 3)),
      'type': 'info',
    },
    {
      'id': 6,
      'action': 'DECONNEXION',
      'details': 'Déconnexion manuelle',
      'utilisateur': 'Admin Principal',
      'horodatage': DateTime.now().subtract(const Duration(hours: 5)),
      'type': 'neutral',
    },
    {
      'id': 7,
      'action': 'CREATION_COMPTE',
      'details': 'Compte créé pour g.hounkpe@imf.bj — rôle UTILISATEUR METIER',
      'utilisateur': 'Admin Principal',
      'horodatage': DateTime.now().subtract(const Duration(hours: 8)),
      'type': 'success',
    },
    {
      'id': 8,
      'action': 'CONNEXION',
      'details': 'Connexion réussie depuis 192.168.1.14',
      'utilisateur': 'Admin Principal',
      'horodatage': DateTime.now().subtract(const Duration(hours: 9)),
      'type': 'success',
    },
    {
      'id': 9,
      'action': 'MODIF_PARAMETRES',
      'details': 'Règle de détection "Transfert massif" activée',
      'utilisateur': 'Admin Principal',
      'horodatage': DateTime.now().subtract(const Duration(days: 1)),
      'type': 'info',
    },
    {
      'id': 10,
      'action': 'SUSPENSION_COMPTE',
      'details': 'Compte de T. Agbodji réactivé',
      'utilisateur': 'Admin Principal',
      'horodatage': DateTime.now().subtract(const Duration(days: 1, hours: 3)),
      'type': 'warning',
    },
  ];

  final List<String> _typesAction = [
    'TOUS',
    'CONNEXION',
    'DECONNEXION',
    'CREATION_COMPTE',
    'SUSPENSION_COMPTE',
    'MODIF_PARAMETRES',
    'MODIF_PROFIL',
  ];

  List<Map<String, dynamic>> get _journauxFiltres {
    return _journaux.where((j) {
      final q = _searchCtrl.text.toLowerCase();
      final matchSearch = q.isEmpty ||
          j['details'].toString().toLowerCase().contains(q) ||
          j['utilisateur'].toString().toLowerCase().contains(q) ||
          j['action'].toString().toLowerCase().contains(q);
      final matchAction =
          _filtreAction == 'TOUS' || j['action'] == _filtreAction;
      final matchPeriode = _periodeFiltree == null ||
          (j['horodatage'].isAfter(_periodeFiltree!.start) &&
              j['horodatage'].isBefore(_periodeFiltree!.end));
      return matchSearch && matchAction && matchPeriode;
    }).toList();
  }

  Future<void> _choisirPeriode() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.blueImf),
        ),
        child: child!,
      ),
    );
    if (result != null) setState(() => _periodeFiltree = result);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<JournauxProvider>();
    final auth = context.read<AuthProvider>();

    if (provider.journaux.isEmpty && !provider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.charger(auth.token ?? '');
      });
    }

    final liste = provider.filtrer(
      action: _filtreAction,
      recherche: _searchCtrl.text,
      periode: _periodeFiltree,
    );
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildTopbar(liste.length),
          _buildBarreOutils(),
          Expanded(child: _buildListe(liste)),
        ],
      ),
    );
  }

  Widget _buildTopbar(int count) {
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
              Text('Journaux d\'activité',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text('$count entrée(s) affichée(s)',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => setState(() {}),
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

  Widget _buildBarreOutils() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          // Recherche
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Rechercher dans les journaux...',
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

          // Filtre action
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 38,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.surface,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filtreAction,
                    isExpanded: true,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: AppColors.textPrimary),
                    items: _typesAction
                        .map((a) => DropdownMenuItem(
                              value: a,
                              child: Text(
                                a == 'TOUS'
                                    ? 'Toutes les actions'
                                    : a.replaceAll('_', ' '),
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _filtreAction = v!),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Filtre période
          OutlinedButton.icon(
            onPressed: _choisirPeriode,
            icon: const Icon(Icons.calendar_today_outlined, size: 14),
            label: Text(
              _periodeFiltree == null
                  ? 'Période'
                  : '${DateFormat('dd/MM').format(_periodeFiltree!.start)} — ${DateFormat('dd/MM').format(_periodeFiltree!.end)}',
              style: GoogleFonts.inter(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _periodeFiltree != null
                  ? AppColors.blueImf
                  : AppColors.textSecondary,
              side: BorderSide(
                color: _periodeFiltree != null
                    ? AppColors.blueImf
                    : AppColors.border,
                width: 0.5,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),

          if (_periodeFiltree != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  size: 16, color: AppColors.textSecondary),
              tooltip: 'Effacer la période',
              onPressed: () => setState(() => _periodeFiltree = null),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildListe(List<Map<String, dynamic>> liste) {
    if (liste.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_outlined,
                size: 40, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text('Aucun journal trouvé',
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
          // En-tête
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
                SizedBox(width: 36),
                SizedBox(width: 12),
                Expanded(flex: 2, child: _EnTete('Action')),
                Expanded(flex: 4, child: _EnTete('Détails')),
                Expanded(flex: 2, child: _EnTete('Utilisateur')),
                Expanded(flex: 2, child: _EnTete('Horodatage')),
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
              children: liste.map((j) => _LigneJournal(journal: j)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LigneJournal extends StatelessWidget {
  final Map<String, dynamic> journal;
  const _LigneJournal({required this.journal});

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
      case 'CONNEXION':
        return Icons.login_rounded;
      case 'DECONNEXION':
        return Icons.logout_rounded;
      case 'CREATION_COMPTE':
        return Icons.person_add_outlined;
      case 'SUSPENSION_COMPTE':
        return Icons.block_outlined;
      case 'MODIF_PARAMETRES':
        return Icons.settings_outlined;
      case 'MODIF_PROFIL':
        return Icons.edit_outlined;
      default:
        return Icons.history_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.borderLight, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(_icon, size: 16, color: _color),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                journal['action'].toString().replaceAll('_', ' '),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: _color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                journal['details'],
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              journal['utilisateur'],
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM/yyyy HH:mm').format(journal['horodatage']),
              style: GoogleFonts.jetBrainsMono(
                  fontSize: 11, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _EnTete extends StatelessWidget {
  final String label;
  const _EnTete(this.label);

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
