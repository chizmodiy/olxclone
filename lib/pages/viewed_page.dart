import 'package:flutter/material.dart';
import '../widgets/common_header.dart';

class ViewedPage extends StatelessWidget {
  const ViewedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      appBar: CommonHeader(),
      body: Padding(
        padding: EdgeInsets.only(top: 20),
        child: Center(
          child: Text('Переглянуті'),
        ),
      ),
    );
  }
} 