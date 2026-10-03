import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomCtrl;
  late TextEditingController _prenomCtrl;
  late TextEditingController _emailCtrl;
  final _ancienMdpCtrl = TextEditingController();
  final _nouveauMdpCtrl = TextEditingController();
  final _confirmMdpCtrl = TextEditingController();

  bool _obscureAncien = true;
  bool _obscureNouveau = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  bool _saved = false;
  String? _erreurMdp;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _nomCtrl = TextEditingController(text: auth.nom ?? '');
    _prenomCtrl = TextEditingController(text: auth.prenom ?? '');
    _emailCtrl = TextEditingController(text: auth.email ?? '');
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _ancienMdpCtrl.dispose();
    _nouveauMdpCtrl.dispose();
    _confirmMdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sauvegarder() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nouveauMdpCtrl.text.isNotEmpty) {
      if (_ancienMdpCtrl.text.isEmpty) {
        setState(() => _erreurMdp = 'Saisissez votre mot de passe actuel.');
        return;
      }
      if (_nouveauMdpCtrl.text != _confirmMdpCtrl.text) {
        setState(() => _erreurMdp = 'Les mots de passe ne correspondent pas.');
        return;
      }
      if (_nouveauMdpCtrl.text.length < 8) {
        setState(() => _erreurMdp = 'Minimum 8 caractères requis.');
        return;
      }
    }

    setState(() {
      _isSaving = true;
      _erreurMdp = null;
      _saved = false;
    });

    final auth = context.read<AuthProvider>();
    final succes = await auth.mettreAJourProfil(
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      ancienMotDePasse:
          _ancienMdpCtrl.text.isNotEmpty ? _ancienMdpCtrl.text : null,
      nouveauMotDePasse:
          _nouveauMdpCtrl.text.isNotEmpty ? _nouveauMdpCtrl.text : null,
    );

    if (succes) {
      setState(() {
        _isSaving = false;
        _saved = true;
      });
      _ancienMdpCtrl.clear();
      _nouveauMdpCtrl.clear();
      _confirmMdpCtrl.clear();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _saved = false);
    } else {
      setState(() {
        _isSaving = false;
        _erreurMdp = 'Erreur lors de la mise à jour.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildTopbar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        _buildCarteInfosPersonnelles(),
                        const SizedBox(height: 16),
                        _buildCarteMotDePasse(),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: _buildCarteInfosCompte(auth),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopbar() {
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
              Text('Mon profil',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
              Text('Gérez vos informations personnelles',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          if (_saved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.3),
                    width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      size: 14, color: AppColors.success),
                  const SizedBox(width: 6),
                  Text('Profil mis à jour',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.success)),
                ],
              ),
            ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _sauvegarder,
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save_outlined, size: 16),
            label: Text(_isSaving ? 'Sauvegarde...' : 'Enregistrer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              textStyle: GoogleFonts.inter(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarteInfosPersonnelles() {
    return _Carte(
      titre: 'Informations personnelles',
      icon: Icons.person_outline_rounded,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _ChampTexte(
                        label: 'Prénom',
                        controller: _prenomCtrl,
                        hint: 'Votre prénom',
                        validateur: (v) =>
                            v!.trim().isEmpty ? 'Champ requis' : null)),
                const SizedBox(width: 16),
                Expanded(
                    child: _ChampTexte(
                        label: 'Nom',
                        controller: _nomCtrl,
                        hint: 'Votre nom',
                        validateur: (v) =>
                            v!.trim().isEmpty ? 'Champ requis' : null)),
              ],
            ),
            const SizedBox(height: 16),
            _ChampTexte(
              label: 'Adresse email',
              controller: _emailCtrl,
              hint: 'votre@email.bj',
              clavier: TextInputType.emailAddress,
              validateur: (v) {
                if (v!.trim().isEmpty) return 'Champ requis';
                if (!v.contains('@')) return 'Email invalide';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarteMotDePasse() {
    return _Carte(
      titre: 'Modifier le mot de passe',
      icon: Icons.lock_outline_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_erreurMdp != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.dangerLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.2), width: 0.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 14, color: AppColors.danger),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(_erreurMdp!,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: AppColors.danger))),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          _ChampMotDePasse(
              label: 'Mot de passe actuel',
              controller: _ancienMdpCtrl,
              obscure: _obscureAncien,
              onToggle: () => setState(() => _obscureAncien = !_obscureAncien)),
          const SizedBox(height: 14),
          _ChampMotDePasse(
              label: 'Nouveau mot de passe',
              controller: _nouveauMdpCtrl,
              obscure: _obscureNouveau,
              onToggle: () =>
                  setState(() => _obscureNouveau = !_obscureNouveau),
              hint: 'Minimum 8 caractères'),
          const SizedBox(height: 14),
          _ChampMotDePasse(
              label: 'Confirmer le nouveau mot de passe',
              controller: _confirmMdpCtrl,
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm)),
          const SizedBox(height: 8),
          Text('Laissez vide pour ne pas modifier le mot de passe.',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildCarteInfosCompte(AuthProvider auth) {
    return _Carte(
      titre: 'Informations du compte',
      icon: Icons.badge_outlined,
      child: Column(
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.blueImf,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    auth.initiales.isEmpty ? '??' : auth.initiales,
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                Text(auth.nomComplet.isEmpty ? 'Utilisateur' : auth.nomComplet,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.blueImf.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(auth.roleLabel.isEmpty ? '-' : auth.roleLabel,
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.blueImf)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 16),
          _InfoNonModifiable(
              label: 'Identifiant',
              valeur: auth.identifiant ?? '-',
              icon: Icons.alternate_email_rounded),
          const SizedBox(height: 12),
          _InfoNonModifiable(
              label: 'Rôle',
              valeur: auth.roleLabel.isEmpty ? '-' : auth.roleLabel,
              icon: Icons.manage_accounts_outlined),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        'L\'identifiant et le rôle ne peuvent pas être modifiés.',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Composants ───────────────────────────────────────────────────────────────

class _Carte extends StatelessWidget {
  final String titre;
  final IconData icon;
  final Widget child;
  const _Carte({required this.titre, required this.icon, required this.child});

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
                Text(titre,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

class _ChampTexte extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validateur;
  final TextInputType? clavier;
  const _ChampTexte(
      {required this.label,
      required this.controller,
      required this.hint,
      this.validateur,
      this.clavier});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: clavier,
          validator: validateur,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 0.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 0.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.blueImf, width: 1)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.danger, width: 1)),
          ),
        ),
      ],
    );
  }
}

class _ChampMotDePasse extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? hint;
  const _ChampMotDePasse(
      {required this.label,
      required this.controller,
      required this.obscure,
      required this.onToggle,
      this.hint});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.inter(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint ?? '••••••••',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: AppColors.surface,
            suffixIcon: IconButton(
              icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 17,
                  color: AppColors.textSecondary),
              onPressed: onToggle,
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 0.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.border, width: 0.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: AppColors.blueImf, width: 1)),
          ),
        ),
      ],
    );
  }
}

class _InfoNonModifiable extends StatelessWidget {
  final String label;
  final String valeur;
  final IconData icon;
  const _InfoNonModifiable(
      {required this.label, required this.valeur, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: AppColors.textSecondary))),
        Text(valeur,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary)),
      ],
    );
  }
}
