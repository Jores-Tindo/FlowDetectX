import 'package:flowdetectx/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifiantController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _identifiantController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final succes = await auth.login(
      _identifiantController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (succes) {
      context.go(auth.routeInitiale);
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = auth.erreur ?? 'Identifiant ou mot de passe incorrect.';
      });
    }
  }

  void _ouvrirDialogueMotDePasseOublie() {
    final emailCtrl = TextEditingController();
    bool envoiEnCours = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text('Mot de passe oublié',
              style:
                  GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saisissez votre adresse email. Si un compte existe, un lien de réinitialisation vous sera envoyé.',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'adresse@imf.bj',
                  prefixIcon: Icon(Icons.email_outlined, size: 18),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Annuler',
                  style: GoogleFonts.inter(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: envoiEnCours
                  ? null
                  : () async {
                      if (emailCtrl.text.trim().isEmpty ||
                          !emailCtrl.text.contains('@')) return;
                      setDialogState(() => envoiEnCours = true);

                      final result = await AuthService()
                          .motDePasseOublie(emailCtrl.text.trim());

                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                          result['success'] == true
                              ? 'Si un compte existe pour cet email, un lien de réinitialisation vient d\'être envoyé.'
                              : (result['message'] ??
                                  'Une erreur est survenue.'),
                        ),
                        backgroundColor: result['success'] == true
                            ? AppColors.success
                            : AppColors.danger,
                        behavior: SnackBarBehavior.floating,
                      ));
                    },
              child: envoiEnCours
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: Row(
        children: [
          // Panneau gauche branding
          Expanded(flex: 5, child: _LeftPanel()),

          // Panneau droit formulaire
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.surface,
              height: double.infinity,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Container(
                        width: 600,
                        padding: const EdgeInsets.all(60),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: AppColors.border, width: 0.5),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    'assets/pictures/FDXlogo.png',
                                    width: 60,
                                    height: 60,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'FlowDetectX',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Analysez vos transactions',
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                            letterSpacing: 0.5,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 32),
                              Text(
                                'Connexion',
                                style: GoogleFonts.inter(
                                  fontSize: 29,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Accédez à votre espace de travail',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 28),
                              if (_errorMessage != null) ...[
                                _ErrorBanner(message: _errorMessage!),
                                const SizedBox(height: 16),
                              ],
                              const _FieldLabel(label: 'Identifiant'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _identifiantController,
                                style: GoogleFonts.inter(fontSize: 15),
                                decoration: const InputDecoration(
                                  hintText: 'Votre identifiant',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    size: 21,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Veuillez saisir votre identifiant';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _handleLogin(),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const _FieldLabel(label: 'Mot de passe'),
                                  TextButton(
                                    onPressed: _ouvrirDialogueMotDePasseOublie,
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Mot de passe oublié ?',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.blueImf,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: GoogleFonts.inter(fontSize: 15),
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 21,
                                    color: AppColors.textSecondary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 21,
                                      color: AppColors.textSecondary,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez saisir votre mot de passe';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _handleLogin(),
                              ),
                              const SizedBox(height: 28),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'Se connecter',
                                          style: GoogleFonts.inter(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Divider(
                                  color: AppColors.borderLight, height: 1),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.shield_outlined,
                                    size: 15,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Votre connexion est sécurisée · Session chiffrée JWT',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Panneau gauche ───────────────────────────────────────────────────────────

class _LeftPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy,
      padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 48),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/pictures/FDXLogo1.png',
              width: 300,
              height: 300,
            ),

            // Nom du logiciel juste sous le logo, "X" en bleu
            RichText(
              text: TextSpan(
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
                children: [
                  const TextSpan(text: 'FlowDetect'),
                  TextSpan(
                    text: 'X',
                    style: TextStyle(color: AppColors.blueImf),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'Surveillez et\ndétectez les\nanomalies dans\n vos flux financiers',
              style: GoogleFonts.inter(
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.2,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'FlowDetectX est un logiciel developpé pour optimiser\n la détection des transactions suspectes au sein de votre IMF.',
              style: GoogleFonts.inter(
                fontSize: 17,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.7,
              ),
            ),

            const SizedBox(height: 48),

            // Séparateur discret
            Container(
              width: double.infinity,
              height: 2,
              color: Colors.white.withValues(alpha: 0.12),
            ),

            const SizedBox(height: 32),

            const _FeaturePoint(
              icon: Icons.manage_search_rounded,
              text:
                  'Analyse automatique des flux financiers via un moteur de règles',
            ),
            const SizedBox(height: 16),
            const _FeaturePoint(
              icon: Icons.notifications_active_outlined,
              text: 'Alertes en temps réel sur les transactions à risque',
            ),
            const SizedBox(height: 16), const SizedBox(height: 25),

            const _FeaturePoint(
              icon: Icons.verified_user_outlined,
              text: 'Workflow de validation par les équipes de conformité',
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeaturePoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, size: 28, color: Colors.white.withValues(alpha: 0.55)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 11),
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Composants utilitaires ───────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dangerLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFFA32D2D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
