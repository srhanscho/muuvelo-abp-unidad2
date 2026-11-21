import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/bill_item.dart';
import '../models/participant.dart';
import '../models/vaca_draft.dart';
import '../services/split_service.dart';
import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import '../utils/validators.dart';
import 'bill_item_card.dart';
import 'custom_text_field.dart';
import 'grouped_section.dart';
import 'host_picker.dart';
import 'item_sheet.dart';
import 'large_title_page.dart';
import 'participants_editor.dart';
import 'primary_button.dart';
import 'summary_card.dart';
import 'tip_selector.dart';

/// VacaForm: the whole "bill" form (restaurant, people, host, items, tip,
/// live preview). Shared by Registro (empty) and Edición (pre-filled), so
/// both screens validate and look exactly the same.
///
/// It owns only the INPUT state. When everything is valid it gives a
/// [VacaDraft] to [onSubmit]; the screen decides what to do with it
/// (create or update in the database).
///
/// Parameters:
/// - [title] / [previousPageTitle]: texts of the large title bar.
/// - [initial]: draft to pre-fill (Edición) or null (Registro).
/// - [submitLabel] / [submitIcon]: main button.
/// - [onSubmit]: async; the button shows a spinner while it runs.
/// - [header]: optional widget shown above the form (e.g. a warning).
class VacaForm extends StatefulWidget {
  const VacaForm({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.submitIcon,
    this.initial,
    this.previousPageTitle,
    this.header,
  });

  final String title;
  final String? previousPageTitle;
  final VacaDraft? initial;
  final String submitLabel;
  final IconData? submitIcon;
  final Future<void> Function(VacaDraft draft) onSubmit;
  final Widget? header;

  @override
  State<VacaForm> createState() => _VacaFormState();
}

class _VacaFormState extends State<VacaForm> {
  final _formKey = GlobalKey<FormState>();
  late final _restaurantController = TextEditingController(text: widget.initial?.restaurantName);
  final _nameController = TextEditingController();

  late final List<Participant> _participants = List.of(widget.initial?.participants ?? const []);
  late final List<BillItem> _items = List.of(widget.initial?.items ?? const []);
  late String? _hostId = widget.initial?.hostId;
  late bool _tipEnabled = widget.initial?.tipEnabled ?? true;
  late int _tipPercent = widget.initial?.tipPercent ?? defaultTipPercent;
  String? _nameError;
  int _lastId = 0;
  bool _saving = false;

  /// After the first submit we also show inline errors.
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

  String _newId(String prefix) => 'local-$prefix${++_lastId}';

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

  Future<void> _renameParticipant(Participant person) async {
    final controller = TextEditingController(text: person.name);
    String? error;
    final newName = await showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => CupertinoAlertDialog(
          title: const Text('Cambiar nombre'),
          content: Padding(
            padding: const EdgeInsets.only(top: Space.m),
            child: Material(
              color: Colors.transparent,
              child: CustomTextField(
                label: 'Nombre',
                icon: CupertinoIcons.person,
                controller: controller,
                errorText: error,
                maxLength: Limits.maxParticipantName,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                final others = _participants.where((p) => p.id != person.id).map((p) => p.name).toList();
                final message = validateParticipantName(controller.text, others);
                if (message != null) {
                  setDialogState(() => error = message);
                  return;
                }
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (newName == null) return;
    setState(() {
      final index = _participants.indexWhere((p) => p.id == person.id);
      if (index >= 0) _participants[index] = person.copyWith(name: newName);
    });
  }

  // ---- Items ----

  Future<void> _addItem() async {
    // Drop focus first, otherwise the sheet restores it to the last text
    // field on close and the keyboard pops up over the list.
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showItemSheet(context);
    if (result == null) return; // cancelled
    setState(() => _items.add(BillItem(id: _newId('i'), description: result.description, price: result.price)));
  }

  Future<void> _editItem(int index) async {
    final item = _items[index];
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showItemSheet(context, description: item.description, price: item.price);
    if (result == null) return;
    setState(() => _items[index] = item.copyWith(description: result.description, price: result.price));
  }

  void _toggleSharer(int index, String participantId) {
    final item = _items[index];
    final sharers = item.sharedBy.contains(participantId)
        ? item.sharedBy.where((id) => id != participantId).toList()
        : [...item.sharedBy, participantId];
    setState(() => _items[index] = item.copyWith(sharedBy: sharers));
  }

  // ---- Submit ----

  Future<void> _submit() async {
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
          SnackBar(content: Text(error ?? 'Revisa los campos marcados en rojo'), backgroundColor: AppColors.error),
        );
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.onSubmit(
        VacaDraft(
          restaurantName: _restaurantController.text.trim(),
          participants: List.of(_participants),
          hostId: _hostId!,
          items: List.of(_items),
          tipEnabled: _tipEnabled,
          tipPercent: _tipPercent,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = previewTotals(_items, _effectiveTip);
    final restaurant = _restaurantController.text.trim();
    final itemsError = _submitted ? validateItems(_items) : null;
    final countError = _submitted ? validateParticipantCount(_participants.length) : null;

    return Form(
      key: _formKey,
      // After the first submit, re-check each field while the user types.
      autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      child: LargeTitlePage(
        title: widget.title,
        previousPageTitle: widget.previousPageTitle,
        bottomBar: PrimaryButton(
          label: widget.submitLabel,
          icon: widget.submitIcon,
          loading: _saving,
          onPressed: _submit,
        ),
        children: [
          if (widget.header != null) ...[widget.header!, const SectionGap(height: Space.xl)],
          GroupedSection(
            header: 'Restaurante',
            children: [
              Padding(
                padding: const EdgeInsets.all(Space.l),
                child: CustomTextField(
                  label: 'Nombre del restaurante',
                  hint: 'Ej: La Fonda del Parque',
                  icon: CupertinoIcons.house,
                  controller: _restaurantController,
                  validator: validateRestaurantName,
                  maxLength: Limits.maxRestaurantName,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SectionGap(),
          GroupedSection(
            header: 'Personas',
            trailingHeader: Text('${_participants.length}/${Limits.maxParticipants}', style: AppText.sectionHeader),
            footer: 'Toca un nombre para cambiarlo.',
            separatorInset: 64,
            children: [
              ParticipantsEditor(
                controller: _nameController,
                participants: _participants,
                hostId: _hostId,
                errorText: _nameError ?? countError,
                onAdd: _addParticipant,
                onRemove: _removeParticipant,
                onRename: _renameParticipant,
              ),
              HostPicker(
                participants: _participants,
                hostId: _hostId,
                onChanged: (id) => setState(() => _hostId = id),
              ),
            ],
          ),
          const SectionGap(),
          GroupedSection(
            header: 'La cuenta',
            trailingHeader: Text(
              '${_items.length} ${_items.length == 1 ? 'ítem' : 'ítems'}',
              style: AppText.sectionHeader,
            ),
            children: [
              for (var i = 0; i < _items.length; i++)
                BillItemCard(
                  key: ValueKey(_items[i].id),
                  description: _items[i].description,
                  price: _items[i].price,
                  people: _participants,
                  selectedIds: _items[i].sharedBy,
                  showError: _submitted,
                  onToggle: (personId) => _toggleSharer(i, personId),
                  onEdit: () => _editItem(i),
                  onDelete: () => setState(() => _items.removeAt(i)),
                ),
              GroupedRow(
                leading: const Icon(CupertinoIcons.add_circled_solid, color: AppColors.primary),
                title: 'Agregar ítem',
                titleStyle: AppText.body.copyWith(color: AppColors.primary),
                showChevron: false,
                onTap: _addItem,
              ),
            ],
          ),
          if (itemsError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
              child: Text(itemsError, style: AppText.footnote.copyWith(color: AppColors.error)),
            ),
          const SectionGap(),
          TipSelector(
            enabled: _tipEnabled,
            percent: _tipPercent,
            presets: tipPresets,
            maxPercent: Limits.maxTipPercent,
            onEnabledChanged: (value) => setState(() => _tipEnabled = value),
            onPercentChanged: (value) => setState(() => _tipPercent = value),
          ),
          const SectionGap(),
          SummaryCard(
            header: 'Vista previa',
            title: restaurant.isEmpty ? 'Tu vaca' : restaurant,
            subtitle:
                '${_participants.length} ${_participants.length == 1 ? 'persona' : 'personas'} · '
                '${_items.length} ${_items.length == 1 ? 'ítem' : 'ítems'}',
            subtotal: preview.subtotal,
            tip: preview.tip,
            tipPercent: _effectiveTip,
            total: preview.total,
          ),
        ],
      ),
    );
  }
}
