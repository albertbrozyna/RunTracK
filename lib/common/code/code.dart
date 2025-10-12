// Expanded
// (
// child: Container(
// padding: EdgeInsets.only(top: 12,bottom: 12),
// margin: EdgeInsets.only(right: 5),
// decoration: BoxDecoration(
// color: Colors.white.withValues(alpha: 0.1),
// borderRadius: BorderRadius.circular(12),
// border: Border.all(color: Colors.white24, width: 1),
// ),
// child: Column(
// mainAxisAlignment: MainAxisAlignment.center,
// children: [
// Icon(
// Icons.access_time,
// color: Colors.white,
// size: 28,
// ),
// SizedBox(height: 5),
// Text(
// ActivityService.formatElapsedTime(AppData.trackState.elapsedTime),
// style: AppTextStyles.heading.copyWith(
// fontSize: 20,
// fontWeight: FontWeight.bold,
// color: Colors.white,
// ),
// ),
// Text(
// "Time",
// style: TextStyle(
// color: Colors.white70,
// fontSize: 14,
// ),
// ),
// ],
// ),
// ),
// ),
// // Distance
// Expanded(
// child: Container(
// padding: EdgeInsets.only(top: 12,bottom: 12),
// margin: EdgeInsets.only(left: 5),
// decoration: BoxDecoration(
// color: Colors.white.withValues(alpha: 0.1),
// borderRadius: BorderRadius.circular(12),
// border: Border.all(color: Colors.white24, width: 1),
// ),
// child: Column(
// mainAxisAlignment: MainAxisAlignment.center,
// children: [
// Icon(Icons.route, color: Colors.white, size: 28),
// SizedBox(height: 5),
// Text(
// "${widget.activityData.totalDistance?.toStringAsFixed(2)} km",
// style: AppTextStyles.heading.copyWith(
// fontSize: 20,
// fontWeight: FontWeight.bold,
// color: Colors.white,
// ),
// ),
// Text(
// "Distance",
// style: TextStyle(
// color: Colors.white70,
// fontSize: 14,
// ),
// ),
// ],
// )
// ,
// )
// ,
// )
// ,