import 'package:flutter/material.dart';

class LiquorKilnScreen extends StatefulWidget {
  @override
  _LiquorKilnChartState createState() => _LiquorKilnChartState();
}

class _LiquorKilnChartState extends State<LiquorKilnScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold( // Thêm Scaffold 
      body: Container(
        // Thêm nội dung của bạn ở đây
        child: Center(
          child: Text('Liquor Kiln Content'),
        ),
      ),
    );
  }
}