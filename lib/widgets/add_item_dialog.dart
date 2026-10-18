import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/money.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'custom_text_field.dart';

/// AddItemDialog: [AlertDialog] with a small form (description + price) to
/// add one item of the bill.
///
/// It returns the typed values with `Navigator.pop`, which is how every
/// Flutter dialog gives its answer back; it does NOT create the item or
/// touch the screen state. The screen decides what to do with the answer:
///
/// ```dart
/// final result = await showDialog<({String description, int price})>(
///   context: context, builder: (_) => const AddItemDialog());
/// ```
///
/// Used in: RegisterScreen ("Agregar ítem" button).
class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context)
        .pop((description: _descriptionController.text.trim(), price: parsePesos(_priceController.text)!));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar ítem'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Descripción',
                hint: 'Ej: Bandeja paisa',
                icon: Icons.restaurant_menu,
                controller: _descriptionController,
                validator: validateItemDescription,
                maxLength: Limits.maxItemDescription,
                textInputAction: TextInputAction.next,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Precio en pesos',
                hint: 'Ej: 26000',
                icon: Icons.attach_money,
                controller: _priceController,
                validator: validateItemPrice,
                keyboardType: TextInputType.number,
                // Only digits: no letters, no decimals (COP has no cents).
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 8,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
          onPressed: _submit,
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
