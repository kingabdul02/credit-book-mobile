import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/home/presentation/bloc/home_event.dart';
import '../../features/people/presentation/pages/people_screen.dart';
import '../../features/people/presentation/pages/add_person_screen.dart';
import '../../features/people/presentation/pages/ledger_screen.dart';
import '../../features/people/presentation/pages/add_transaction_screen.dart';
import '../../features/people/presentation/pages/all_debts_screen.dart';
import '../../features/people/presentation/bloc/people_bloc.dart';
import '../../features/people/presentation/bloc/add_person_bloc.dart';
import '../../features/people/presentation/bloc/ledger_bloc.dart';
import '../../features/people/presentation/bloc/add_transaction_bloc.dart';
import '../../features/people/presentation/bloc/all_debts_bloc.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/auth_screen.dart';
import '../../features/auth/presentation/pages/set_pin_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/settings/presentation/pages/face_setup_screen.dart';
import '../../features/people/presentation/pages/face_verify_screen.dart';
import '../../features/insights/presentation/pages/insights_screen.dart';
import '../../features/insights/presentation/bloc/insights_bloc.dart';
import '../../features/legacy/presentation/pages/next_of_kin_screen.dart';
import '../../features/legacy/presentation/pages/add_legacy_contact_screen.dart';
import '../../features/legacy/presentation/pages/access_requests_screen.dart';
import '../../features/legacy/presentation/pages/submit_access_request_screen.dart';
import '../../features/legacy/presentation/pages/estate_report_screen.dart';
import '../../features/legacy/presentation/bloc/legacy_bloc.dart';
import '../../features/legacy/domain/entities/legacy_contact_entity.dart';
import '../di/injection_container.dart' as di;

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/set-pin',
        name: 'set-pin',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SetPinScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => di.sl<HomeBloc>()..add(LoadDashboardRequested()),
            child: const HomeScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/people',
        name: 'people',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => di.sl<PeopleBloc>()..add(LoadPeopleDataRequested()),
            child: const PeopleScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/add-person',
        name: 'add-person',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => di.sl<AddPersonBloc>(),
            child: const AddPersonScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/ledger/:id',
        name: 'ledger',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => di.sl<LedgerBloc>(),
              child: LedgerScreen(contactId: id),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/add-transaction',
        name: 'add-transaction',
        pageBuilder: (context, state) {
          final contactId = state.uri.queryParameters['contactId'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: BlocProvider(
              create: (_) => di.sl<AddTransactionBloc>(),
              child: AddTransactionScreen(preSelectedContactId: contactId),
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/insights',
        name: 'insights',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => di.sl<InsightsBloc>(),
            child: const InsightsScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/all-debts',
        name: 'all-debts',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => di.sl<AllDebtsBloc>(),
            child: const AllDebtsScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: '/settings/face-setup',
        name: 'face-setup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FaceSetupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/face-verify',
        name: 'face-verify',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final amount = extra['amount'] as double? ?? 0.0;
          final contactName = extra['contactName'] as String? ?? 'Unknown';

          return CustomTransitionPage(
            key: state.pageKey,
            child: FaceVerifyScreen(amount: amount, contactName: contactName),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: '/next-of-kin',
        name: 'next-of-kin',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => di.sl<LegacyBloc>()..add(LoadLegacyData()),
            child: const NextOfKinScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
        ),
      ),
      GoRoute(
        path: '/next-of-kin/add',
        name: 'next-of-kin-add',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final contact = extra['contact'] as LegacyContactEntity?;
          final isPrimary = extra['isPrimary'] as bool? ?? true;
          // The caller must pass the live LegacyBloc via extra['bloc'] so we
          // reuse the already-initialized instance (with _settings populated).
          final bloc = extra['bloc'] as LegacyBloc?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: bloc != null
                ? BlocProvider.value(
                    value: bloc,
                    child: AddLegacyContactScreen(
                      existingContact: contact,
                      isPrimary: isPrimary,
                    ),
                  )
                : BlocProvider(
                    create: (_) => di.sl<LegacyBloc>()..add(LoadLegacyData()),
                    child: AddLegacyContactScreen(
                      existingContact: contact,
                      isPrimary: isPrimary,
                    ),
                  ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 1.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
          );
        },
      ),
      GoRoute(
        path: '/access-requests',
        name: 'access-requests',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final bloc = extra['bloc'] as LegacyBloc?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: bloc != null
                ? BlocProvider.value(
                    value: bloc,
                    child: const AccessRequestsScreen(),
                  )
                : BlocProvider(
                    create: (_) => di.sl<LegacyBloc>(),
                    child: const AccessRequestsScreen(),
                  ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
          );
        },
      ),
      GoRoute(
        path: '/submit-access-request',
        name: 'submit-access-request',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => di.sl<LegacyBloc>(),
            child: const SubmitAccessRequestScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
        ),
      ),
      GoRoute(
        path: '/estate-report/:id',
        name: 'estate-report',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final bloc = extra['bloc'] as LegacyBloc?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: bloc != null
                ? BlocProvider.value(
                    value: bloc,
                    child: EstateReportScreen(requestId: id),
                  )
                : BlocProvider(
                    create: (_) => di.sl<LegacyBloc>(),
                    child: EstateReportScreen(requestId: id),
                  ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) =>
                    SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(1.0, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
          );
        },
      ),
    ],
  );
}
