import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.uploading,
    required this.onChangePhoto,
  });

  final String? displayName;
  final String email;
  final String? avatarUrl;
  final bool uploading;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (displayName?.trim().isNotEmpty ?? false)
        ? displayName!.trim()
        : email.split('@').first;
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    final url = avatarUrl;

    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundImage:
                    url == null ? null : CachedNetworkImageProvider(url),
                child: Text(
                  initial,
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (uploading)
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                ),
              ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton.filled(
                iconSize: 18,
                visualDensity: VisualDensity.compact,
                onPressed: uploading ? null : onChangePhoto,
                icon: const Icon(Icons.photo_camera_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          name,
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 2),
        Text(
          email,
          style: AppFonts.label(
            size: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
