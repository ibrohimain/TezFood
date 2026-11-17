import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config.dart';
import 'data/repositories/tez_repository.dart';
import 'data/services/api_client.dart';
import 'ui/core/theme.dart';
import 'ui/features/cart/cart_model.dart';
import 'ui/router.dart';
import 'ui/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final session = SessionModel();
  await session.load();
  runApp(buildTezApp(session));
}

Widget buildTezApp(SessionModel session) {
  final api = ApiClient(baseUrl: ApiConfig.base, session: session);
  final repository = TezRepository(api, session);
  final router = buildRouter(session);
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SessionModel>.value(value: session),
      ChangeNotifierProvider(create: (_) => CartModel()),
      Provider<TezRepository>.value(value: repository),
    ],
    child: TezApp(router: router),
  );
}

class TezApp extends StatelessWidget {
  const TezApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TEZ FOOD',
      debugShowCheckedModeBanner: false,
      theme: buildTezTheme(),
      routerConfig: router,
    );
  }
}
