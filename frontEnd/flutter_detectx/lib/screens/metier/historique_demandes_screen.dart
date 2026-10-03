import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../theme/app_theme.dart';

class HistoriqueDemandesScreen extends StatefulWidget {
  const HistoriqueDemandesScreen({super.key});

  @override
  State<HistoriqueDemandesScreen> createState() =>
      _HistoriqueDemandesScreenState();
}

class _HistoriqueDemandesScreenState extends State<HistoriqueDemandesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      if (auth.token != null) {
        await context.read<DashboardProvider>().chargerDemandes(auth.token!);
      }
    });
  }

  String _formatTemps(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return 'il y a ${diff.inDays}j';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final demandes = provider.demandesToutes;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text('Historique des demandes',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: demandes.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Aucune demande',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: demandes.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 0.5, color: AppColors.borderLight),
                  itemBuilder: (context, index) {
                    final d = demandes[index];
                    final nom = d['nom'] as String? ?? 'Sans titre';
                    final soumis = d['soumisLe'] as DateTime? ?? DateTime.now();
                    final statut =
                        (d['statut'] as String? ?? 'EN_ATTENTE').toUpperCase();

                    Color statutColor;
                    if (statut == 'APPROUVEE')
                      statutColor = AppColors.success;
                    else if (statut == 'REJETEE')
                      statutColor = AppColors.danger;
                    else
                      statutColor = AppColors.warning;

                    final motifInline = (d['motifDemande'] as String? ??
                        d['motif'] as String? ??
                        '');

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(nom,
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (motifInline.isNotEmpty) const SizedBox(width: 8),
                          if (motifInline.isNotEmpty)
                            Flexible(
                              child: Text(
                                motifInline,
                                style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(_formatTemps(soumis),
                          style: GoogleFonts.inter(
                              fontSize: 11, color: AppColors.textSecondary)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statutColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statut == 'EN_ATTENTE'
                              ? 'En attente'
                              : statut == 'APPROUVEE'
                                  ? 'Approuvée'
                                  : 'Rejetée',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: statutColor),
                        ),
                      ),
                      onTap: () {
                        // TODO: ouvrir détail demande si nécessaire
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }
}
