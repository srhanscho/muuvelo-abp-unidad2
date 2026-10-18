import 'package:flutter/material.dart';

import '../models/money.dart';
import '../utils/constants.dart';

/// ConfirmCloseDialog: [AlertDialog] that asks before closing the account.
///
/// If someone has not paid it warns about it, but still lets the host close
/// (PRD section 6: closing incomplete is a valid state). It answers `true`
/// (close) or `false`/null (cancel) through `Navigator.pop`.
///
/// Parameters:
/// - [unpaidNames]: people who have not paid (empty = everyone paid).
/// - [pendingAmount]: pesos still missing.
///
/// Used in: ResultsScreen ("Cerrar cuenta" button), with two
/// configurations: everybody paid / someone is missing.
class ConfirmCloseDialog extends StatelessWidget {
  const ConfirmCloseDialog({super.key, required this.unpaidNames, required this.pendingAmount});

  final List<String> unpaidNames;
  final int pendingAmount;

  @override
  Widget build(BuildContext context) {
    final complete = unpaidNames.isEmpty;
    return AlertDialog(
      icon: Icon(
        complete ? Icons.check_circle_outline : Icons.warning_amber_rounded,
        color: complete ? AppColors.success : AppColors.pending,
        size: 36,
      ),
      title: const Text('¿Cerrar la cuenta?'),
      content: Text(
        complete
            ? 'Todos pagaron. Al cerrar ya no podrás cambiar los pagos.'
            : 'Falta por pagar: ${unpaidNames.join(', ')} '
                  '(${formatPesos(pendingAmount)}).\n\n'
                  'Puedes cerrar igual con lo recogido; ya no podrás cambiar los pagos.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(complete ? 'Cerrar' : 'Cerrar igual'),
        ),
      ],
    );
  }
}
