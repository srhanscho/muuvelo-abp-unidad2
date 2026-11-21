import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/vaca_draft.dart';
import '../services/vaca_sync_controller.dart';
import '../utils/constants.dart';
import '../utils/error_messages.dart';
import '../widgets/vaca_form.dart';
import 'success_screen.dart';

/// Screen 3 - Registro.
///
/// Container: the shared [VacaForm] collects and validates the bill; this
/// screen saves it in Supabase (the controller computes nothing: the
/// draft carries the split from split_service) and shows the success
/// state.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key, required this.controller});

  final VacaSyncController controller;

  Future<void> _save(BuildContext context, VacaDraft draft) async {
    try {
      final vaca = await controller.create(draft);
      if (!context.mounted) return;
      // Replace this screen: "back" from the success state goes home.
      Navigator.pushReplacementNamed(
        context,
        Routes.success,
        arguments: SuccessArgs(vacaId: vaca.id, kind: SuccessKind.created),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return VacaForm(
      title: 'Nueva vaca',
      previousPageTitle: 'Atrás',
      submitLabel: 'Calcular y guardar',
      submitIcon: CupertinoIcons.checkmark_alt,
      onSubmit: (draft) => _save(context, draft),
    );
  }
}
