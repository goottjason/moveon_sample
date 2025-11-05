import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class SelfCheckDetailScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> resultData;

  const SelfCheckDetailScreen({
    Key? key,
    required this.userId,
    required this.resultData,
  }) : super(key: key);

  @override
  State<SelfCheckDetailScreen> createState() => _SelfCheckDetailScreenState();
}

class _SelfCheckDetailScreenState extends State<SelfCheckDetailScreen> {
  final firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('자가진단 상세'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ===== 상단: 결과 요약 =====
            _buildResultSummary(),

            const Divider(thickness: 2),

            // ===== 하단: 답변 상세 =====
            _buildAnswerDetails(),
          ],
        ),
      ),
    );
  }

  // ========== 결과 요약 섹션 ==========
  Widget _buildResultSummary() {
    final severity = widget.resultData['severity'] ?? 'unknown';
    final totalScore = widget.resultData['totalScore'] ?? 0;
    final checkDate = widget.resultData['checkDate'] ?? '-';
    final message = widget.resultData['message'] ?? '';

    // 심각도별 색상
    Color severityColor = Colors.grey;
    if (severity == '경증') {
      severityColor = Colors.green;
    } else if (severity == '중등도') {
      severityColor = Colors.orange;
    } else if (severity == '심각') {
      severityColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                checkDate,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  severity,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('총점: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '$totalScore점',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ========== 답변 상세 섹션 ==========
  Widget _buildAnswerDetails() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: firestoreService.getSelfCheckAnswersByResult(
        widget.userId,
        widget.resultData['id'],
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('에러: ${snapshot.error}'),
          );
        }

        final answers = snapshot.data ?? [];

        if (answers.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('답변이 없습니다'),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '답변 상세 (${answers.length}개 문항)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: answers.length,
              itemBuilder: (context, index) {
                final answer = answers[index];
                return _buildAnswerCard(answer, index + 1);
              },
            ),
          ],
        );
      },
    );
  }

  // ========== 개별 답변 카드 ==========
  Widget _buildAnswerCard(
      Map<String, dynamic> answer,
      int questionNumber,
      ) {
    final selfCheckId = answer['selfCheckId'] ?? '';
    final questionId = answer['questionId'] ?? '';
    final answerScore = answer['answerScore'] ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 질문 번호 + 점수
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '문항 $questionNumber',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$answerScore점',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 질문 텍스트 (비동기 로드)
            FutureBuilder<String>(
              future: firestoreService.getQuestionText(
                selfCheckId,
                questionId,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text(
                    '질문 로딩 중...',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  );
                }

                return Text(
                  snapshot.data ?? '질문을 찾을 수 없습니다',
                  style: const TextStyle(fontSize: 14),
                );
              },
            ),
            const SizedBox(height: 8),

            // 추가 정보
            Row(
              children: [
                Text(
                  'Q. $questionId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'sc: $selfCheckId',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
