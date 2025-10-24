import 'package:flutter/cupertino.dart';

class PageContainer extends StatelessWidget {
  final Widget? child;


  const PageContainer({super.key, this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: Colors.t,
        ),
        image: DecorationImage(
          image: AssetImage("assets/appBg4.jpg"),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.50), BlendMode.darken),
        ),
        height: double.infinity,
        width: double.infinity,
        child: Padding(padding: EdgeInsets.all(10),
          child: child,)
    )
  }

}
