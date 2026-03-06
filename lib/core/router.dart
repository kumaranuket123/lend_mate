import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/signup_screen.dart';
import '../features/home/ui/home_screen.dart';
import '../features/loan/ui/create_loan_screen.dart';
import '../features/loan/ui/loan_detail_screen.dart';
import '../features/notifications/ui/notifications_screen.dart';
import '../features/payment/ui/extra_payment_screen.dart';
import '../features/profile/ui/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isAuth = session != null;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/signup';

    if (!isAuth && !isAuthRoute) return '/login';
    if (isAuth && isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/',       redirect: (_, __) => '/login'),
    GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/home',        builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/create-loan', builder: (_, __) => const CreateLoanScreen()),
    GoRoute(
      path: '/loan/:id',
      builder: (_, state) =>
          LoanDetailScreen(loanId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/extra-payment/:id',
      builder: (_, state) =>
          ExtraPaymentScreen(loanId: state.pathParameters['id']!),
    ),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/profile',       builder: (_, __) => const ProfileScreen()),
  ],
);
