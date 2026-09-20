import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../cubit/auth_form_cubit.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/password_field.dart';
import '../widgets/submit_button.dart';

/// Shown after the user opens the recovery link from the reset email.
class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthFormCubit>(),
      child: const _ResetPasswordView(),
    );
  }
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView();

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthFormCubit>().updatePassword(_password.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<AuthFormCubit, AuthFormState>(
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.status.isFailure && state.failure != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(failureMessage(l10n, state.failure!))),
            );
        } else if (state.result == AuthFormResult.passwordUpdated) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.passwordUpdated)));
          // The router guard leaves this page on the resulting auth event.
        }
      },
      child: AuthScaffold(
        title: l10n.resetPasswordTitle,
        subtitle: l10n.resetPasswordSubtitle,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PasswordField(
                controller: _password,
                label: l10n.newPasswordLabel,
                validator: Validators.password(l10n),
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 16),
              PasswordField(
                controller: _confirm,
                label: l10n.confirmPasswordLabel,
                validator:
                    Validators.confirmPassword(l10n, () => _password.text),
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: _submit,
              ),
              const SizedBox(height: 24),
              BlocBuilder<AuthFormCubit, AuthFormState>(
                builder: (context, state) => SubmitButton(
                  label: l10n.updatePasswordButton,
                  loading: state.status.isLoading,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
                child: Text(l10n.cancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
