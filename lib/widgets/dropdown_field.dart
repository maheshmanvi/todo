import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DropdownField extends StatelessWidget {
  final String label;
  final RxString selectedValue;
  final List<String> options;

  const DropdownField({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {

    return Obx(() {
      final currentValue = options.contains(selectedValue.value)
          ? selectedValue.value
          : options.first;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        decoration: BoxDecoration(
          // color: Color.fromARGB(60, 255, 0, 0),
          color: const Color.fromARGB(10, 255, 0, 0),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            icon: const Icon(Icons.keyboard_arrow_down,),
            value: currentValue,
            padding: const EdgeInsets.only(right: 20),
            isExpanded: true,
            hint: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                '$label: $currentValue',
                style: TextStyle(
                  color: Colors.grey[900],
                  fontSize: 18.0,
                ),
              ),
            ),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Center(
                  child: Text(
                    option,
                    style: TextStyle(fontSize: 16.0, color: Colors.grey[900]),
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                selectedValue.value = newValue;
              }
            },
          ),
        ),
      );
    });
  }
}
