import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_prompt.dart';


class PenForgeApp extends ConsumerWidget {
  const PenForgeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: authState.when(
        loading: () => const SplashScreen(),
        error: (_, __) => const ErrorScreen(),
        data: (user) {
          if (user == null) {
            ref.read(authControllerProvider).signInAnonymously();
            return const SplashScreen();
          }
          return const HomeScreen();
        },
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Setting up PenForge…")));
  }
}

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Something went wrong")));
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text("PenForge"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Logged in successfully 🎉",
              style: TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 20),

            // Show button only if user is anonymous
            if (user != null && user.isAnonymous)
              ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const LoginPrompt(),
                  );
                },
                child: const Text("Save your work"),
              ),
          ],
        ),
      ),
    );
  }
}

