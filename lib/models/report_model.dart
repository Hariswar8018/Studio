import 'dart:convert';

class QuestionReportModel {
  final String id;
  final String questionId;
  final String topicId;
  final String category; // 'grammar', 'vocab', 'kanji'
  final String level;
  final String questionText;
  final String reportedReason;
  final String userComment;
  final DateTime createdAt;
  final String status; // 'pending', 'resolved', 'dismissed'
  final Map<String, String> options;
  final String correctOption;

  QuestionReportModel({
    required this.id,
    required this.questionId,
    required this.topicId,
    required this.category,
    required this.level,
    required this.questionText,
    required this.reportedReason,
    this.userComment = '',
    required this.createdAt,
    this.status = 'pending',
    this.options = const {},
    this.correctOption = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionId': questionId,
      'topicId': topicId,
      'category': category,
      'level': level,
      'questionText': questionText,
      'reportedReason': reportedReason,
      'userComment': userComment,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'options': options,
      'correctOption': correctOption,
    };
  }

  factory QuestionReportModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    return QuestionReportModel(
      id: docId ?? map['id']?.toString() ?? '',
      questionId: map['questionId']?.toString() ?? '',
      topicId: map['topicId']?.toString() ?? '',
      category: map['category']?.toString() ?? 'grammar',
      level: map['level']?.toString() ?? 'N2',
      questionText: map['questionText']?.toString() ?? '',
      reportedReason: map['reportedReason']?.toString() ?? 'General Error',
      userComment: map['userComment']?.toString() ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: map['status']?.toString() ?? 'pending',
      options: map['options'] != null
          ? Map<String, String>.from(
              (map['options'] as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
            )
          : {},
      correctOption: map['correctOption']?.toString() ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory QuestionReportModel.fromJson(String source) =>
      QuestionReportModel.fromMap(json.decode(source) as Map<String, dynamic>);
}

