import 'package:flutter/cupertino.dart';

import '../models/vaca.dart';
import '../services/vaca_sync_controller.dart';
import '../utils/constants.dart';
import '../utils/dates.dart';
import '../utils/design_tokens.dart';
import '../utils/error_messages.dart';
import '../widgets/grouped_section.dart';
import '../widgets/large_title_page.dart';
import '../widgets/state_views.dart';
import '../widgets/sync_status_badge.dart';
import '../widgets/vaca_tile.dart';

enum VacaFilter { all, open, closed }

/// Screen 2 - Listado ("Mis vacas").
///
/// Every vaca of the user, read from Supabase. Search by restaurant,
/// filter Todas / Abiertas / Cerradas and pull down to re-sync.
class VacasListScreen extends StatefulWidget {
  const VacasListScreen({super.key, required this.controller, required this.onNewVaca});

  final VacaSyncController controller;
  final VoidCallback onNewVaca;

  @override
  State<VacasListScreen> createState() => _VacasListScreenState();
}

class _VacasListScreenState extends State<VacasListScreen> {
  VacaFilter _filter = VacaFilter.all;
  String _query = '';

  /// Pure filtering: no extra queries, the list is already in memory.
  List<Vaca> _visible(List<Vaca> vacas) {
    final query = _query.trim().toLowerCase();
    return vacas.where((v) {
      final matchesFilter = switch (_filter) {
        VacaFilter.all => true,
        VacaFilter.open => !v.isClosed,
        VacaFilter.closed => v.isClosed,
      };
      return matchesFilter && (query.isEmpty || v.restaurantName.toLowerCase().contains(query));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final visible = _visible(controller.vacas);
        return LargeTitlePage(
          title: 'Mis vacas',
          onRefresh: controller.refresh,
          bottomPadding: Space.tabBarClearance,
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onNewVaca,
            child: const Icon(CupertinoIcons.add, semanticLabel: 'Nueva vaca'),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SyncStatusBadge(state: controller.state, lastSync: controller.lastSync, onRetry: controller.refresh),
            ),
            const SizedBox(height: Space.l),
            CupertinoSearchTextField(
              placeholder: 'Buscar restaurante',
              style: AppText.body,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: Space.m),
            SizedBox(
              width: double.infinity,
              child: CupertinoSlidingSegmentedControl<VacaFilter>(
                groupValue: _filter,
                onValueChanged: (value) => setState(() => _filter = value ?? VacaFilter.all),
                children: const {
                  VacaFilter.all: _Segment('Todas'),
                  VacaFilter.open: _Segment('Abiertas'),
                  VacaFilter.closed: _Segment('Cerradas'),
                },
              ),
            ),
            const SizedBox(height: Space.xl),
            ..._content(context, visible),
          ],
        );
      },
    );
  }

  List<Widget> _content(BuildContext context, List<Vaca> visible) {
    final controller = widget.controller;
    if (!controller.hasLoaded) return const [SkeletonRows()];
    if (controller.error != null && controller.vacas.isEmpty) {
      return [ErrorView(message: friendlyError(controller.error!), onRetry: controller.refresh)];
    }
    if (controller.vacas.isEmpty) {
      return [
        EmptyState(
          illustration: 'empty_vacas',
          fallback: CupertinoIcons.tray,
          title: 'Aún no tienes vacas',
          message: 'Registra la primera cuenta y Muuvelo calcula lo justo para cada uno.',
          actionLabel: 'Nueva vaca',
          onAction: widget.onNewVaca,
        ),
      ];
    }
    if (visible.isEmpty) {
      return const [
        EmptyState(
          illustration: 'empty_vacas',
          fallback: CupertinoIcons.search,
          title: 'Sin resultados',
          message: 'Prueba con otro nombre o cambia el filtro.',
        ),
      ];
    }
    return [
      GroupedSection(
        header: '${visible.length} ${visible.length == 1 ? 'vaca' : 'vacas'}',
        separatorInset: 58,
        children: [for (final vaca in visible) _tile(context, vaca)],
      ),
    ];
  }

  Widget _tile(BuildContext context, Vaca vaca) => VacaTile(
    key: ValueKey(vaca.id),
    title: vaca.restaurantName,
    subtitle: '${formatRelativeDay(vaca.createdAt, DateTime.now())} · ${vaca.participants.length} personas',
    amount: vaca.isClosed ? vaca.total : vaca.pending,
    amountCaption: vaca.isClosed ? 'total' : 'por cobrar',
    percent: vaca.percentCollected,
    isClosed: vaca.isClosed,
    statusLabel: vaca.isClosed ? 'Cerrada' : 'Abierta · ${vaca.paidCount} de ${vaca.participants.length}',
    onTap: () => Navigator.pushNamed(context, Routes.detail, arguments: vaca.id),
  );
}

class _Segment extends StatelessWidget {
  const _Segment(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: Space.s),
    child: Text(text, style: AppText.subheadline.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600)),
  );
}
