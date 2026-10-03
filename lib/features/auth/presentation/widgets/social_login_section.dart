import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/auth_form_cubit.dart';

/// "or" separator plus the Apple button, under the email form of the
/// login and register pages. Hidden when [AppConfig.socialLoginEnabled] is
/// false (the providers must also be enabled in the Supabase dashboard).
class SocialLoginSection extends StatelessWidget {
  const SocialLoginSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.socialLoginEnabled) return const SizedBox.shrink();
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final loading = context.select<AuthFormCubit, bool>(
      (cubit) => cubit.state.status.isLoading,
    );
    void signIn(SocialProvider provider) =>
        context.read<AuthFormCubit>().signInWithProvider(provider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l10n.orSeparator,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: loading ? null : () => signIn(SocialProvider.apple),
          icon: const Icon(Icons.apple, size: 22),
          label: Text(l10n.continueWithApple),
        ),
      ],
    );
  }
}

