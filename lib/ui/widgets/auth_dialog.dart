import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_service.dart';
import '../theme/app_theme.dart';
import 'common.dart';

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key});

  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;

  String _friendlyError(Object e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-email':
          return 'That email address does not look right.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'email-already-in-use':
          return 'An account with this email already exists. Try signing in.';
        case 'weak-password':
          return 'Choose a stronger password (at least 6 characters).';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'No internet connection. Check your network and try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
      }
    }
    return 'Something went wrong. Please try again.';
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await action();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitEmailAuth() async {
    if (_isLoading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Enter your email and password.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }
    await _run(() async {
      if (_isSignUp) {
        await FirebaseService.signUpWithEmail(email, password);
      } else {
        await FirebaseService.signInWithEmail(email, password);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseService.currentUser;
    final isLoggedIn = currentUser != null && !currentUser.isAnonymous;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: isLoggedIn ? _buildProfile(currentUser) : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildProfile(User user) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.safe.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.verified_user_rounded, color: AppColors.safe, size: 32),
        ),
        const SizedBox(height: 16),
        const Text("You're signed in",
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        const SizedBox(height: 4),
        Text(user.email ?? '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.5, color: context.mutedText)),
        const SizedBox(height: 14),
        const StatusPill(
            label: 'Backup on', color: AppColors.safe, icon: Icons.cloud_done_outlined),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isLoading ? null : () => _run(FirebaseService.signOut),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(_isLoading ? 'Signing out…' : 'Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.danger,
              side: const BorderSide(color: AppColors.danger),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isSignUp ? 'Create your account' : 'Sign in',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        const SizedBox(height: 4),
        Text('Back up your scans and use them on any device.',
            style: TextStyle(fontSize: 14, color: context.mutedText)),
        const SizedBox(height: 20),
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage!,
                      style: const TextStyle(
                          color: AppColors.danger, fontSize: 13.5, height: 1.35)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          textInputAction: TextInputAction.done,
          autofillHints: [_isSignUp ? AutofillHints.newPassword : AutofillHints.password],
          onSubmitted: (_) => _submitEmailAuth(),
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              tooltip: _showPassword ? 'Hide password' : 'Show password',
              icon: Icon(
                  _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _isLoading ? null : _submitEmailAuth,
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(_isSignUp ? 'Create account' : 'Sign in'),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: _isLoading
                ? null
                : () => setState(() {
                      _isSignUp = !_isSignUp;
                      _errorMessage = null;
                    }),
            child: Text(_isSignUp
                ? 'Already have an account? Sign in'
                : 'New here? Create an account'),
          ),
        ),
        const Divider(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => _run(() async {
                  await FirebaseService.signInGuest();
                }),
            child: const Text('Continue as guest'),
          ),
        ),
      ],
    );
  }
}
