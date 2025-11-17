class CompetitionResult {
  final String competitionId;
  final List<Record> ranking;

  CompetitionResult({
    required this.competitionId,
    required this.ranking,
  }) {
    ranking.sort((a, b) => a.finalPlace.compareTo(b.finalPlace));
  }

  factory CompetitionResult.fromJson(Map<String, dynamic> data) {
    final rankingList = (data['ranking'] as List<dynamic>?) ?? [];

    return CompetitionResult(
      competitionId: data['competitionId'] as String,
      ranking: rankingList
          .map((recordData) => Record.fromJson(recordData as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ranking': ranking.map((record) => record.toJson()).toList(),
    };
  }

  CompetitionResult copyWith({
    String? competitionId,
    List<Record>? ranking,
  }) {
    return CompetitionResult(
      competitionId: competitionId ?? this.competitionId,
      ranking: ranking ?? this.ranking,
    );
  }
}

class Record {
  final String recordId;
  final String userUid;
  final int finalPlace;
  final String firstName;
  final String lastName;
  final Duration time;
  final double distance;
  final bool finished;

  Record({
    required this.recordId,
    required this.userUid,
    required this.finalPlace,
    required this.firstName,
    required this.lastName,
    required this.time,
    required this.distance,
    required this.finished,
  });

  String get formattedTime {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(time.inHours);
    final minutes = twoDigits(time.inMinutes.remainder(60));
    final seconds = twoDigits(time.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  Map<String, dynamic> toJson() {
    return {
      'recordId': recordId,
      'userUid': userUid,
      'finalPlace': finalPlace,
      'firstName': firstName,
      'lastName': lastName,
      'timeInSeconds': time.inSeconds,
      'distance': distance,
      'finished': finished,
    };


  }

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      recordId: json['recordId'] as String,
      userUid: json['userUid'] as String,
      finalPlace: json['finalPlace'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      time: Duration(seconds: json['timeInSeconds'] as int),
      distance: (json['distance'] as num).toDouble(),
      finished: json['finished'] as bool,
    );
  }

  Record copyWith({
    String? recordId,
    String? userUid,
    int? finalPlace,
    String? firstName,
    String? lastName,
    Duration? time,
    double? distance,
    bool? finished,
  }) {
    return Record(
      recordId: recordId ?? this.recordId,
      userUid: userUid ?? this.userUid,
      finalPlace: finalPlace ?? this.finalPlace,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      time: time ?? this.time,
      distance: distance ?? this.distance,
      finished: finished ?? this.finished,
    );
  }
}