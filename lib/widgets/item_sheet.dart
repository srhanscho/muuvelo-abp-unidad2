import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/money.dart';
import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import '../utils/validators.dart';
import 'custom_text_field.dart';
import 'primary_button.dart';

/// ItemSheet: bottom sheet (grabber + rounded top) with a small form to
/// add or edit one item of the bill.
///
/// It returns the typed values with `Navigator.pop`; it does NOT touch the
/// screen state. The screen decides what to do with the answer:
///
/// ```dart
/// final result = await showItemSheet(context);
/// ```
class ItemSheet extends StatefulWidget {
  const ItemSheet({super.key, this.initialDescription, this.initialPrice});

  final String? initialDescription;
  final int? initialPrice;

  @override
  State<ItemSheet> createState() => _ItemSheetState();
}

/// Opens the sheet; null means the user cancelled.
Future<({String description, int price})?> showItemSheet(
  BuildContext context, {
  String? description,
  int? price,
}) {
  return showModalBottomSheet<({String description, int price})>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ItemSheet(initialDescription: description, initialPrice: price),
  );
}

class _ItemSheetState extends State<ItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _descriptionController = TextEditingController(text: widget.initialDescription);
  late final _priceController = TextEditingController(text: widget.initialPrice?.toString());

  bool get _isEdit => widget.initialDescription != null;

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((description: _descriptionController.text.trim(), price: parsePesos(_priceController.text)!));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(Space.page, 0, Space.page, Space.xl),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(_isEdit ? 'Editar ítem' : 'Agregar ítem', style: AppText.title2)),
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
                ],
              ),
              const SizedBox(height: Space.l),
              CustomTextField(
                label: 'Descripción',
                hint: 'Ej: Bandeja paisa',
                icon: CupertinoIcons.text_cursor,
                controller: _descriptionController,
                validator: validateItemDescription,
                maxLength: Limits.maxItemDescription,
                textInputAction: TextInputAction.next,
                autofocus: !_isEdit,
              ),
              const SizedBox(height: Space.l),
              CustomTextField(
                label: 'Precio en pesos',
                hint: 'Ej: 26000',
                icon: CupertinoIcons.money_dollar,
                controller: _priceController,
                validator: validateItemPrice,
                keyboardType: TextInputType.number,
                // Only digits: no letters, no decimals (COP has no cents).
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 8,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Space.xl),
              PrimaryButton(label: _isEdit ? 'Guardar ítem' : 'Agregar', onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}
