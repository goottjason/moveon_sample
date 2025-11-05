import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ========== READ (읽기) ==========

  /// users 컬렉션의 모든 유저 조회
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _db.collection('users').snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(),
    );
  }

  /// 특정 유저 조회
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      print('유저 조회 에러: $e');
      return null;
    }
  }

  /// 특정 유저의 todos 조회
  Stream<List<Map<String, dynamic>>> getUserRoutines(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('routines')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(),
    );
  }

  /// 특정 유저에게 routine 추가 (추가됨)
  Future<void> addRoutine({
    required String userId,
    required String routineText,
    bool isCompleted = false,
    bool isRecommended = false,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('routines')  // ← todos → routines
          .add({
        'routineText': routineText,
        'isCompleted': isCompleted,
        'isRecommended': isRecommended,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Routine 추가 성공');
    } catch (e) {
      print('Routine 추가 실패: $e');
      rethrow;
    }
  }
  /// routine 완료 상태 변경
  Future<void> updateRoutineStatus(
      String userId,
      String routineId,
      bool isCompleted,
      ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('routines')  // ← todos → routines
          .doc(routineId)
          .update({
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
        if (isCompleted) 'completedAt': FieldValue.serverTimestamp(),
      });
      print('Routine 상태 변경 성공');
    } catch (e) {
      print('Routine 상태 변경 실패: $e');
      rethrow;
    }
  }
  /// routine 삭제
  Future<void> deleteRoutine(String userId, String routineId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('routines')  // ← todos → routines
          .doc(routineId)
          .delete();
      print('Routine 삭제 성공');
    } catch (e) {
      print('Routine 삭제 실패: $e');
      rethrow;
    }
  }

  /// 특정 유저의 points 조회
  Stream<List<Map<String, dynamic>>> getUserPoints(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('points')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(),
    );
  }
  /// 특정 유저의 checkins 조회
  Stream<List<Map<String, dynamic>>> getUserCheckins(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('checkins')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(),
    );
  }

  /// 특정 유저의 selfcheckresults 조회 (결과 목록)
  Stream<List<Map<String, dynamic>>> getUserSelfCheckResults(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('selfcheckresults')
        // .orderBy('checkDate', descending: true)  // 최신순 정렬
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(),
    );
  }

  /// 특정 selfcheckresult의 answers 조회
  Stream<List<Map<String, dynamic>>> getSelfCheckAnswersByResult(
      String userId,
      String resultId,
      ) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('selfcheckanswers')
        .where('resultId', isEqualTo: resultId)  // resultId로 필터링
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(),
    );
  }

  /// 특정 selfcheck의 question 텍스트 조회
  Future<String> getQuestionText(
      String selfCheckId,
      String questionId,
      ) async {
    try {
      final doc = await _db
          .collection('selfchecks')
          .doc(selfCheckId)
          .collection('selfcheckquestions')
          .doc(questionId)
          .get();

      if (doc.exists) {
        return doc['questionText'] ?? '질문 없음';
      }
      return '질문을 찾을 수 없습니다';
    } catch (e) {
      print('질문 조회 에러: $e');
      return '에러';
    }
  }

  /// selfcheckresult 추가
  Future<void> addSelfCheckResult({
    required String userId,
    required String selfCheckId,
    required int totalScore,
    required String checkDate,
    required String severity,
    required String message,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('selfcheckresults')
          .add({
        'selfCheckId': selfCheckId,
        'totalScore': totalScore,
        'checkDate': checkDate,
        'severity': severity,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('자가진단 결과 추가 성공');
    } catch (e) {
      print('자가진단 결과 추가 실패: $e');
      rethrow;
    }
  }

  /// selfcheckanswer 추가 (resultId 포함)
  Future<void> addSelfCheckAnswerWithResult({
    required String userId,
    required String selfCheckId,
    required String questionId,
    required int answerScore,
    required String resultId,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('selfcheckanswers')
          .add({
        'selfCheckId': selfCheckId,
        'questionId': questionId,
        'answerScore': answerScore,
        'resultId': resultId,  // 결과와 연결
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('자가진단 답변 추가 성공');
    } catch (e) {
      print('자가진단 답변 추가 실패: $e');
      rethrow;
    }
  }



  /// 특정 유저의 selfcheckanswers 조회
  Stream<List<Map<String, dynamic>>> getUserSelfCheckAnswers(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('selfcheckanswers')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(),
    );
  }
  /// 체크인 추가
  Future<void> addCheckin({
    required String userId,
    required String checkInDate,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('checkins')
          .doc(checkInDate) // 날짜를 문서ID로
          .set({
        'checkInDate': checkInDate,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('체크인 추가 성공');
    } catch (e) {
      print('체크인 추가 실패: $e');
      rethrow;
    }
  }
  /// 자가진단 답변 추가
  Future<void> addSelfCheckAnswer({
    required String userId,
    required String selfCheckId,
    required String questionId,
    required int answerScore,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('selfcheckanswers')
          .add({
        'selfCheckId': selfCheckId,
        'questionId': questionId,
        'answerScore': answerScore,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('자가진단 답변 추가 성공');
    } catch (e) {
      print('자가진단 답변 추가 실패: $e');
      rethrow;
    }
  }

  /// selfchecks 조회
  Future<Map<String, dynamic>?> getSelfCheck(String selfCheckId) async {
    try {
      final doc = await _db.collection('selfchecks').doc(selfCheckId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data() as Map<String, dynamic>};
      }
      return null;
    } catch (e) {
      print('selfcheck 조회 에러: $e');
      return null;
    }
  }

  /// 특정 selfcheck의 questions 조회
  Stream<List<Map<String, dynamic>>> getSelfCheckQuestions(
      String selfCheckId) {
    return _db
        .collection('selfchecks')
        .doc(selfCheckId)
        .collection('selfcheckquestions')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList(),
    );
  }

  // ========== CREATE (추가) ==========

  /// 새로운 유저 추가
  Future<void> addUser({
    required String userId,
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await _db.collection('users').doc(userId).set({
        'username': username,
        'email': email,
        'password': password,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('유저 추가 성공: $userId');
    } catch (e) {
      print('유저 추가 실패: $e');
      rethrow;
    }
  }

  /// 특정 유저에게 todo 추가
  Future<void> addTodo({
    required String userId,
    required String todoText,
    bool isCompleted = false,
    bool isRecommended = false,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('todos')
          .add({
        'todoText': todoText,
        'isCompleted': isCompleted,
        'isRecommended': isRecommended,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Todo 추가 성공');
    } catch (e) {
      print('Todo 추가 실패: $e');
      rethrow;
    }
  }

  /// 특정 유저에게 points 추가
  Future<void> addPoints({
    required String userId,
    required int amount,
    required String pointType,
    required String reason,
    String? relatedId,
    String? relatedType,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('points')
          .add({
        'amount': amount,
        'pointType': pointType,
        'reason': reason,
        'relatedId': relatedId,
        'relatedType': relatedType,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('포인트 추가 성공');
    } catch (e) {
      print('포인트 추가 실패: $e');
      rethrow;
    }
  }

  // ========== UPDATE (수정) ==========

  /// todo 완료 상태 변경
  Future<void> updateTodoStatus(
      String userId,
      String todoId,
      bool isCompleted,
      ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(todoId)
          .update({
        'isCompleted': isCompleted,
        'updatedAt': FieldValue.serverTimestamp(),
        if (isCompleted) 'completedAt': FieldValue.serverTimestamp(),
      });
      print('Todo 상태 변경 성공');
    } catch (e) {
      print('Todo 상태 변경 실패: $e');
      rethrow;
    }
  }

  /// 유저 정보 수정
  Future<void> updateUser(
      String userId,
      Map<String, dynamic> data,
      ) async {
    try {
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _db.collection('users').doc(userId).update(data);
      print('유저 정보 수정 성공');
    } catch (e) {
      print('유저 정보 수정 실패: $e');
      rethrow;
    }
  }

  // ========== DELETE (삭제) ==========

  /// todo 삭제
  Future<void> deleteTodo(String userId, String todoId) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('todos')
          .doc(todoId)
          .delete();
      print('Todo 삭제 성공');
    } catch (e) {
      print('Todo 삭제 실패: $e');
      rethrow;
    }
  }
}


