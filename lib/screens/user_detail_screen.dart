import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'selfcheck_detail_screen.dart';

class UserDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userData;

  const UserDetailScreen({
    Key? key,
    required this.userId,
    required this.userData,
  }) : super(key: key);

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userData['username'] ?? '유저'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '기본정보', icon: Icon(Icons.person)),
            Tab(text: '체크인', icon: Icon(Icons.check_circle)),
            Tab(text: '할일', icon: Icon(Icons.task)),
            Tab(text: '자가진단', icon: Icon(Icons.health_and_safety)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 탭 1: 기본 정보
          _buildUserInfoTab(),
          // 탭 2: 체크인
          _buildCheckinsTab(),
          // 탭 3: 할일
          _buildRoutinesTab(),
          // 탭 4: 자가진단
          _buildSelfCheckTab(),
        ],
      ),
    );
  }

  // ========== TAB 1: 기본 정보 ==========
  Widget _buildUserInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('기본 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildInfoRow('ID', widget.userId),
          _buildInfoRow('이름', widget.userData['username'] ?? '-'),
          _buildInfoRow('이메일', widget.userData['email'] ?? '-'),
          _buildInfoRow('역할', widget.userData['role'] ?? '-'),
          _buildInfoRow('생성일', _formatDate(widget.userData['createdAt'])),
          _buildInfoRow('수정일', _formatDate(widget.userData['updatedAt'])),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // ========== TAB 2: 체크인 ==========
  Widget _buildCheckinsTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestoreService.getUserCheckins(widget.userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('에러: ${snapshot.error}'));
        }

        final checkins = snapshot.data ?? [];

        if (checkins.isEmpty) {
          return const Center(child: Text('체크인 기록이 없습니다'));
        }

        return ListView.builder(
          itemCount: checkins.length,
          itemBuilder: (context, index) {
            final checkin = checkins[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text('체크인: ${checkin['checkInDate'] ?? '-'}'),
                subtitle: Text('ID: ${checkin['id']}'),
                trailing: Text(_formatDate(checkin['createdAt'])),
              ),
            );
          },
        );
      },
    );
  }

  // ========== TAB 3: 할일 ==========
  // ========== TAB 3: 루틴 (수정됨) ==========
  Widget _buildRoutinesTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestoreService.getUserRoutines(widget.userId),  // ← 변경
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('에러: ${snapshot.error}'));
        }

        final routines = snapshot.data ?? [];  // ← todos → routines

        if (routines.isEmpty) {
          return const Center(child: Text('루틴이 없습니다'));  // ← 메시지 수정
        }

        return ListView.builder(
          itemCount: routines.length,
          itemBuilder: (context, index) {
            final routine = routines[index];  // ← 변수명 변경
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                leading: Checkbox(
                  value: routine['isCompleted'] ?? false,
                  onChanged: (value) {
                    firestoreService.updateRoutineStatus(  // ← 메서드명 변경
                      widget.userId,
                      routine['id'],
                      value ?? false,
                    );
                  },
                ),
                title: Text(
                  routine['routineText'] ?? '루틴 없음',  // ← 필드명 변경
                  style: TextStyle(
                    decoration: (routine['isCompleted'] ?? false)
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('추천: ${routine['isRecommended'] ?? false ? 'Yes' : 'No'}'),
                    Text('생성: ${_formatDate(routine['createdAt'])}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    firestoreService.deleteRoutine(widget.userId, routine['id']);  // ← 메서드명 변경
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }


  // ========== TAB 4: 자가진단 (수정됨) ==========
  Widget _buildSelfCheckTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestoreService.getUserSelfCheckResults(widget.userId),  // 결과 목록
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('에러: ${snapshot.error}'));
        }

        final results = snapshot.data ?? [];

        if (results.isEmpty) {
          return const Center(child: Text('자가진단 결과가 없습니다'));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            final severity = result['severity'] ?? 'unknown';
            final totalScore = result['totalScore'] ?? 0;
            final checkDate = result['checkDate'] ?? '-';

            // 심각도별 색상
            Color severityColor = Colors.grey;
            if (severity == '경증') {
              severityColor = Colors.green;
            } else if (severity == '중등도') {
              severityColor = Colors.orange;
            } else if (severity == '심각') {
              severityColor = Colors.red;
            }

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                onTap: () {
                  // 자가진단 상세 화면으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelfCheckDetailScreen(
                        userId: widget.userId,
                        resultData: result,
                      ),
                    ),
                  );
                },
                leading: CircleAvatar(
                  backgroundColor: severityColor,
                  child: Text(
                    '$totalScore',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  checkDate,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(severity),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            );
          },
        );
      },
    );
  }


  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '-';
    if (timestamp is String) return timestamp;
    try {
      return timestamp.toDate().toString().split('.')[0];
    } catch (e) {
      return '-';
    }
  }
}
