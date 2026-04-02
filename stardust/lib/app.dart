import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/register_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/likes/screens/likes_screen.dart';
import 'features/messages/screens/messages_screen.dart';
import 'features/messages/screens/chat_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/profile/screens/edit_profile_screen.dart';
import 'features/profile/screens/user_profile_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/settings/screens/notification_settings_screen.dart';
import 'features/settings/screens/privacy_settings_screen.dart';
import 'features/settings/screens/search_preferences_screen.dart';
import 'features/settings/screens/card_settings_screen.dart';
import 'features/premium/screens/premium_screen.dart';
import 'features/settings/screens/about_screen.dart';
import 'web/screens/landing_screen.dart';
import 'web/screens/rules_screen.dart';
import 'web/screens/docs_screen.dart';
import 'web/screens/privacy_screen.dart';
import 'shared/widgets/main_scaffold.dart';
import 'shared/widgets/web_navigation.dart';
import 'services/online_status_service.dart';

void main() {}

// Auth state provider
final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

Stream<User?> get authStateChanges => _auth.authStateChanges();

String? get currentUserId => _auth.currentUser?.uid;

// Check if profile is complete
Future<bool> _isProfileComplete(String userId) async {
  final doc = await _firestore.collection('users').doc(userId).get();
  if (doc.exists) {
    return doc.data()?['isProfileComplete'] ?? false;
  }
  return false;
}

// Роутер
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: kIsWeb ? '/' : '/login',
  redirect: (context, state) async {
    final isLoggedIn = _auth.currentUser != null;
    final isAuthRoute = state.matchedLocation == '/login' || 
                        state.matchedLocation == '/register';
    final isOnboarding = state.matchedLocation == '/edit-profile';
    
    // Публичные маршруты (доступны без авторизации)
    final isPublicRoute = state.matchedLocation == '/' ||
                          state.matchedLocation == '/rules' ||
                          state.matchedLocation == '/docs' ||
                          state.matchedLocation == '/privacy' ||
                          state.matchedLocation == '/terms';
    
    // If not logged in and not on auth route and not public route, redirect to login
    if (!isLoggedIn && !isAuthRoute && !isPublicRoute) {
      return '/login';
    }
    
    // If logged in and on auth route, redirect to home
    if (isLoggedIn && isAuthRoute) {
      return '/home';
    }
    
    // If logged in but profile not complete, force to fill profile
    if (isLoggedIn && !isOnboarding) {
      final isComplete = await _isProfileComplete(_auth.currentUser!.uid);
      if (!isComplete) {
        return '/edit-profile';
      }
    }
    
    return null;
  },
  routes: [
    // Web маршруты (Landing страницы)
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: '/rules',
      builder: (context, state) => const RulesScreen(),
    ),
    GoRoute(
      path: '/docs',
      builder: (context, state) => const DocsScreen(),
    ),
    GoRoute(
      path: '/privacy',
      builder: (context, state) => const PrivacyScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const RulesScreen(),
    ),
    // Auth
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    // Main app (mobile/web)
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        if (kIsWeb) {
          return WebNavigation(child: child);
        }
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/likes',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const LikesScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/messages',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const MessagesScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => CustomTransitionPage(
            child: const ProfileScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
      ],
    ),
    // Non-shell routes
    GoRoute(
      path: '/chat/:conversationId',
      builder: (context, state) {
        final conversationId = state.pathParameters['conversationId']!;
        final userName = state.uri.queryParameters['name'] ?? 'Чат';
        final userId = state.uri.queryParameters['userId'];
        return ChatScreen(
          conversationId: conversationId, 
          userName: userName,
          userId: userId,
        );
      },
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationSettingsScreen(),
    ),
    GoRoute(
      path: '/privacy-settings',
      builder: (context, state) => const PrivacySettingsScreen(),
    ),
    GoRoute(
      path: '/search-preferences',
      builder: (context, state) => const SearchPreferencesScreen(),
    ),
    GoRoute(
      path: '/card-settings',
      builder: (context, state) => const CardSettingsScreen(),
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const AboutScreen(),
    ),
    
    // Просмотр профиля пользователя
    GoRoute(
      path: '/user/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        final userName = state.uri.queryParameters['name'];
        final photoUrl = state.uri.queryParameters['photo'];
        return UserProfileScreen(
          userId: userId,
          userName: userName,
          photoUrl: photoUrl,
        );
      },
    ),
  ],
);

class StardustApp extends StatefulWidget {
  const StardustApp({super.key});

  @override
  State<StardustApp> createState() => _StardustAppState();
}

class _StardustAppState extends State<StardustApp> with WidgetsBindingObserver {
  final OnlineStatusService _onlineStatusService = OnlineStatusService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToAuthChanges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _onlineStatusService.stopTracking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // User opened app - start tracking
        _onlineStatusService.startTracking();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // User left app - stop tracking
        _onlineStatusService.stopTracking();
        break;
    }
  }

  void _listenToAuthChanges() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        // User logged in - start tracking
        _onlineStatusService.startTracking();
      } else {
        // User logged out - stop tracking
        _onlineStatusService.stopTracking();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Stardust',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
