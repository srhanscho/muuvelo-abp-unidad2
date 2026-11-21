import 'package:flutter/cupertino.dart';

import '../models/vaca.dart';
import '../services/vaca_sync_controller.dart';
import '../utils/constants.dart';
import '../utils/error_messages.dart';
import 'large_title_page.dart';
import 'state_views.dart';

/// VacaLoader: finds a vaca by id and rebuilds [builder] every time the
/// synced list changes (so a change saved from another screen, or pulled
/// from the database, appears here too).
///
/// If the vaca is not in the list yet it asks the database once; while
/// waiting it shows a spinner, and on failure an ErrorView with
/// "Reintentar". If the vaca was deleted it says so.
class VacaLoader extends StatefulWidget {
  const VacaLoader({
    super.key,
    required this.controller,
    required this.vacaId,
    required this.title,
    required this.builder,
    this.previousPageTitle,
  });

  final VacaSyncController controller;
  final String vacaId;

  /// Title of the placeholder page shown while loading / on error.
  final String title;
  final String? previousPageTitle;
  final Widget Function(BuildContext context, Vaca vaca) builder;

  @override
  State<VacaLoader> createState() => _VacaLoaderState();
}

class _VacaLoaderState extends State<VacaLoader> {
  Vaca? _fetched;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.byId(widget.vacaId) == null) _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final vaca = await widget.controller.fetch(widget.vacaId);
      if (mounted) setState(() => _fetched = vaca);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _placeholder(Widget child) => LargeTitlePage(
    title: widget.title,
    previousPageTitle: widget.previousPageTitle,
    children: [child],
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        // The synced list wins; _fetched only covers a vaca not listed yet.
        final vaca = widget.controller.byId(widget.vacaId) ?? _fetched;
        if (vaca != null) return widget.builder(context, vaca);
        if (_loading) {
          return _placeholder(
            const Padding(padding: EdgeInsets.all(48), child: CupertinoActivityIndicator(radius: 14)),
          );
        }
        if (_error != null) return _placeholder(ErrorView(message: friendlyError(_error!), onRetry: _fetch));
        return _placeholder(const _Gone());
      },
    );
  }
}

class _Gone extends StatelessWidget {
  const _Gone();

  @override
  Widget build(BuildContext context) => EmptyState(
    illustration: 'empty_vacas',
    fallback: CupertinoIcons.trash,
    title: 'Esta vaca ya no existe',
    message: 'Puede que la hayas eliminado desde otro dispositivo.',
    actionLabel: 'Volver al inicio',
    onAction: () => Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == Routes.home),
  );
}
