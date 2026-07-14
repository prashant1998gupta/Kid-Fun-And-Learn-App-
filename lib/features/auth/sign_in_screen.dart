import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'auth_controller.dart';
import 'data/auth_service.dart';

/// Parent sign-in. Reached from the parent dashboard (behind the parent gate),
/// never surfaced to children. Cloud sign-in is entirely optional — the app is
/// fully playable offline, so this screen leads with that reassurance.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(authControllerProvider.notifier);

    // Pop back to the dashboard once signed in.
    ref.listen(authControllerProvider, (prev, next) {
      if (next.status == AuthStatus.signedIn && context.canPop()) {
        context.pop();
      }
    });

    final showApple = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    return Scaffold(
      appBar: AppBar(title: const Text('Parent Account')),
      body: AbsorbPointer(
        absorbing: auth.busy,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const _CloudBlurb(),
            if (!auth.cloudEnabled) const _OfflineNotice(),
            const SizedBox(height: 16),

            // Email / password.
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: auth.busy ? null : _submitEmail,
              child: Text(_register ? 'Create account' : 'Sign in'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _register = !_register),
                child: Text(
                  _register
                      ? 'Have an account? Sign in'
                      : 'New here? Create an account',
                ),
              ),
            ),
            if (!_register)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => controller.sendPasswordReset(_email.text),
                  child: const Text('Forgot password?'),
                ),
              ),

            const _OrDivider(),

            _ProviderButton(
              icon: Icons.g_mobiledata_rounded,
              label: 'Continue with Google',
              color: const Color(0xFFDB4437),
              onTap: auth.busy ? null : controller.signInWithGoogle,
            ),
            if (showApple) ...[
              const SizedBox(height: 12),
              _ProviderButton(
                icon: Icons.apple_rounded,
                label: 'Continue with Apple',
                color: Colors.black,
                onTap: auth.busy ? null : controller.signInWithApple,
              ),
            ],
            const SizedBox(height: 12),
            _ProviderButton(
              icon: Icons.sms_outlined,
              label: 'Continue with Phone',
              color: AppColors.success,
              onTap: auth.busy ? null : _startPhone,
            ),

            if (auth.busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            if (auth.error != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(
                message: auth.error!,
                onDismiss: controller.clearError,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submitEmail() async {
    final controller = ref.read(authControllerProvider.notifier);
    if (_register) {
      await controller.registerWithEmail(_email.text, _password.text);
    } else {
      await controller.signInWithEmail(_email.text, _password.text);
    }
  }

  Future<void> _startPhone() async {
    final service = ref.read(authServiceProvider);
    final controller = ref.read(authControllerProvider.notifier);
    final phone = await _prompt('Phone number', 'e.g. +15551234567',
        keyboard: TextInputType.phone);
    if (phone == null || phone.trim().isEmpty || !mounted) return;

    controller.clearError();
    try {
      await service.startPhoneSignIn(
        phone,
        onCodeSent: (verificationId) async {
          if (!mounted) return;
          final code = await _prompt('Enter the SMS code', '6-digit code',
              keyboard: TextInputType.number);
          if (code == null || code.trim().isEmpty) return;
          await controller.confirmSmsCode(verificationId, code);
        },
        onAutoVerified: (_) {/* stream flips to signedIn */},
        onError: (e) => _showError(e.message),
      );
    } on AuthException catch (e) {
      _showError(e.message);
    }
  }

  Future<String?> _prompt(String title, String hint,
      {TextInputType? keyboard}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        scrollable: true,
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: keyboard,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CloudBlurb extends StatelessWidget {
  const _CloudBlurb();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Save & sync progress',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          'Sign in to back up your children\'s progress to the cloud and pick '
          'up on any device. Totally optional — everything works offline too.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _OfflineNotice extends StatelessWidget {
  const _OfflineNotice();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.15),
          borderRadius: const BorderRadius.all(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_rounded, color: AppColors.warning),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Cloud accounts aren\'t configured in this build. You can keep '
                'playing — everything is saved on this device.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap == null ? null : () => onTap!(),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        alignment: Alignment.centerLeft,
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(child: Divider()),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text('or'),
          ),
          Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});
  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.all(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
