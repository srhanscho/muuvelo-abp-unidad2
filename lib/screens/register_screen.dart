import 'package:flutter/material.dart';

import '../models/bill_item.dart';
import '../models/participant.dart';
import '../models/vaca.dart';
import '../services/split_service.dart';
import '../services/vaca_store.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/add_item_dialog.dart';
import '../widgets/bill_item_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/host_dropdown.dart';
import '../widgets/participants_editor.dart';
import '../widgets/section_header.dart';
import '../widgets/summary_card.dart';
import '../widgets/tip_selector.dart';

/// Screen 2 - Pantalla de registro.
///
/// Captures the bill (restaurant, people, host, items, tip), validates it
/// and, when everything is correct, calculates the split and opens the
/// results. This screen is the "container": it owns the state and the
/// rules; the widgets it uses only draw and report taps.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.store});

  final VacaStore store;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantController = TextEditingController();
  final _nameController = TextEditingController();

  final List<Participant> _participants = [];
  final List<BillItem> _items = [];
  String? _hostId;
  String? _nameError;
  bool _tipEnabled = true;
  int _tipPercent = defaultTipPercent;
  int _lastId = 0;

  /// After the first "Calcular reparto" we also show inline errors.
  bool _submitted = false;

  int get _effectiveTip => _tipEnabled ? _tipPercent : 0;

  @override
  void initState() {
    super.initState();
    // Repaint the live preview title while the restaurant name is typed.
    _restaurantController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _restaurantController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String _newId(String prefix) => '$prefix${++_lastId}';

  // ---- Participants ----

  void _addParticipant() {
    final name = _nameController.text.trim();
    final error = validateParticipantName(name, _participants.map((p) => p.name).toList());
    setState(() {
      _nameError = error;
      if (error != null) return;
      final person = Participant(id: _newId('p'), name: name);
      _participants.add(person);
      // Convenience: the first person added is the host until changed.
      _hostId ??= person.id;
      _nameController.clear();
    });
  }

  void _removeParticipant(String id) {
    setState(() {
      _participants.removeWhere((p) => p.id == id);
      // Nobody can share an item with a person who left the table.
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(sharedBy: _items[i].sharedBy.where((s) => s != id).toList());
      }
      if (_hostId == id) _hostId = _participants.isEmpty ? null : _participants.first.id;
    });
  }

  // ---- Items ----

  Future<void> _addItem() async {
    final result = await showDialog<({String description, int price})>(
      context: context,
      builder: (_) => const AddItemDialog(),
    );
    if (result == null) return; // cancelled
    setState(() {
      _items.add(BillItem(id: _newId('i'), description: result.description, price: result.price));
    });
  }

  void _toggleSharer(int index, String participantId) {
    final item = _items[index];
    final sharers = item.sharedBy.contains(participantId)
        ? item.sharedBy.where((id) => id != participantId).toList()
        : [...item.sharedBy, participantId];
    setState(() => _items[index] = item.copyWith(sharedBy: sharers));
  }

  // ---- Submit ----

  void _submit() {
    setState(() => _submitted = true);
    final formValid = _formKey.currentState!.validate();

    // First problem found, in the same order as the form.
    final error =
        validateRestaurantName(_restaurantController.text) ??
        validateParticipantCount(_participants.length) ??
        validateHost(_hostId) ??
        validateItems(_items);

    if (!formValid || error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error ?? 'Revisa los campos marcados en rojo'),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }

    // Processing: the pure split function does the math.
    final result = calculateSplit(
      participants: _participants,
      items: _items,
      hostId: _hostId!,
      tipPercent: _effectiveTip,
    );
    final vaca = Vaca(
      id: widget.store.nextId(),
      restaurantName: _restaurantController.text.trim(),
      participants: List.of(_participants),
      hostId: _hostId!,
      items: List.of(_items),
      tipPercent: _effectiveTip,
      result: result,
    );
    widget.store.add(vaca);

    // Replace this screen: "back" from the results goes to home.
    Navigator.pushReplacementNamed(context, Routes.results, arguments: vaca.id);
  }

  @override
  Widget build(BuildContext context) {
    final preview = previewTotals(_items, _effectiveTip);
    final restaurant = _restaurantController.text.trim();
    final itemsError = _submitted ? validateItems(_items) : null;
    final countError = _submitted ? validateParticipantCount(_participants.length) : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Nueva vaca')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          // After the first submit, re-check each field while the user types,
          // so a red error disappears as soon as it is fixed.
          autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
          // SingleChildScrollView (not ListView) keeps EVERY field alive even
          // when scrolled off screen, so Form.validate() checks all of them
          // and their red error messages are not lost.
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SectionHeader('Restaurante'),
                CustomTextField(
                  label: 'Nombre del restaurante',
                  hint: 'Ej: La Fonda del Parque',
                  icon: Icons.storefront,
                  controller: _restaurantController,
                  validator: validateRestaurantName,
                  maxLength: Limits.maxRestaurantName,
                  textInputAction: TextInputAction.next,
                ),
                SectionHeader(
                  'Personas',
                  trailing: Text('${_participants.length}/${Limits.maxParticipants}'),
                ),
                ParticipantsEditor(
                  controller: _nameController,
                  participants: _participants,
                  errorText: _nameError ?? countError,
                  onAdd: _addParticipant,
                  onRemove: _removeParticipant,
                ),
                const SectionHeader('Anfitrión'),
                HostDropdown(
                  participants: _participants,
                  hostId: _hostId,
                  validator: validateHost,
                  onChanged: (id) => setState(() => _hostId = id),
                ),
                SectionHeader('La cuenta', trailing: Text('${_items.length} ítems')),
                for (var i = 0; i < _items.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: BillItemCard(
                      key: ValueKey(_items[i].id),
                      description: _items[i].description,
                      price: _items[i].price,
                      people: _participants,
                      selectedIds: _items[i].sharedBy,
                      showError: _submitted,
                      onToggle: (personId) => _toggleSharer(i, personId),
                      onDelete: () => setState(() => _items.removeAt(i)),
                    ),
                  ),
                if (itemsError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(itemsError, style: const TextStyle(color: AppColors.error)),
                  ),
                OutlinedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar ítem'),
                ),
                const SectionHeader('Propina'),
                TipSelector(
                  enabled: _tipEnabled,
                  percent: _tipPercent,
                  presets: tipPresets,
                  maxPercent: Limits.maxTipPercent,
                  onEnabledChanged: (value) => setState(() => _tipEnabled = value),
                  onPercentChanged: (value) => setState(() => _tipPercent = value),
                ),
                const SectionHeader('Vista previa'),
                SummaryCard(
                  title: restaurant.isEmpty ? 'Tu vaca' : restaurant,
                  subtitle: '${_participants.length} personas · ${_items.length} ítems',
                  subtotal: preview.subtotal,
                  tip: preview.tip,
                  tipPercent: _effectiveTip,
                  total: preview.total,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Calcular reparto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
