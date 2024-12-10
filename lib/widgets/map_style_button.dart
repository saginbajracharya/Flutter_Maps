import 'package:flutter/material.dart';

class MapStyleButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onPressed;

  const MapStyleButton({
    super.key,
    required this.title,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.black : Colors.grey,
        foregroundColor: isSelected ? Colors.white : null,
        padding: const EdgeInsets.only(left:5,right:5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Less rounded
          side: BorderSide(
            color: isSelected ? Colors.grey : Colors.black, // Border color
            width: 2, // Border width
          ),
        ),
      ),
      child: Text(title,style: const TextStyle(fontSize: 12)),
    );
  }
}