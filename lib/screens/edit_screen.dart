import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/vaca_draft.dart';
import '../services/vaca_sync_controller.dart';
import '../utils/constants.dart';
import '../utils/error_messages.dart';
import '../widgets/info_banner.dart';
import '../widgets/muuvelo_icon.dart';
import '../widgets/vaca_form.dart';
import '../widgets/vaca_loader.dart';

/// Screen 5 - Edición.
///
/// The same form as Registro, pre-filled with the saved vaca. On save the
/// split is recomputed and the database is updated (see
/// SupabaseVacaRepository.updateVaca for the strategy).
class EditScreen extends StatelessWidget {
  const EditScreen({super.key, required this.controller, required this.vacaId});

  final VacaSyncController controller;
  final String vacaId;

  Future<void> _save(BuildContext context, VacaDraft draft) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await controller.update(vacaId, draft);
      if (!context.mounted) return;
      Navigator.pop(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Cambios guardados y sincronizados')));
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return VacaLoader(
      controller: controller,
      vacaId: vacaId,
      title: 'Editar vaca',
      previousPageTitle: 'Detalle',
      builder: (context, vaca) => VacaForm(
        // A new key per vaca version: the form reads `initial` only once.
        key: ValueKey('edit-${vaca.id}'),
        title: 'Editar vaca',
        previousPageTitle: 'Detalle',
        initial: VacaDraft.fromVaca(vaca),
        submitLabel: 'Guardar cambios',
        submitIcon: CupertinoIcons.cloud_upload,
        header: vaca.paidCount > 0
            ? InfoBanner(
                icon: const MuuveloIcon('edit', size: 22, fallback: CupertinoIcons.info_circle_fill, color: AppColors.pending),
                title: 'Algunas personas ya pagaron',
                message: 'Si cambias precios o quién consumió qué, sus montos se recalculan. '
                    'Revisa los pagos después de guardar.',
                color: AppColors.pending,
                background: AppColors.pendingSoft,
              )
            : null,
        onSubmit: (draft) => _save(context, draft),
      ),
    );
  }
}
