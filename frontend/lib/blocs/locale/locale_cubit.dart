import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cubit for locale switching with SharedPreferences persistence.
class LocaleCubit extends Cubit<Locale> {
  static const _key = 'preferred_locale';

  LocaleCubit() : super(const Locale('en')) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      emit(Locale(value));
    }
  }

  Future<void> setLocale(Locale locale) async {
    emit(locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }

  /// Called on login to sync locale from the user's server-side preference.
  void setFromUserPreference(String? preferredLocale) {
    if (preferredLocale != null && preferredLocale.isNotEmpty) {
      setLocale(Locale(preferredLocale));
    }
  }
}
