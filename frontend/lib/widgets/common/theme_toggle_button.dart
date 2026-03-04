import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ws_seeker_frontend/l10n/app_localizations.dart';
import '../../blocs/theme/theme_cubit.dart';

/// A compact icon button that cycles through theme modes: system → light → dark.
/// Place in AppBar actions or navigation areas for global visibility.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final (icon, tooltip) = switch (mode) {
          ThemeMode.system => (Icons.brightness_auto, l10n.themeSystem),
          ThemeMode.light => (Icons.light_mode, l10n.themeLight),
          ThemeMode.dark => (Icons.dark_mode, l10n.themeDark),
        };
        return IconButton(
          icon: Icon(icon),
          tooltip: tooltip,
          onPressed: () => context.read<ThemeCubit>().toggle(),
        );
      },
    );
  }
}
