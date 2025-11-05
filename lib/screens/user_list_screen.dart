import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'user_detail_screen.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('유저 목록')),
      body: StreamBuilder(
        stream: firestoreService.getAllUsers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('에러: ${snapshot.error}'));
          }

          final users = snapshot.data as List<Map<String, dynamic>>;

          if (users.isEmpty) {
            return const Center(child: Text('저장된 유저가 없습니다'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(user['username']?[0] ?? 'U'),
                ),
                title: Text(user['username'] ?? '이름 없음'),
                subtitle: Text(user['email'] ?? '이메일 없음'),
                trailing: Text(
                  user['role'] ?? 'user',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserDetailScreen(
                        userId: user['id'],
                        userData: user,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void showUserDetails(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['username'] ?? '유저'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${user['id']}'),
            Text('Email: ${user['email']}'),
            Text('Role: ${user['role']}'),
            Text('Created: ${user['createdAt']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
