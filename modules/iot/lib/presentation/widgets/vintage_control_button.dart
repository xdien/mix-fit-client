import 'package:flutter/material.dart';

class VintageControlButton extends StatelessWidget {
  final VoidCallback onPressed;

  const VintageControlButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey[800]!,
              Colors.grey[900]!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 10,
              offset: Offset(4, 4),
            ),
            BoxShadow(
              color: Colors.grey[700]!,
              blurRadius: 10,
              offset: Offset(-4, -4),
            ),
          ],
          border: Border.all(
            color: Colors.grey[850]!,
            width: 4,
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(15),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[900]!,
                Colors.grey[800]!,
              ],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.settings,
              size: 50,
              color: Colors.amber[300],
            ),
          ),
        ),
      ),
    );
  }
}