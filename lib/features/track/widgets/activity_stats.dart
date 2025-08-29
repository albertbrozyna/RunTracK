import 'package:flutter/cupertino.dart';

class RunStats extends StatelessWidget{
  final double totalDistance;
  final String pace;

  const RunStats({
    Key? key,
    required this.totalDistance,
    required this.pace
}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return  Row(
        children: [
          Text(
            "Distance: ${(totalDistance / 1000).toStringAsFixed(2)} km",
            style: TextStyle(fontSize: 18),
          ),
          Text(
            "Pace: $pace",
            style: TextStyle(fontSize: 18),
          ),
        ]
    );
  }


}
