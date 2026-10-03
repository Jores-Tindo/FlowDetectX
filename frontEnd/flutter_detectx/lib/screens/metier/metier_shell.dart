import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/simulation_provider.dart';

class MetierShell extends StatefulWidget {
  final Widget child;
  const MetierShell({super.key, required this.child});

  @override
  State<MetierShell> createState() => _MetierShellState();
}

class _MetierShellState extends State<MetierShell> {
  static const double _minSidebarWidth = 180.0;
  static const double _maxSidebarWidth = 320.0;
  double _sidebarWidth = 224.0;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Row(
        children: [
          SizedBox(
            width: _sidebarWidth,
            height: double.infinity,
            child: _Sidebar(currentLocation: location, width: _sidebarWidth),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.resizeColumn,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragUpdate: (details) {
                setState(() {
                  _sidebarWidth = (_sidebarWidth + details.delta.dx)
                      .clamp(_minSidebarWidth, _maxSidebarWidth);
                });
              },
              child: const SizedBox(
                width: 6,
                height: double.infinity,
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final String currentLocation;
  final double width;
  const _Sidebar({required this.currentLocation, required this.width});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SimulationProvider>();
    final nbAlertes = provider.nbNouvellesAlertes;
    return Container(
      width: width,
      height: double.infinity,
      color: AppColors.navy,
      child: Column(
        children: [
          _SidebarLogo(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/metier/dashboard',
                    currentLocation: currentLocation,
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.rule_outlined,
                    label: 'Règles',
                    route: '/metier/regles',
                    currentLocation: currentLocation,
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.notifications_active_outlined,
                    label: 'Alertes temps réel',
                    route: '/metier/alertes',
                    currentLocation: currentLocation,
                    badge: nbAlertes > 0 ? '$nbAlertes' : null,
                    onTap: () {
                      provider.marquerAlertesLues();
                      context.go('/metier/alertes');
                    },
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.history_outlined,
                    label: 'Historique demandes',
                    route: '/metier/historique-demandes',
                    currentLocation: currentLocation,
                  ),
                  const SizedBox(height: 4),
                  _NavItem(
                    icon: Icons.account_circle_outlined,
                    label: 'Mon profil',
                    route: '/metier/profil',
                    currentLocation: currentLocation,
                  ),
                ],
              ),
            ),
          ),
          _UserFooter(),
        ],
      ),
    );
  }
}

class _SidebarLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x14FFFFFF), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/pictures/FDXLogo1.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FlowDetectX',
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis),
                Text('ESPACE MÉTIER',
                    style: GoogleFonts.inter(
                        fontSize: 8,
                        color: Colors.white.withValues(alpha: 0.3),
                        letterSpacing: 1.2),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final String currentLocation;
  final String? badge;
  final bool badgeActif;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentLocation,
    this.badge,
    this.onTap,
  }) : badgeActif = false;

  bool get isActive => currentLocation == route;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap ?? () => context.go(route),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.success.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 3,
              height: 16,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isActive ? AppColors.success : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(icon,
                size: 17,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.45)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isActive
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.55),
                      fontWeight: isActive ? FontWeight.w500 : FontWeight.w400),
                  overflow: TextOverflow.ellipsis),
            ),
            // Badge nombre alertes
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(badge!,
                    style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            // Badge simulation active (point pulsant)
            if (badgeActif) _PulseBadge(),
          ],
        ),
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x14FFFFFF), width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.blueImf,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              auth.initiales.isEmpty ? 'UM' : auth.initiales,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // TODO: nom depuis GET /api/utilisateurs/moi
                  'Utilisateur Métier',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text('Utilisateur Métier',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.4))),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded,
                size: 16, color: Colors.white.withValues(alpha: 0.3)),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await context.read<AuthProvider>().deconnecter();
              if (context.mounted) context.go('/login');
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _PulseBadge extends StatefulWidget {
  @override
  State<_PulseBadge> createState() => _PulseBadgeState();
}

class _PulseBadgeState extends State<_PulseBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success.withValues(alpha: 0.5 + 0.5 * _ctrl.value),
        ),
      ),
    );
  }
}
