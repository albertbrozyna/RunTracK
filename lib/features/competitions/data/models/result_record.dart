class ResultRecord {
  final String recordId;
  final String userUid;
  final String? activityId;
  final String firstName;
  final String lastName;
  final Duration time;
  final double distance;
  final bool finished;

  ResultRecord({
    required this.recordId,
    required this.userUid,
    required this.firstName,
    required this.lastName,
    required this.time,
    required this.distance,
    required this.finished,
    this.activityId
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
      'firstName': firstName,
      'lastName': lastName,
      'timeInSeconds': time.inSeconds,
      'distance': distance,
      'finished': finished,
    };
  }

  factory ResultRecord.fromJson(Map<String, dynamic> json) {
    return ResultRecord(
      recordId: json['recordId'] as String,
      userUid: json['userUid'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      time: Duration(seconds: json['timeInSeconds'] as int),
      distance: (json['distance'] as num).toDouble(),
      finished: json['finished'] as bool,
    );
  }

  ResultRecord copyWith({
    String? recordId,
    String? userUid,
    int? finalPlace,
    String? firstName,
    String? lastName,
    Duration? time,
    double? distance,
    bool? finished,
  }) {
    return ResultRecord(
      recordId: recordId ?? this.recordId,
      userUid: userUid ?? this.userUid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      time: time ?? this.time,
      distance: distance ?? this.distance,
      finished: finished ?? this.finished,
    );
  }
}
