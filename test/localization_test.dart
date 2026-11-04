import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pawrescue_mobile/l10n/app_localizations.dart';

void main() {
  test('French, English, and Arabic strings are available', () {
    expect(AppLocalizations(const Locale('fr')).text('Animaux'), 'Animaux');
    expect(AppLocalizations(const Locale('en')).text('Animaux'), 'Animals');
    expect(AppLocalizations(const Locale('ar')).text('Animaux'), 'الحيوانات');
  });

  testWidgets('Arabic locale applies right-to-left text direction', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Text(
            Directionality.of(context).toString(),
            key: const ValueKey('text-direction'),
          ),
        ),
      ),
    );

    expect(find.text('TextDirection.rtl'), findsOneWidget);
  });
}
