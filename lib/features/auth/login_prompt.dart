import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';


class LoginPrompt extends ConsumerWidget {
  const LoginPrompt({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text("Save your work"),
      content: const Text(
        "Sign in to keep your notes safe and access them across devices.",
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Not now"),
        ),
        ElevatedButton(
          onPressed: () async {
            await ref
                .read(authControllerProvider)
                .signInWithGoogle();
            Navigator.pop(context);
          },
          child: const Text("Sign in with Google"),
        ),
      ],
    );
  }
}
