import 'package:flutter/cupertino.dart';

import '../models/money.dart';

// Confirmation dialogs (iOS alert style). They answer `true` (confirm)
// or `false` (cancel) through `Navigator.pop`.

/// Generic confirmation. [destructive] paints the confirm action red
/// (Eliminar, Cerrar sesión).
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final answer = await showCupertinoDialog<bool>(
    context: context,
    builder: (dialogContext) => CupertinoAlertDialog(
      title: Text(title),
      content: Padding(padding: const EdgeInsets.only(top: 4), child: Text(message)),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          isDefaultAction: !destructive,
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return answer ?? false;
}

/// Before closing a vaca. If someone has not paid it warns about it but
/// still lets the host close (closing incomplete is a valid state).
Future<bool> showConfirmCloseDialog(
  BuildContext context, {
  required List<String> unpaidNames,
  required int pendingAmount,
}) {
  final complete = unpaidNames.isEmpty;
  return showConfirmDialog(
    context,
    title: '¿Cerrar la cuenta?',
    message: complete
        ? 'Todos pagaron. Al cerrar ya no podrás cambiar los pagos.'
        : 'Falta por pagar: ${unpaidNames.join(', ')} (${formatPesos(pendingAmount)}).\n\n'
              'Puedes cerrar igual con lo recogido; ya no podrás cambiar los pagos.',
    confirmLabel: complete ? 'Cerrar' : 'Cerrar igual',
  );
}
