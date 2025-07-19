import 'package:flutter/material.dart';
import 'routes.dart';
import 'package:living/services/auth_helper.dart';
import 'package:living/services/user_dao.dart';
import 'package:living/widgets/loader.dart';

Future<bool> _isAuthenticated() async {
  // Use AuthService as the source of truth
  return AuthService().currentUser != null;
}

// Helper to get user role (stub, implement as needed)
Future<String?> _getUserRole() async {
  final user = AuthService().currentUser;
  if (user == null) return null;
  // Replace with your actual user role fetching logic
  return await UserDao().getUserRole(user.uid);
}

Route<dynamic>? guardedRoute(RouteSettings settings) {
  final String? name = settings.name;
  final builder = routes[name];

  // If route doesn't exist, return unknown route
  if (builder == null) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => 
          const Scaffold(body: Center(child: Text('Unknown route'))),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  // If route is unprotected, return it directly
  if (unprotectedRoutes.contains(name)) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => builder(context),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  // If route is admin-only, check authentication and role
  if (adminOnlyRoutes.contains(name)) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => 
          FutureBuilder<bool>(
            future: _isAuthenticated(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (!snapshot.data!) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushReplacementNamed('/auth');
                });
                return const Scaffold(
                  body: Center(child: Loader()),
                );
              }
              // Authenticated, now check role
              return FutureBuilder<String?>(
                future: _getUserRole(),
                builder: (context, roleSnapshot) {
                  if (!roleSnapshot.hasData) {
                    return const Scaffold(
                      body: Center(child: Loader()),
                    );
                  }
                  if (roleSnapshot.data != 'admin') {
                    // Not admin, redirect or show error
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Navigator.of(context).pushReplacementNamed('/');
                    });
                    return const Scaffold(
                      body: Center(child: Text('Access denied: Admins only')),
                    );
                  }
                  // Is admin
                  return builder(context);
                },
              );
            },
          ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  // If route is protected, check authentication
  if (protectedRoutesList.contains(name)) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => 
          FutureBuilder<bool>(
            future: _isAuthenticated(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: Loader()),
                );
              }
              if (!snapshot.data!) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushReplacementNamed('/auth');
                });
                return const Scaffold(
                  body: Center(child: Loader()),
                );
              }
              return builder(context);
            },
          ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }

  // Route exists but is not in either list - treat as unprotected by default
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
