import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/evaluations_provider.dart';
import '../providers/historique_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

/// Widget de debug pour afficher l'état de la connexion API
class ApiDebugWidget extends StatefulWidget {
  const ApiDebugWidget({super.key});

  @override
  State<ApiDebugWidget> createState() => _ApiDebugWidgetState();
}

class _ApiDebugWidgetState extends State<ApiDebugWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dashboard = context.watch<DashboardProvider>();
    final evaluations = context.watch<EvaluationsProvider>();
    final historique = context.watch<HistoriqueProvider>();
    final auth = context.watch<AuthProvider>();

    final hasErrors = (dashboard.erreur?.isNotEmpty ?? false) ||
        (evaluations.erreur?.isNotEmpty ?? false) ||
        (historique.erreur?.isNotEmpty ?? false);

    if (!hasErrors && !_expanded) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasErrors
            ? AppColors.danger.withValues(alpha: 0.05)
            : AppColors.warning.withValues(alpha: 0.05),
        border: Border.all(
          color: hasErrors
              ? AppColors.danger.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: hasErrors ? AppColors.danger : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    hasErrors ? Icons.error_outline : Icons.warning_outlined,
                    size: 16,
                    color: hasErrors ? AppColors.danger : AppColors.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasErrors ? '⚠️ Erreurs détectées' : 'ℹ️ Info API',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: hasErrors ? AppColors.danger : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: AppColors.border.withValues(alpha: 0.5)),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Auth info
                  Text(
                    'Authentification:',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.token != null && auth.token!.isNotEmpty
                        ? '✓ Token présent (${auth.token!.substring(0, 20)}...)'
                        : '✗ Pas de token',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: auth.token != null && auth.token!.isNotEmpty
                          ? AppColors.success
                          : AppColors.danger,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dashboard errors
                  if (dashboard.erreur?.isNotEmpty ?? false) ...[
                    Text(
                      'Dashboard:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dashboard.erreur!,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Evaluations errors
                  if (evaluations.erreur?.isNotEmpty ?? false) ...[
                    Text(
                      'Évaluations:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      evaluations.erreur!,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Historique errors
                  if (historique.erreur?.isNotEmpty ?? false) ...[
                    Text(
                      'Historique:',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      historique.erreur!,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // API endpoints
                  Text(
                    'Endpoints configurés:',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...[
                    '/api/dashboard/metier/stats',
                    '/api/alertes?limit=4',
                    '/api/demandes?limit=3',
                    '/api/dashboard',
                    '/api/alertes/historique?jours=30',
                  ].map(
                    (ep) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '• $ep',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
