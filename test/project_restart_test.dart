import 'dart:convert';

import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Use a failing preferences store to exercise a native disk-write failure.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:voting_pro/main.dart';

const _projectKey = 'voting_pro_project_v1';
const _savedText = 'Existing poster';

class _FailingRemoveStore extends InMemorySharedPreferencesStore {
  _FailingRemoveStore(String project)
      : super.withData({'flutter.$_projectKey': project});

  @override
  Future<bool> remove(String key) async => false;
}

class _UnavailablePathProvider extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async {
    throw StateError('Project files unavailable');
  }
}

void main() {
  for (final outcome in ['Cancel', 'Restart', 'Storage failure']) {
    testWidgets('Restart project: $outcome', (tester) async {
      final project = jsonEncode({
        'overlays': [_savedText],
        'textOverlayIds': [0],
      });
      SharedPreferences.setMockInitialValues({_projectKey: project});
      if (outcome == 'Storage failure') {
        SharedPreferencesStorePlatform.instance = _FailingRemoveStore(project);
      }
      addTearDown(() => SharedPreferences.setMockInitialValues({}));

      final originalPathProvider = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _UnavailablePathProvider();
      addTearDown(() => PathProviderPlatform.instance = originalPathProvider);

      await tester.pumpWidget(const MaterialApp(home: Editor()));
      await tester.pumpAndSettle();
      expect(find.text(_savedText), findsOneWidget);
      final restart = find.text('Restart Project');
      await tester.ensureVisible(restart);
      await tester.tap(restart);
      await tester.pumpAndSettle();
      final confirmed = outcome != 'Cancel';
      await tester.tap(find.text(confirmed ? 'Restart' : 'Cancel'));
      await tester.pumpAndSettle();

      if (outcome == 'Restart') {
        expect(find.text(_savedText), findsNothing);
      } else {
        expect(find.text(_savedText), findsOneWidget);
      }
      if (outcome == 'Storage failure') {
        expect(
          find.text('Could not restart. Your current poster is still open.'),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
