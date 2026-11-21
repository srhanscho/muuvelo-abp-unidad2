import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/money.dart';
import '../models/participant.dart';
import '../models/vaca.dart';
import '../services/vaca_sync_controller.dart';
import '../utils/constants.dart';
import '../utils/design_tokens.dart';
import '../utils/error_messages.dart';
import '../widgets/collected_card.dart';
import '../widgets/confirm_dialogs.dart';
import '../widgets/grouped_section.dart';
import '../widgets/info_banner.dart';
import '../widgets/large_title_page.dart';
import '../widgets/person_share_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/vaca_loader.dart';
import 'success_screen.dart';

/// Screen 6 - Gestión de cobro (main feature).
///
/// The glass fills as the host marks who paid; every switch is saved in
/// Supabase (participantes.paid / paid_at) and re-read. Closing sets
/// status = 'cerrada' and closed_at.
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.controller, required this.vacaId});

  final VacaSyncController controller;
  final String vacaId;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  /// Participants whose change is being saved (spinner instead of switch).
  final Set<String> _saving = {};
  bool _closing = false;

  void _show(String text, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), backgroundColor: error ? AppColors.error : null));
  }

  Future<void> _togglePaid(Participant person, bool paid) async {
    HapticFeedback.lightImpact();
    setState(() => _saving.add(person.id));
    try {
      await widget.controller.setPaid(person.id, paid);
      _show(paid ? '${person.name} pagó ${formatPesos(person.amount)}' : '${person.name} quedó pendiente');
    } catch (e) {
      _show(friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving.remove(person.id));
    }
  }

  Future<void> _confirmClose(Vaca vaca) async {
    final confirmed = await showConfirmCloseDialog(
      context,
      unpaidNames: vaca.unpaid.map((p) => p.name).toList(),
      pendingAmount: vaca.pending,
    );
    if (!confirmed || !mounted) return;
    setState(() => _closing = true);
    try {
      await widget.controller.close(vaca.id);
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      Navigator.pushNamed(context, Routes.success, arguments: SuccessArgs(vacaId: vaca.id, kind: SuccessKind.closed));
    } catch (e) {
      _show(friendlyError(e), error: true);
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VacaLoader(
      controller: widget.controller,
      vacaId: widget.vacaId,
      title: 'Cobro',
      previousPageTitle: 'Atrás',
      builder: (context, vaca) => LargeTitlePage(
        title: 'Cobro',
        previousPageTitle: 'Atrás',
        onRefresh: widget.controller.refresh,
        bottomBar: vaca.isClosed
            ? null
            : PrimaryButton(
                label: 'Cerrar cuenta',
                icon: CupertinoIcons.lock,
                loading: _closing,
                background: AppColors.gold,
                foreground: AppColors.ink,
                onPressed: () => _confirmClose(vaca),
              ),
        children: [
          Text(vaca.restaurantName, style: AppText.title2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: Space.l),
          CollectedCard(
            collected: vaca.collected,
            total: vaca.total,
            percent: vaca.percentCollected,
            paidCount: vaca.paidCount,
            peopleCount: vaca.participants.length,
            isClosed: vaca.isClosed,
          ),
          if (vaca.isClosed) ...[
            const SizedBox(height: Space.l),
            InfoBanner(
              icon: const Icon(CupertinoIcons.checkmark_seal_fill),
              title: 'La vaca quedó cerrada',
              message: vaca.pending == 0
                  ? 'Todos pagaron su parte.'
                  : 'Se cerró con lo recogido. Faltó ${formatPesos(vaca.pending)}.',
              color: AppColors.success,
              background: AppColors.successSoft,
            ),
          ],
          const SectionGap(),
          GroupedSection(
            header: 'Quién paga qué',
            footer: vaca.isClosed ? null : 'Activa el interruptor cuando alguien te pague.',
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
                  saving: _saving.contains(person.id),
                  // A closed vaca cannot change: null hides the switch.
                  onPaidChanged: vaca.isClosed || _saving.contains(person.id)
                      ? null
                      : (paid) => _togglePaid(person, paid),
                ),
            ],
          ),
          const SizedBox(height: Space.l),
          PlainButton(
            label: 'Compartir resumen',
            icon: CupertinoIcons.share,
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: vaca.toSummaryText(), subject: 'Muuvelo · ${vaca.restaurantName}'),
            ),
          ),
        ],
      ),
    );
  }
}
