import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:motorstock_mobile/app_config.dart';
import 'package:motorstock_mobile/supabase_backend.dart';

void main() {
  final email = Platform.environment['SUPABASE_TEST_EMAIL'] ?? '';
  final password = Platform.environment['SUPABASE_TEST_PASSWORD'] ?? '';
  final enabled =
      AppConfig.hasSupabaseValues && email.isNotEmpty && password.isNotEmpty;

  test('authenticated admin can load the MotorStock snapshot', () async {
    final repository = SupabaseMotorRepository(
      SupabaseClient(AppConfig.supabaseUrl, AppConfig.supabaseKey),
    );
    try {
      final profile = await repository.signIn(email, password);
      final snapshot = await repository.loadSnapshot();

      expect(profile.isAdmin, isTrue);
      expect(profile.name, isNotEmpty);
      expect(snapshot.branches, isNotEmpty);
      expect(snapshot.vehicles, isNotEmpty);
      expect(snapshot.staff, isNotEmpty);
    } finally {
      await repository.signOut();
      repository.client.dispose();
    }
  }, skip: enabled ? false : 'Supabase test credentials were not supplied.');
}
