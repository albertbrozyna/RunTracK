import 'package:run_track/features/competitions/data/models/result_record.dart';

class CompetitionResult {
  final String competitionId;
  final List<ResultRecord> ranking;

  CompetitionResult({
    required this.competitionId,
    required this.ranking,
  });

  factory CompetitionResult.fromJson(Map<String, dynamic> data) {
    final rankingList = (data['ranking'] as List<dynamic>?) ?? [];

    return CompetitionResult(
      competitionId: data['competitionId'] as String,
      ranking: rankingList
          .map((recordData) => ResultRecord.fromJson(recordData as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'competitionId': competitionId,
      'ranking': ranking.map((record) => record.toJson()).toList(),
    };
  }

  CompetitionResult copyWith({
    String? competitionId,
    List<ResultRecord>? ranking,
  }) {
    return CompetitionResult(
      competitionId: competitionId ?? this.competitionId,
      ranking: ranking ?? this.ranking,
    );
  }
}

