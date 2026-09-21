import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/errors/failure_message.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../library/domain/entities/reading_stats.dart';
import '../../../library/presentation/bloc/library_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../cubit/theme_cubit.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_shelves.dart';
import '../widgets/stats_row.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(const ProfileStarted()),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) =>
          previous.actionStatus != current.actionStatus &&
          (current.actionStatus.isSuccess || current.actionStatus.isFailure),
      listener: (context, state) {
        final message = state.actionStatus.isFailure
            ? failureMessage(l10n, state.failure!)
            : switch (state.action) {
                ProfileAction.updateName => l10n.profileUpdated,
                ProfileAction.updateAvatar => l10n.avatarUpdated,
                _ => null,
              };
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.profileTitle)),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state.profile == null) {
              if (state.status.isFailure && state.failure != null) {
                return ErrorView(
                  failure: state.failure!,
                  onRetry: () =>
                      context.read<ProfileBloc>().add(const ProfileStarted()),
                );
              }
              return const Center(child: CircularProgressIndicator());
            }
            return _ProfileBody(state: state);
          },
        ),
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.state});

  final ProfileState state;

  Future<void> _pickAvatar(BuildContext context) async {
    final bloc = context.read<ProfileBloc>();
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final ext = file.name.contains('.')
        ? file.name.split('.').last.toLowerCase()
        : 'jpg';
    const allowed = {'jpg', 'png', 'webp'};
    final normalized = ext == 'jpeg' ? 'jpg' : ext;
    bloc.add(
      ProfileAvatarSelected(
        bytes: bytes,
        extension: allowed.contains(normalized) ? normalized : 'jpg',
      ),
    );
  }

  Future<void> _editName(BuildContext context) async {
    final l10n = context.l10n;
    final bloc = context.read<ProfileBloc>();
    final controller = TextEditingController(text: state.profile?.displayName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.editDisplayName),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: l10n.displayNameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) {
      bloc.add(ProfileDisplayNameSubmitted(name));
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    final changed = await showChangePasswordDialog(context);
    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(context.l10n.passwordUpdated)));
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l10n = context.l10n;
    final authBloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (confirmed ?? false) authBloc.add(const AuthLogoutRequested());
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final bloc = context.read<ProfileBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(88, 44),
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteAccountConfirm),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(const ProfileDeleteAccountRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final profile = state.profile!;
    final email =
        context.select((AuthBloc bloc) => bloc.state.user?.email ?? '');
    final books = context.select((LibraryBloc bloc) => bloc.state.books);
    final themeMode = context.watch<ThemeCubit>().state;
    final busy = state.actionStatus.isLoading;
    final deleting = busy && state.action == ProfileAction.deleteAccount;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: [
        ProfileHeader(
          displayName: profile.displayName,
          email: email,
          avatarUrl: profile.avatarUrl,
          uploading: busy && state.action == ProfileAction.updateAvatar,
          onChangePhoto: () => _pickAvatar(context),
        ),
        const SizedBox(height: 24),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final profileBloc = context.read<ProfileBloc>();
            await context.push(AppRoutes.stats);
            // The goal may have been changed there.
            profileBloc.add(const ProfileRefreshRequested());
          },
          child: Column(
            children: [
              StatsRow(stats: ReadingStats.fromBooks(books)),
              _GoalHint(
                goal: profile.readingGoal,
                stats: ReadingStats.fromBooks(books),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const ProfileShelves(),
        if (context
            .select((LibraryBloc bloc) => bloc.state.shelfCounts.isNotEmpty))
          const SizedBox(height: 24),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(l10n.displayNameLabel),
                subtitle: Text(profile.displayName ?? '—'),
                trailing: const Icon(Icons.edit_outlined),
                onTap: busy ? null : () => _editName(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.mail_outline_rounded),
                title: Text(l10n.emailLabel),
                subtitle: Text(email),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.swap_vert_rounded),
                title: Text(l10n.ioProfileEntry),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.data),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_reset_rounded),
                title: Text(l10n.changePassword),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _changePassword(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.theme,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text(l10n.themeSystem),
                      ),
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text(l10n.themeLight),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text(l10n.themeDark),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (s) =>
                        context.read<ThemeCubit>().setThemeMode(s.first),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: Text(l10n.logout),
                onTap: busy ? null : () => _confirmLogout(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.delete_forever_outlined,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  l10n.deleteAccount,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                trailing: deleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: busy ? null : () => _confirmDelete(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One line under the counters: progress towards the yearly goal, or an
/// invitation to open the statistics.
class _GoalHint extends StatelessWidget {
  const _GoalHint({required this.goal, required this.stats});

  final int? goal;
  final ReadingStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final target = goal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: target == null
                ? Text(l10n.statsGoalSet, style: theme.textTheme.bodySmall)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.statsGoalProgress(stats.booksThisYear, target),
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (stats.booksThisYear / target).clamp(0.0, 1.0),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
