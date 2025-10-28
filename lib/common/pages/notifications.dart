import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:run_track/common/widgets/page_container.dart';
import 'package:run_track/models/notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<StatefulWidget> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {

  late List<AppNotification> notifications;

  @override
  void initState() {
    super.initState();
    initalize();
  }

  void initalize(){


  }

  void initalizeAsync(){

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Notifications")),
      body: PageContainer(
        child: SingleChildScrollView(child: Column(children: [])),
      ),
    );
  }
}
