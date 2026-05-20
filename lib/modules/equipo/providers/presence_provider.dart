import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Conjunto de user_id de usuarios actualmente online.
/// Usa Supabase Realtime Presence: todos los clientes conectados al canal
/// 'app:presence' son visibles mutuamente en tiempo real.
final onlineUserIdsProvider = StreamProvider<Set<String>>((ref) {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value(<String>{});

  final controller = StreamController<Set<String>>.broadcast();

  // Nombre fijo para que todos los usuarios compartan el mismo canal.
  final channel = Supabase.instance.client.channel('app:presence');

  void syncPresence() {
    if (controller.isClosed) return;
    final ids = <String>{};
    // presenceState() ? List<SinglePresenceState>
    // cada SinglePresenceState.presences ? List<Presence>
    // cada Presence.payload ? Map<String, dynamic>
    for (final state in channel.presenceState()) {
      for (final p in state.presences) {
        final uid = p.payload['user_id'] as String?;
        if (uid != null) ids.add(uid);
      }
    }
    if (kDebugMode) print('[presence] online: ${ids.length} usuarios · $ids');
    controller.add(ids);
  }

  channel
      .onPresenceSync((_) => syncPresence())
      .onPresenceJoin((_) => syncPresence())
      .onPresenceLeave((_) => syncPresence())
      .subscribe((status, [error]) async {
    if (kDebugMode) print('[presence] status: $status');
    if (status == RealtimeSubscribeStatus.subscribed) {
      await channel.track({
        'user_id': userId,
        'online_at': DateTime.now().toIso8601String(),
      });
      syncPresence();
    }
  });

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});
