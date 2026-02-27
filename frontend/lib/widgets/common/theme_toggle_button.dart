import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/theme/theme_cubit.dart';

/// A compact icon button that cycles through theme modes: system → light → dark.
/// Place in AppBar actions or navigation areas for global visibility.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) {
        final (icon, tooltip) = switch (mode) {
          ThemeMode.system => (Icons.brightness_auto, 'Theme: System'),
          ThemeMode.light => (Icons.light_mode, 'Theme: Light'),
          ThemeMode.dark => (Icons.dark_mode, 'Theme: Dark'),
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
