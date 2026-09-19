import 'package:go_router/go_router.dart';

import '../features/character_creation/character_creation_screen.dart';
import '../features/character_sheet/character_sheet_screen.dart';
import '../features/game_master/game_master_screen.dart';
import '../features/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/rulebook/rulebook_chapter_screen.dart';
import '../features/rulebook/rulebook_screen.dart';
import '../features/scenarios/scenario_detail_screen.dart';
import '../features/scenarios/scenarios_screen.dart';
import '../features/shell/app_shell.dart';
import '../features/tables/notifications_screen.dart';
import '../features/tables/session_form_screen.dart';
import '../features/tables/table_detail_screen.dart';
import '../features/tables/tables_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/perso',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/perso',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'create',
                builder: (context, state) => const CharacterCreationScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => CharacterSheetScreen(
                  characterId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/tables',
            builder: (context, state) => const TablesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => TableDetailScreen(
                  tableId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'sessions/new',
                    builder: (context, state) => SessionFormScreen(
                      tableId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'sessions/:sessionId',
                    builder: (context, state) => SessionFormScreen(
                      tableId: state.pathParameters['id']!,
                      sessionId: state.pathParameters['sessionId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/scenarios',
            builder: (context, state) => const ScenariosScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => ScenarioDetailScreen(
                  scenarioId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ]),
        // A fourth branch with no tab of its own, for what the chrome opens:
        // the drawer's destinations and the bell. They keep the shell around,
        // and coming back to Perso, Tables or Scénarios finds each where it
        // was left.
        //
        // Notifications used to live under `/tables`, which meant opening the
        // bell from a character sheet lit the Tables tab and lost the reader's
        // place there. They are not a table matter — an invitation arrives
        // before any table exists.
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profil',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/regles',
            builder: (context, state) => const RulebookScreen(),
            routes: [
              GoRoute(
                path: ':chapterId',
                builder: (context, state) => RulebookChapterScreen(
                  chapterId: state.pathParameters['chapterId']!,
                ),
              ),
            ],
          ),
        ]),
      ],
    ),
    // Hors du shell, seul écran dans ce cas : animer une session prend la
    // tablette entière, et la barre d'onglets n'y mène nulle part.
    GoRoute(
      path: '/tables/:id/sessions/:sessionId/mj',
      builder: (context, state) => GameMasterScreen(
        tableId: state.pathParameters['id']!,
        sessionId: state.pathParameters['sessionId']!,
      ),
    ),
  ],
);
