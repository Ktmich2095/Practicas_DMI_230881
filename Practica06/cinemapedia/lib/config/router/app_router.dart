
import 'package:cinemapedia/presentations/screens/screens.dart';
import 'package:go_router/go_router.dart';


final appRouter = GoRouter(
  initialLocation: '/',
  routes:[
    GoRoute(
      path:'/',
      name: HomeScreen.name
    ),
  ]
);