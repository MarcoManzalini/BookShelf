import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../widgets/welcome_illustration.dart';

/// First screen for a signed-out reader: three slides that say what the app
/// does, then either create an account or sign in.
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  static const _slideCount = 3;

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isFirst => _page == 0;
  bool get _isLast => _page == _slideCount - 1;

  void _goTo(int page) => _controller.animateToPage(
        page,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // The tour: "Start" opens it, "Next" goes on, and the last slide hands
    // over to sign-up / sign-in. "Skip" jumps straight to that last slide.
    final primaryLabel =
        _isFirst || _isLast ? l10n.welcomeStart : l10n.welcomeNext;
    final secondaryLabel = _isFirst
        ? l10n.welcomeHaveAccount
        : (_isLast ? l10n.welcomeSignIn : l10n.welcomeSkip);
    final slides = [
      _Slide(
        art: const WelcomeIllustration(asset: WelcomeIllustration.mascot),
        title: 'BookShelf',
        body: l10n.welcomeTagline,
      ),
      _Slide(
        art: const WelcomeIllustration(asset: WelcomeIllustration.find),
        title: l10n.welcomeTitleFind,
        body: l10n.welcomeBodyFind,
      ),
      _Slide(
        art: const WelcomeIllustration(asset: WelcomeIllustration.track),
        title: l10n.welcomeTitleTrack,
        body: l10n.welcomeBodyTrack,
      ),
    ];
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (page) => setState(() => _page = page),
                    children: slides,
                  ),
                ),
                const SizedBox(height: 20),
                _PageDots(count: _slideCount, current: _page),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: _isLast
                            ? () => context.push(AppRoutes.register)
                            : () => _goTo(_page + 1),
                        child: Text(primaryLabel),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _isFirst || _isLast
                            ? () => context.push(AppRoutes.login)
                            : () => _goTo(_slideCount - 1),
                        child: Text(secondaryLabel),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One page of the welcome flow: a picture on top, title and a line under it.
class _Slide extends StatelessWidget {
  const _Slide({required this.art, required this.title, required this.body});

  final Widget art;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 24),
              child: Center(child: art),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppFonts.text(
              size: 40,
              weight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1.5,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Same height on every slide, so the dots never jump.
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Page indicator of the welcome flow.
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final inactive = Theme.of(context).colorScheme.outlineVariant;
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == current ? AppColors.accent : inactive,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
