import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muuvelo_abp/utils/validators.dart';
import 'package:muuvelo_abp/widgets/avatar_initials.dart';
import 'package:muuvelo_abp/widgets/custom_text_field.dart';
import 'package:muuvelo_abp/widgets/glass_progress.dart';
import 'package:muuvelo_abp/widgets/money_text.dart';

/// Wraps a widget in the minimum app needed to render it.
Widget wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('CustomTextField', () {
    testWidgets('shows the label and the validator error', (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        wrap(
          Form(
            key: formKey,
            child: const CustomTextField(
              label: 'Restaurante',
              icon: Icons.storefront,
              validator: validateRestaurantName,
            ),
          ),
        ),
      );

      expect(find.text('Restaurante'), findsOneWidget);
      expect(find.byIcon(Icons.storefront), findsOneWidget);

      formKey.currentState!.validate();
      await tester.pump();
      expect(find.text('Escribe el nombre del restaurante'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField), 'La Fonda');
      expect(formKey.currentState!.validate(), isTrue);
    });

    testWidgets('input formatters block letters in a numeric field', (tester) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        wrap(
          CustomTextField(
            label: 'Precio',
            icon: Icons.attach_money,
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), '12a3');
      expect(controller.text, '123');
    });

    testWidgets('shows an external errorText', (tester) async {
      await tester.pumpWidget(
        wrap(const CustomTextField(label: 'Nombre', icon: Icons.person, errorText: 'Ana ya está en la mesa')),
      );
      expect(find.text('Ana ya está en la mesa'), findsOneWidget);
    });
  });

  group('GlassProgress', () {
    for (final percent in [0, 50, 100]) {
      testWidgets('renders $percent%', (tester) async {
        await tester.pumpWidget(wrap(GlassProgress(percent: percent)));
        await tester.pumpAndSettle();
        expect(find.text('$percent%'), findsOneWidget);
        expect(
          find.descendant(of: find.byType(GlassProgress), matching: find.byType(CustomPaint)),
          findsWidgets,
        );
      });
    }

    testWidgets('clamps values above 100', (tester) async {
      await tester.pumpWidget(wrap(const GlassProgress(percent: 140)));
      await tester.pumpAndSettle();
      expect(find.text('100%'), findsOneWidget);
    });
  });

  testWidgets('AvatarInitials shows the given initials', (tester) async {
    await tester.pumpWidget(wrap(const AvatarInitials(initials: 'JD')));
    expect(find.text('JD'), findsOneWidget);
  });

  testWidgets('MoneyText formats pesos with dot separators', (tester) async {
    await tester.pumpWidget(wrap(const MoneyText(79200)));
    expect(find.text(r'$ 79.200'), findsOneWidget);
  });
}
