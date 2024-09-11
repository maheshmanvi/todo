import 'package:get/get.dart';

class FilterController extends GetxController {
  // Observable set of selected filters
  var selectedFilters = <String>{}.obs;

  // Toggle the presence of a filter
  void toggleFilter(String filter) {
    if (selectedFilters.contains(filter)) {
      selectedFilters.remove(filter);
    } else {
      selectedFilters.add(filter);
    }
  }

  // Clear all filters
  void clearFilters() {
    selectedFilters.clear();
  }

  // Get the display text for the filter menu
  String get filterDisplayText {
    return selectedFilters.isEmpty ? 'None' : selectedFilters.join(', ');
  }
}
