import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/vaca_sync_controller.dart';
import '../utils/constants.dart';
import '../utils/dates.dart';
import '../utils/design_tokens.dart';
import 'muuvelo_icon.dart';

/// SyncStatusBadge: small pill that always tells whether the data on
/// screen matches the database: "Sincronizando…" (spinner),
/// "Sincronizado hace un momento" (green cloud) or "Sin sincronizar ·
/// Reintentar" (red, tappable).
///
/// Parameters:
/// - [state] / [lastSync]: from VacaSyncController.
/// - [onRetry]: called when the user taps the badge.
///
/// It refreshes its own text every 30 s so "hace un momento" becomes
/// "hace 2 min" without waiting for the next sync.
class SyncStatusBadge extends StatefulWidget {
  const SyncStatusBadge({super.key, required this.state, required this.lastSync, this.onRetry});

  final SyncState state;
  final DateTime? lastSync;
  final VoidCallback? onRetry;

  @override
  State<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends State<SyncStatusBadge> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (Widget icon, String text, Color color) = switch (widget.state) {
      SyncState.syncing => (
        const CupertinoActivityIndicator(radius: 7),
        'Sincronizando…',
        AppColors.muted,
      ),
      SyncState.synced => (
        const MuuveloIcon('cloud_sync', size: 16, fallback: CupertinoIcons.cloud_fill, color: AppColors.success),
        describeLastSync(widget.lastSync, DateTime.now()),
        AppColors.muted,
      ),
      SyncState.error => (
        const Icon(CupertinoIcons.exclamationmark_circle_fill, size: 16, color: AppColors.error),
        'Sin sincronizar · Reintentar',
        AppColors.error,
      ),
    };

    return Semantics(
      liveRegion: true,
      button: widget.onRetry != null,
      child: Material(
        color: AppColors.surface,
        borderRadius: Radii.largeAll,
        child: InkWell(
          borderRadius: Radii.largeAll,
          onTap: widget.state == SyncState.syncing ? null : widget.onRetry,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: 6),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Row(
                key: ValueKey(text),
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 16, height: 16, child: Center(child: icon)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      text,
                      style: AppText.caption.copyWith(color: color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
