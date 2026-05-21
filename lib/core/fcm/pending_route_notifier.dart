import 'package:flutter/foundation.dart';

// FcmService corre fuera del árbol de widgets (es estático, se inicializa en
// main antes de runApp), por lo que no puede leer Riverpod ni acceder al
// BuildContext. Este ValueNotifier hace de puente: FcmService asigna la ruta
// pendiente y AppShell la consume cuando el árbol ya está montado.
final ValueNotifier<String?> pendingRouteNotifier = ValueNotifier<String?>(null);
