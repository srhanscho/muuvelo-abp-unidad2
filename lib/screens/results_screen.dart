import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/money.dart';
import '../models/participant.dart';
import '../models/vaca.dart';
import '../services/vaca_store.dart';
import '../utils/constants.dart';
import '../widgets/collected_card.dart';
import '../widgets/confirm_close_dialog.dart';
import '../widgets/info_banner.dart';
import '../widgets/person_share_card.dart';
import '../widgets/section_header.dart';
import '../widgets/summary_card.dart';

/// Screen 3 - Pantalla de consulta y resultados.
///
/// Shows how much each person owes, lets the host mark who paid (the glass
/// fills up live) and close the account or copy a summary.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.store, required this.vacaId});

  final VacaStore store;
  final String vacaId;

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  void _togglePaid(BuildContext context, Vaca vaca, Participant person, bool paid) {
    store.setPaid(vaca.id, person.id, paid);
    HapticFeedback.lightImpact(); // small vibration as feedback
    _showMessage(
      context,
      paid
          ? '${person.name} pagó ${formatPesos(vaca.result.amountFor(person.id))}'
          : '${person.name} quedó pendiente',
    );
  }

  Future<void> _confirmClose(BuildContext context, Vaca vaca) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmCloseDialog(
        unpaidNames: vaca.unpaid.map((p) => p.name).toList(),
        pendingAmount: vaca.pending,
      ),
    );
    if (confirmed != true || !context.mounted) return;
    store.close(vaca.id);
    HapticFeedback.mediumImpact();
    _showMessage(context, 'Cuenta cerrada con ${formatPesos(vaca.collected)}');
  }

  Future<void> _copySummary(BuildContext context, Vaca vaca) async {
    await Clipboard.setData(ClipboardData(text: vaca.toSummaryText()));
    if (context.mounted) _showMessage(context, 'Resumen copiado. Pégalo en el chat del grupo');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final vaca = store.byId(vacaId);
        if (vaca == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Resultados')),
            body: const Center(child: Text('No encontramos esta vaca')),
          );
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Resultados')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const SizedBox(height: 4),
                SummaryCard(
                  title: vaca.restaurantName,
                  subtitle: '${vaca.participants.length} personas · anfitrión: ${vaca.host.name}',
                  subtotal: vaca.result.subtotal,
                  tip: vaca.result.tip,
                  tipPercent: vaca.tipPercent,
                  total: vaca.total,
                ),
                const SectionHeader('El vaso'),
                CollectedCard(
                  collected: vaca.collected,
                  total: vaca.total,
                  percent: vaca.percentCollected,
                  paidCount: vaca.paidCount,
                  peopleCount: vaca.participants.length,
                  isClosed: vaca.isClosed,
                ),
                if (vaca.isClosed) ...[
                  const SizedBox(height: 12),
                  InfoBanner(
                    icon: Icons.check_circle,
                    title: 'La vaca quedó cerrada',
                    message: vaca.pending == 0
                        ? 'Todos pagaron su parte.'
                        : 'Se cerró con lo recogido. Faltó ${formatPesos(vaca.pending)}.',
                    color: AppColors.success,
                    background: AppColors.successSoft,
                  ),
                ],
                const SectionHeader('Quién paga qué'),
                for (final person in vaca.participants)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: PersonShareCard(
                      name: person.name,
                      initials: person.initials,
                      amount: vaca.result.amountFor(person.id),
                      isHost: person.id == vaca.hostId,
                      isPaid: vaca.isPaid(person.id),
                      shares: vaca.result.sharesFor(person.id),
                      // A closed vaca cannot change: null disables the checkbox.
                      onPaidChanged: vaca.isClosed
                          ? null
                          : (paid) => _togglePaid(context, vaca, person, paid),
                    ),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _copySummary(context, vaca),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copiar resumen'),
                ),
                const SizedBox(height: 10),
                if (!vaca.isClosed)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.ink,
                    ),
                    onPressed: () => _confirmClose(context, vaca),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Cerrar cuenta'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    icon: const Icon(Icons.home_outlined),
                    label: const Text('Volver al inicio'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
