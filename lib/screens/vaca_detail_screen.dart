import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/vaca.dart';
import '../services/vaca_sync_controller.dart';
import '../utils/constants.dart';
import '../utils/dates.dart';
import '../utils/design_tokens.dart';
import '../utils/error_messages.dart';
import '../widgets/collected_card.dart';
import '../widgets/confirm_dialogs.dart';
import '../widgets/grouped_section.dart';
import '../widgets/large_title_page.dart';
import '../widgets/money_text.dart';
import '../widgets/muuvelo_icon.dart';
import '../widgets/person_share_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_chip.dart';
import '../widgets/vaca_loader.dart';

/// Screen 4 - Detalle.
///
/// Everything about one vaca, read from the database: money summary,
/// items with who shared them, participants with amounts and paid state.
/// Actions: Editar, Eliminar and Gestionar cobro.
class VacaDetailScreen extends StatefulWidget {
  const VacaDetailScreen({super.key, required this.controller, required this.vacaId});

  final VacaSyncController controller;
  final String vacaId;

  @override
  State<VacaDetailScreen> createState() => _VacaDetailScreenState();
}

class _VacaDetailScreenState extends State<VacaDetailScreen> {
  bool _deleting = false;

  void _edit() => Navigator.pushNamed(context, Routes.edit, arguments: widget.vacaId);

  Future<void> _delete(Vaca vaca) async {
    final confirmed = await showConfirmDialog(
      context,
      title: '¿Eliminar la vaca de ${vaca.restaurantName}?',
      message: 'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _deleting = true);
    try {
      await widget.controller.delete(vaca.id);
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Vaca de ${vaca.restaurantName} eliminada')));
    } catch (e) {
      if (mounted) setState(() => _deleting = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(friendlyError(e)), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return VacaLoader(
      controller: widget.controller,
      vacaId: widget.vacaId,
      title: 'Detalle',
      previousPageTitle: 'Atrás',
      builder: (context, vaca) => LargeTitlePage(
        title: 'Detalle',
        previousPageTitle: 'Atrás',
        onRefresh: widget.controller.refresh,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _deleting ? null : _edit,
          child: const Text('Editar'),
        ),
        children: [
          _Header(vaca: vaca),
          const SizedBox(height: Space.l),
          CollectedCard(
            collected: vaca.collected,
            total: vaca.total,
            percent: vaca.percentCollected,
            paidCount: vaca.paidCount,
            peopleCount: vaca.participants.length,
            isClosed: vaca.isClosed,
          ),
          const SizedBox(height: Space.l),
          PrimaryButton(
            label: vaca.isClosed ? 'Ver cobro' : 'Gestionar cobro',
            icon: CupertinoIcons.money_dollar_circle,
            onPressed: _deleting ? null : () => Navigator.pushNamed(context, Routes.results, arguments: vaca.id),
          ),
          const SectionGap(),
          GroupedSection(
            header: 'La cuenta',
            children: [
              for (final item in vaca.items)
                GroupedRow(
                  title: item.description,
                  subtitle: Text(
                    item.sharedBy.length > 1
                        ? '${vaca.sharedByNames(item)} · 1/${item.sharedBy.length} cada uno'
                        : vaca.sharedByNames(item),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: MoneyText(item.price, style: AppText.money),
                ),
              _TotalsRow(label: 'Subtotal', pesos: vaca.subtotal),
              _TotalsRow(label: 'Propina (${vaca.effectiveTipPercent}%)', pesos: vaca.tip),
              _TotalsRow(label: 'Total', pesos: vaca.total, bold: true),
            ],
          ),
          const SectionGap(),
          GroupedSection(
            header: 'Quién paga qué',
            separatorInset: 72,
            children: [
              for (final person in vaca.participants)
                PersonShareCard(
                  name: person.name,
                  initials: person.initials,
                  amount: person.amount,
                  isHost: person.isHost,
                  isPaid: person.paid,
                  shares: vaca.sharesFor(person.id),
                  onPaidChanged: null, // read-only here; pay in Gestión
                ),
            ],
          ),
          const SectionGap(),
          GroupedSection(
            children: [
              GroupedRow(
                leading: const MuuveloIcon('edit', size: 22, fallback: CupertinoIcons.pencil, color: AppColors.primary),
                title: 'Editar vaca',
                titleStyle: AppText.body.copyWith(color: AppColors.primary),
                onTap: _deleting ? null : _edit,
              ),
              GroupedRow(
                leading: _deleting
                    ? const CupertinoActivityIndicator()
                    : const Icon(CupertinoIcons.trash, color: AppColors.error, size: 22),
                title: 'Eliminar vaca',
                titleStyle: AppText.body.copyWith(color: AppColors.error),
                showChevron: false,
                onTap: _deleting ? null : () => _delete(vaca),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.vaca});

  final Vaca vaca;

  @override
  Widget build(BuildContext context) {
    final host = vaca.participants.isEmpty ? null : vaca.host;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(vaca.restaurantName, style: AppText.title2),
        const SizedBox(height: Space.xs),
        Text(
          '${formatDateTime(vaca.createdAt)} · ${vaca.participants.length} personas'
          '${host == null ? '' : ' · anfitrión: ${host.name}'}',
          style: AppText.footnote,
        ),
        const SizedBox(height: Space.s),
        vaca.isClosed
            ? StatusChip.closed(
                label: vaca.closedAt == null ? 'Cerrada' : 'Cerrada el ${formatDateTime(vaca.closedAt!)}',
              )
            : const StatusChip.open(),
      ],
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.label, required this.pesos, this.bold = false});

  final String label;
  final int pesos;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? AppText.headline : AppText.body.copyWith(color: AppColors.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          MoneyText(pesos, style: bold ? AppText.money.copyWith(fontWeight: FontWeight.w700) : style),
        ],
      ),
    );
  }
}
