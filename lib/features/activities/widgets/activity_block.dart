import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class ActivityBlock extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String title;
  final String description;
  final Duration elapsedTime;
  final DateTime activityDate;
  final List<String> photos;

  const ActivityBlock({
    required this.firstName,
    required this.lastName,
    required this.title,
    required this.description,
    required this.elapsedTime,
    required this.activityDate,
    required this.photos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          // Header with name, date  and profile page
          Row(
            children: [
              // Name and surname
              Text("$firstName $lastName"),
              // Date
              Text("${DateFormat('dd-MM-yyyy hh:mm').format(activityDate)}"),
            ],
          ),
          // Title
          Row(children: [Text("$title")]),
          // Description
          Row(children: [Text("$description")]),

          // Photos from the run
          if (photos.isNotEmpty)
            SizedBox(
              height: 120,
              child: ListView.builder(
                // From left to right
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        photos[index],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
