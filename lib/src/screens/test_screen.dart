import 'package:flutter/material.dart';
import '../services/user_serivce.dart';

class TestScreen extends StatelessWidget {
  const TestScreen({super.key});

  static const routeName = '/test';

  @override
  Widget build(BuildContext context) {
    final userService = UserService();

    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Test Screen')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                await userService.testCreateUser();
              },
              child: const Text('Create Test User'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await userService.testGetAllUsers();
              },
              child: const Text('Get All Users'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Test updating a user
                final testUid =
                    'test_user_${DateTime.now().millisecondsSinceEpoch}';
                await userService.createUserDoc(
                  testUid,
                  'update_test@example.com',
                  'Citizen',
                );
                await userService.updateUser(testUid, {'role': 'Gov Admin'});
                await userService.testGetAllUsers();
              },
              child: const Text('Test Update User'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                // Test deleting a user
                final testUid =
                    'test_user_${DateTime.now().millisecondsSinceEpoch}';
                await userService.createUserDoc(
                  testUid,
                  'delete_test@example.com',
                  'Citizen',
                );
                await userService.deleteUser(testUid);
                await userService.testGetAllUsers();
              },
              child: const Text('Test Delete User'),
            ),
          ],
        ),
      ),
    );
  }
}
