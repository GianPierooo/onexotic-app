import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'core/config/app_config.dart';
import 'core/fcm/fcm_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'modules/perfil/providers/perfil_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  timeago.setLocaleMessages('es', timeago.EsMessages());
  await initializeDateFormatting('es', null);
  await initializeDateFormatting('es_PE', null);

  // .env solo existe en entornos locales — en Vercel se ignora el error.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Las credenciales están en AppConfig (valores públicos hardcodeados).
  // dotenv puede sobreescribirlas en dev local si existe el .env.
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? AppConfig.supabaseUrl,
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? AppConfig.supabaseAnonKey,
  );

  // Firebase init es opcional — la app funciona sin él.
  // Si firebase_options.dart tiene valores REEMPLAZA_* o la config falta,
  // se ignora silenciosamente (las notificaciones push no estarán disponibles).
  try {
    final opts = DefaultFirebaseOptions.currentPlatform;
    if (!opts.apiKey.startsWith('REEMPLAZA')) {
      await Firebase.initializeApp(options: opts);
      await FcmService.init();
      FcmService.listenTokenRefresh();
    }
  } catch (e) {
    debugPrint('[Firebase] no inicializado: $e');
  }

  runApp(const ProviderScope(child: OnExoticApp()));
}

class OnExoticApp extends ConsumerWidget {
  const OnExoticApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Sincroniza la paleta global con el tema actual.
    // Esto se ejecuta antes de construir el árbol, así todos los widgets que
    // referencian AppColors.X (getters dinámicos) leen el color correcto.
    AppColors.brightness =
        themeMode == ThemeMode.light ? Brightness.light : Brightness.dark;

    return MaterialApp.router(
      title: 'OnExotic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
