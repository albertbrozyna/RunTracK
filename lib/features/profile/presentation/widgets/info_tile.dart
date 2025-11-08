import 'package:flutter/material.dart';

class ListInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool endDivider;

  const ListInfoTile({super.key, required this.icon, required this.title,this.endDivider = true});

  @override
  Widget build(BuildContext context) {
    final TextEditingController valueController = TextEditingController(text: title);

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: TextField(
              controller: valueController,
              readOnly: true,
              enabled: false,
              textAlign: TextAlign.center,
              decoration: InputDecoration(prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Icon(icon, color: Colors.white,size: 26,),
              ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide.none
                )

              ),

              style: TextStyle(
                color: Colors.white
              ),
            ),
          ),
          if(endDivider)
            Divider(color: Colors.white60, thickness: 1),
        ],
      ),
    );
  }
}
