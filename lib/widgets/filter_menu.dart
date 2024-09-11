import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/filter_controller.dart'; // Import your FilterController

class FilterMenu extends StatelessWidget {
  const FilterMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final FilterController filterController =
        Get.find(); // Get the controller instance

    return PopupMenuButton<String>(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      onSelected: (value) {
        filterController.toggleFilter(value);
      },
      tooltip: "Filter",
      itemBuilder: (BuildContext context) {
        return [
          // Filter By Text
          PopupMenuItem<String>(
            enabled: false,
            child: Obx(() {
              return Text(
                'Filter By: ${filterController.filterDisplayText}',
                style: Theme.of(context).textTheme.titleSmall,
              );
            }),
          ),
          const PopupMenuDivider(),

          // Date Filters
          PopupMenuItem<String>(
            enabled: false,
            child: Text('Date', style: Theme.of(context).textTheme.titleSmall),
          ),
          ..._buildFilterOptions(
              ['Today', 'Upcoming', 'Overdue'], filterController),
          const PopupMenuDivider(),

          // Priority Filters
          PopupMenuItem<String>(
            enabled: false,
            child:
                Text('Priority', style: Theme.of(context).textTheme.titleSmall),
          ),
          ..._buildFilterOptions(['High', 'Medium', 'Low'], filterController),
          const PopupMenuDivider(),

          // Clear All and OK Buttons
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    filterController.clearFilters(); // Clear all filters
                  },
                  child: const Text('Clear All'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss the menu
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ];
      },
      icon: Obx(() {
        return Icon(
          filterController.selectedFilters.isEmpty
              ? Icons.filter_alt_off
              : Icons.filter_alt,
          color: const Color(0xFF0C1844),
        );
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      offset: const Offset(0, 40),
    );
  }

  List<PopupMenuItem<String>> _buildFilterOptions(
      List<String> options, FilterController filterController) {
    return options.map((option) {
      return PopupMenuItem<String>(
        value: option,
        child: Row(
          children: [
            Obx(() {
              return Checkbox(
                value: filterController.selectedFilters.contains(option),
                onChanged: (bool? value) {
                  filterController.toggleFilter(option);
                },
              );
            }),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  filterController.toggleFilter(option);
                },
                child: Obx(() {
                  return Text(option);
                }),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
