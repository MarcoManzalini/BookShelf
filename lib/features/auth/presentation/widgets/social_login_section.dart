import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../domain/repositories/auth_repository.dart';
import '../cubit/auth_form_cubit.dart';

/// Google/Apple buttons. Hidden until [AppConfig.socialLoginEnabled] is true
/// (the providers must also be enabled in the Supabase dashboard).
class SocialLoginSection extends StatelessWidget {
  const SocialLoginSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.socialLoginEnabled) return const SizedBox.shrink();
    final l10n = context.l10n;
    final cubit = context.read<AuthFormCubit>();
    return Column(
      children: [
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => cubit.signInWithProvider(SocialProvider.google),
          child: Text(l10n.continueWithGoogle),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () => cubit.signInWithProvider(SocialProvider.apple),
          child: Text(l10n.continueWithApple),
        ),
      ],
    );
  }
}
