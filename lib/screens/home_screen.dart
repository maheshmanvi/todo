import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:todo/controllers/home_screen_controller.dart';
import 'package:todo/model/task_model.dart';
import 'package:todo/screens/add_edit_task.dart';
import 'package:todo/widgets/todo_card.dart';

import '../notification/notification_controller.dart';
import '../widgets/task_bottom_sheet_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late TabController _tabController;

  late final FocusNode _searchFocusNode = FocusNode();

  static final HomeScreenController _controller =
      Get.put(HomeScreenController());

  bool useGrid = false;
  bool _isDeleteMode = false;
  Set<int> _selectedTaskIds = {};
  String sortBy = 'Created on';
  String filterBy = 'None';

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 4, vsync: this)
      ..addListener(_handleTabChange);
    _controller.sortOption = sortBy;
    _controller.fetchTasks();
    // _controller.checkNotifications();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ModalRoute.of(context)?.addScopedWillPopCallback(() async {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
          return false; // Prevent default back button behavior
        }
        return true; // Allow default back button behavior
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    int newIndex = _tabController.index;
    if (_controller.selectedTab != newIndex) {
      _controller.selectedTab = newIndex;
      _controller.fetchTasks().whenComplete(() {});
    }
    log('_handleTabChange: AFTER: tabController.index: $newIndex, selectedTab: ${_controller.selectedTab}');
  }

  Widget _buildTaskTabContent({required int tabIndex}) {
    // padding: const EdgeInsets.fromLTRB(5.0, 8.0, 5.0, 5.0),
    return Obx(() {
      if (_controller.searchQuery.value.isNotEmpty &&
          _controller.filteredTasks.isEmpty) {
        return const Center(
            child: Text('Not found',
                style: TextStyle(fontSize: 18, color: Colors.grey)));
      }

      if (_controller.allTasks.isEmpty) {
        return _controller.showWelcomeMsg();
      }

      // return !_controller.isLoading.value // Check if data is loading
      //     ? (!useGrid ? _listView() : _gridView())
      //     : Center(child: CircularProgressIndicator()); // Show loading indicator
      if (!useGrid) {
        return _listView();
      } else {
        return _gridView();
        // return _gridView();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _controller.checkForPendingNotifications();
    return GestureDetector(
      onTap: () {
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.grey[200],
        // backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
        appBar: _isDeleteMode
            ? PreferredSize(
                preferredSize: const Size.fromHeight(75),
                child: deleteView(), // Show deleteView when in delete mode
              )
            : PreferredSize(
                preferredSize: const Size.fromHeight(75),
                child: AppBar(
                  toolbarHeight: 75,
                  automaticallyImplyLeading: false,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainer,
                  elevation: 0,
                  title: PreferredSize(
                    preferredSize: const Size.fromHeight(75),
                    child: Row(
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainer,
                              // color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.grey,
                                // Color of the border
                                // color: Theme.of(context).colorScheme.surfaceContainerHighest, // Color of the border
                                width: 1.0, // Width of the border
                              ),
                            ),
                            child: Row(
                              children: [
                                _searchBar(),
                                _sortMenu(),
                                _filterMenuTemp(),
                                _viewMenu(),
                                _optionsMenu(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        body: Column(
          children: [
            Container(
              height: 50,
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                // Allows horizontal scrolling of tabs if needed
                indicatorWeight: 3.0,
                dividerColor: Colors.grey[300],
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.0,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12.0,
                ),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.list_rounded, size: 18),
                    text: 'All Tasks(${_controller.allTasks.length})',
                    iconMargin: const EdgeInsets.only(
                        right: 4.0), // Adjusts the space between icon and text
                  ),
                  Tab(
                    icon: const Icon(Icons.done_all_rounded, size: 18),
                    text: 'Completed(${_controller.completedTasks.length})',
                    iconMargin: const EdgeInsets.only(right: 4.0),
                  ),
                  Tab(
                    icon: const Icon(Icons.hourglass_top_rounded, size: 18),
                    text: 'Pending(${_controller.pendingTasks.length})',
                    iconMargin: const EdgeInsets.only(right: 4.0),
                  ),
                  Tab(
                    icon: const Icon(Icons.error_outline_rounded, size: 18),
                    text: 'Overdue(${_controller.overdueTasks.length})',
                    iconMargin: const EdgeInsets.only(right: 4.0),
                  ),
                ],
                onTap: (index) {
                  _controller.selectedTab = index;
                  _controller.fetchTasks();
                },
              ),
            ),
            const SizedBox(height: 5.0),
            Expanded(
              child: Container(
                color: Colors.grey[200],
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTaskTabContent(tabIndex: 0),
                    _buildTaskTabContent(tabIndex: 1),
                    _buildTaskTabContent(tabIndex: 2),
                    _buildTaskTabContent(tabIndex: 3),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: _isDeleteMode
            ? null
            : FloatingActionButton(
                onPressed: () => _showEditScreen(null),
                tooltip: 'Add Task',
                backgroundColor: const Color(0xFFC80036),
                child: const Icon(Icons.add, color: Color(0xFFF5EDED)),
              ),
      ),
    );
  }

  Widget deleteView() {
    return AppBar(
      backgroundColor: const Color(0xFFC80036),
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: _toggleDeleteMode,
        icon: const Icon(Icons.close, color: Colors.white, size: 28),
      ),
      title: Text(
        '${_selectedTaskIds.length} selected',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.normal,
        ),
      ),
      actions: [
        IconButton(
          onPressed: _selectedTaskIds.length == _controller.allTasks.length
              ? _deselectAllTasks
              : _selectAllTasks,
          icon: Icon(
            _selectedTaskIds.length == _controller.allTasks.length
                ? Icons.deselect_rounded
                : Icons.select_all_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        IconButton(
          onPressed: () async {
            if (_selectedTaskIds.isEmpty) return;
            if (_selectedTaskIds.length == _controller.allTasks.length) {
              await _controller.deleteAllTasks();
            } else {
              for (int id in _selectedTaskIds) {
                await _controller.deleteTask(id);
              }
            }
            _controller.fetchTasks();
            _toggleDeleteMode();
          },
          icon: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  Widget _searchBar() {
    return Expanded(
      child: TextField(
        autofocus: false,
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: (query) {
          setState(() {
            _controller.updateSearchQuery(query);
          });
        },
        decoration: InputDecoration(
          hintText: 'Search event, meeting, etc ...',
          hintStyle: TextStyle(
            fontWeight: FontWeight.normal,
            color: Colors.grey[500],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30.0),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 13.0),
            child: Icon(Icons.search, color: Color(0xFF0C1844)),
          ),
        ),
        cursorColor: const Color(0xFF0C1844),
        style: const TextStyle(
          color: Color(0xFF0C1844),
        ),
      ),
    );
  }

  Widget _filterMenuTemp() {
    return PopupMenuButton<String>(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      onSelected: (value) {
        if (_controller.selectedFilters.contains(value)) {
          _controller.selectedFilters.remove(value);
        } else {
          _controller.selectedFilters.add(value);
        }
        _controller.filterOption = _controller.selectedFilters.isEmpty
            ? 'None'
            : _controller.selectedFilters.join(', ');
        // _updateFilterOptions();
      },
      tooltip: "Filter",
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Container(
              padding: EdgeInsets.zero,
              child: Text('Filter By: ',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
          ),
          const PopupMenuDivider(),

          // Date Filters
          PopupMenuItem<String>(
            enabled: false,
            child: Text('Date', style: Theme.of(context).textTheme.titleSmall),
          ),

          ..._buildFilterOptions(['Today', 'Tomorrow', 'Yesterday']),
          const PopupMenuDivider(),

          // Priority Filters
          PopupMenuItem<String>(
            enabled: false,
            child:
                Text('Priority', style: Theme.of(context).textTheme.titleSmall),
          ),
          ..._buildFilterOptions(['High', 'Medium', 'Low']),
          const PopupMenuDivider(),

          // Clear All and OK Buttons
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    _controller.selectedFilters.clear();
                    _controller.filterOption = 'None';
                    _updateFilterOptions();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Clear All'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateFilterOptions();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    // backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
                    backgroundColor: const Color.fromARGB(255, 248, 225, 225),
                  ),
                  child: const Text('OK'),
                )
              ],
            ),
          ),
        ];
      },
      icon: Icon(
        _controller.selectedFilters.isEmpty
            ? Icons.filter_alt_off
            : Icons.filter_alt,
        color: const Color(0xFF0C1844),
      ),
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(20.0),
      // ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2), // Border color
          // color: Theme.of(context).colorScheme.primary, // Border color
          width: 1.0, // Border width
        ),
      ),
      offset: const Offset(0, 40),
    );
  }

  List<PopupMenuItem<String>> _buildFilterOptions(List<String> options) {
    return options.map((option) {
      return PopupMenuItem<String>(
        value: option,
        child: Row(
          children: [
            Obx(() {
              return Checkbox(
                value: _controller.selectedFilters.contains(option),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _controller.selectedFilters.add(option);
                    } else {
                      _controller.selectedFilters.remove(option);
                    }
                    _controller.filterOption =
                        _controller.selectedFilters.isEmpty
                            ? 'None'
                            : _controller.selectedFilters.join(', ');
                    // _updateFilterOptions();
                  });
                },
              );
            }),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {});
                  if (_controller.selectedFilters.contains(option)) {
                    _controller.selectedFilters.remove(option);
                  } else {
                    _controller.selectedFilters.add(option);
                  }
                  _controller.filterOption = _controller.selectedFilters.isEmpty
                      ? 'None'
                      : _controller.selectedFilters.join(', ');
                  // _updateFilterOptions();
                },
                child: Text(option),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _updateFilterOptions() {
    _refreshTasks();
    log("_updateFilterOptions: updating task with filters: ${_controller.selectedFilters.isEmpty ? 'None' : _controller.selectedFilters.join(', ')}");
  }

  void _showEditScreen(TaskModel? task) async {
    final result = await Get.to(() => const AddEditTask(task: null));
    if (result != null) {
      _refreshTasks();
    }
  }

  Future<void> _refreshTasks() async {
    try {
      await _controller.fetchTasks();
    } catch (e) {
      log("ERROR HomeScreen._refreshTasks: $e");
    }
  }

  void _toggleDeleteMode() {
    setState(() {
      _isDeleteMode = !_isDeleteMode;
      if (!_isDeleteMode) {
        _selectedTaskIds.clear();
      }
    });
  }

  void _selectAllTasks() {
    setState(() {
      _selectedTaskIds = _controller.allTasks.map((task) => task.id!).toSet();
    });
  }

  void _deselectAllTasks() {
    setState(() {
      _selectedTaskIds.clear();
    });
  }

  void _updateSelectedTaskIds(int taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
      } else {
        _selectedTaskIds.add(taskId);
      }
      if (_selectedTaskIds.isEmpty) {
        _toggleDeleteMode();
      }
    });
  }

  Widget _sortMenu() {
    return PopupMenuButton<String>(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      onSelected: (value) {
        log("Selected value: $value");
        sortBy = value;
        _updateSortOption(value);
      },
      tooltip: "Sort",
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            enabled: false,
            child: Container(
              padding: EdgeInsets.zero,
              // child: Text('Sort By: $sortBy'),
              child: Text('Sort By: $sortBy',
                  style: Theme.of(context).textTheme.titleSmall),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: "Upcoming",
            child: const Row(
              children: [
                Icon(
                  Icons.upcoming_rounded,
                  size: 20,
                ),
                SizedBox(
                  width: 15,
                ),
                Text('Upcoming'),
              ],
            ),
            onTap: () {
              setState(() {
                // Handle selection
              });
            },
          ),
          PopupMenuItem<String>(
            value: "Priority",
            child: const Row(
              children: [
                Icon(Icons.outlined_flag_rounded, size: 20),
                SizedBox(
                  width: 15,
                ),
                Text('Priority'),
              ],
            ),
            onTap: () {
              setState(() {
                // Handle selection
              });
            },
          ),
          PopupMenuItem<String>(
            value: "Created on",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 20,
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Text('Created on'),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 36.0),
                  child: Text(
                    '(Default)',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 10,
                        fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                // Handle selection
              });
            },
          ),
          const PopupMenuDivider(),
          PopupMenuItem<String>(
            value: "Created on",
            child: Row(
              children: [
                Text(
                  'Clear All',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
                // color: Theme.of(context).colorScheme.surfaceTint)),
              ],
            ),
            onTap: () {
              setState(() {
                // Handle selection
              });
            },
          ),
        ];
      },
      icon: const Icon(Icons.sort_rounded, color: Color(0xFF0C1844)),
      // shape: RoundedRectangleBorder(
      //   borderRadius: BorderRadius.circular(20.0),
      // ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
        side: BorderSide(
          color: Colors.grey.withOpacity(0.2), // Border color
          // color: Theme.of(context).colorScheme.primary, // Border color
          width: 1.0, // Border width
        ),
      ),
      offset: const Offset(0, 40),
    );
  }

  void _updateSortOption(String value) {
    setState(() {
      sortBy = value;
      _controller.sortOption = value;
      // _controller.fetchTasks();
    });
  }

  Widget _viewMenu() {
    // MyUtils.showToast('Not updated');
    return IconButton(
      onPressed: () {
        setState(() {
          useGrid = !useGrid;
        });
      },
      icon: Icon(
        useGrid ? Icons.view_agenda_outlined : Icons.grid_view,
        color: const Color(0xFF0C1844),
      ),
    );
  }

  Widget _optionsMenu() {
    return Container(
      // margin: EdgeInsets.only(left: 7),
      decoration: BoxDecoration(
        // color: Theme.of(context).colorScheme.surfaceContainerHighest,
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(30), // Rounded corners
      ),

      child: PopupMenuButton<String>(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        onSelected: (value) {
          if (value == 'exit') {
            exit(0);
          }
        },
        tooltip: "Menu",
        itemBuilder: (BuildContext context) {
          return [
            PopupMenuItem<String>(
              enabled: false,
              value: "greet",
              padding: EdgeInsets.zero,
              // Remove default padding
              height: 0,
              child: Container(
                width: double.infinity,
                // Full width
                padding: const EdgeInsets.all(16),
                constraints: const BoxConstraints(
                  minHeight: 30, // Adjust as needed to remove space on top
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withOpacity(0.5),
                      Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withOpacity(0.0)
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  // borderRadius: BorderRadius.circular(4.0), // Add rounded corners
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      // Grey color for the bottom border
                      width: 1.0, // Thickness of 1.0 for the bottom border
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _controller.getGreeting(),
                      style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5.0), // Add some spacing
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              onTap: () {
                setState(() {
                  _controller.getGreeting();
                  _controller.fetchTasks();
                });
              },
            ),
            PopupMenuItem<String>(
              value: "add",
              child: Container(
                  padding: EdgeInsets.zero,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        size: 20,
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Text('Add task')
                    ],
                  )),
              onTap: () {
                setState(() {
                  _showEditScreen(null);
                  _controller.getGreeting();
                });
              },
            ),
            PopupMenuItem<String>(
              value: "delete",
              child: Container(
                  padding: EdgeInsets.zero,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.delete,
                        size: 20,
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Text('Delete'),
                    ],
                  )),
              onTap: () {
                setState(() {
                  _isDeleteMode = true;
                });
              },
            ),
            PopupMenuItem<String>(
              value: "refresh",
              child: Container(
                  padding: EdgeInsets.zero,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.refresh_rounded,
                        size: 20,
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Text('Refresh'),
                    ],
                  )),
              onTap: () {
                setState(() {
                  _controller.getGreeting();
                  _controller.fetchTasks();
                });
              },
            ),

            PopupMenuItem<String>(
              value: "All Notifications",
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Obx(() => Icon(
                        _controller.allowNotification.value
                            ? Icons.notifications_active
                            : Icons.notifications_off_rounded,
                        size: 20,
                      )),
                  const SizedBox(
                    width: 15,
                  ),
                  const Text('Notifications'),
                  const Spacer(),
                  Obx(() => Switch(
                        value: _controller.allowNotification.value,
                        onChanged: (bool value) {
                          _controller.allowNotification.value = value;
                          final notificationController =
                              Get.put(NotificationController());
                          if (value) {
                            for (var task in _controller.allTasks) {
                              log('Scheduling notification for all tasks');
                              notificationController
                                  .scheduleNotificationsForTask(task);
                            }
                          } else {
                            log('Clearing all notifications');
                            notificationController.clearAllNotifications();
                          }
                        },
                        inactiveTrackColor: Colors.white,
                      )),
                ],
              ),
              onTap: () {
                final notificationController =
                    Get.put(NotificationController());
                if (_controller.allowNotification.value) {
                  _controller.allowNotification.value = false;
                  notificationController.clearAllNotifications();
                } else {
                  _controller.allowNotification.value = true;
                  for (var task in _controller.allTasks) {
                    notificationController.scheduleNotificationsForTask(task);
                  }
                }
              },
            ),

            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: "exit",
              child: const Row(
                children: [
                  Icon(
                    Icons.exit_to_app_rounded,
                    size: 20,
                  ),
                  SizedBox(
                    width: 15,
                  ),
                  Text('Exit'),
                ],
              ),
              onTap: () {
                log('Application terminated!');
                exit(0);
              },
            ),
          ];
        },
        icon: Container(
          padding: const EdgeInsets.all(8.0), // Adjust the padding as needed
          decoration: BoxDecoration(
            color: Colors.grey[200],
            // color: Theme.of(context).colorScheme.errorContainer, // Dim background color (light gray in this example)
            // color: Theme.of(context).colorScheme.surfaceContainerLow, // Dim background color (light gray in this example)
            borderRadius: BorderRadius.circular(30.0), // Rounded corners
          ),
          child: const Icon(
            Icons.menu_rounded, color: Color(0xFF0C1844), // Icon color
          ),
        ),
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.circular(20.0),
        // ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
          side: BorderSide(
            color: Colors.grey.withOpacity(0.2), // Border color
            // color: Theme.of(context).colorScheme.primary, // Border color
            width: 1.0, // Border width
          ),
        ),

        offset: const Offset(0, 40),
      ),
    );
  }

/*----------------------------------------------------------------------------- -------------------------------*/

  // ListView layout

  Widget _listView() {
    return Obx(() {
      // Log task details (id, title, status) for all tasks in the final list
      // for (var task in _controller.allTasks) {
      //   log("_listView: Task ID: ${task.id}, Task Title: ${task.title}, Task Status: ${task.taskStatus.value}");
      // }
      return ListView.builder(
        itemCount: _controller.filteredTasks.length,
        itemBuilder: (context, index) {
          if (index < _controller.filteredTasks.length) {
            // log('_listView: ${_controller.filteredTasks.length}');
            final task = _controller.filteredTasks[index];
            return _toDoCard(task);
          }
          return const SizedBox.shrink();
        },
      );
    });
  }

  Widget _toDoCard(TaskModel task) {
    return TodoCard(
      task: task,
      isSelected: _selectedTaskIds.contains(task.id),
      isDeleteMode: _isDeleteMode,
      onTap: () {
        if (_isDeleteMode) {
          setState(() {
            if (_selectedTaskIds.contains(task.id)) {
              _selectedTaskIds.remove(task.id!);
            } else {
              _selectedTaskIds.add(task.id!);
            }
          });
        } else {
          _showTaskDetails(task);
        }
      },
      onLongPress: () {
        setState(() {
          if (!_isDeleteMode) {
            _isDeleteMode = true;
          }
          if (_selectedTaskIds.contains(task.id)) {
            _selectedTaskIds.remove(task.id!);
          } else {
            _selectedTaskIds.add(task.id!);
          }
        });
      },
      onSelectionChange: () {
        setState(() {
          if (_selectedTaskIds.contains(task.id)) {
            _selectedTaskIds.remove(task.id!);
          } else {
            _selectedTaskIds.add(task.id!);
          }
        });
      },
    );
  }

  Widget _gridView() {
    return Obx(() {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio: 1.17,
          ),
          itemCount: _controller.filteredTasks.length,
          itemBuilder: (context, index) {
            final task = _controller.filteredTasks[index];
            return _buildGridCard(
              task,
              onTap: () => _showTaskDetails(task),
              // onTap: () async {
              //   // TaskModel updatedTask = _controller.getTaskById(task.id);
              //   setState(() {
              //     _showTaskDetails(task);
              //   });
              // },
              onLongPress: () {
                setState(() {
                  if (!_isDeleteMode) {
                    _isDeleteMode = true;
                    _selectedTaskIds.add(task.id!);
                  }
                });
              },
              onSelectionChange: () {
                setState(() {
                  if (_selectedTaskIds.contains(task.id)) {
                    _selectedTaskIds.remove(task.id!);
                  } else {
                    _selectedTaskIds.add(task.id!);
                  }
                });
              },
              isSelected: _selectedTaskIds.contains(task.id!), isDeleteMode: _isDeleteMode,
            );
          },
        ),
      );
    });
  }

  Widget _buildGridCard(
      TaskModel task, {
        required bool isSelected,
        required void Function() onTap,
        required void Function() onLongPress,
        required void Function() onSelectionChange,
        required bool isDeleteMode,
      }) {
    final controller = Get.put(HomeScreenController());

    // Set the card color based on the selection and delete mode status
    Color? cardColor = isSelected && isDeleteMode
        ? Colors.grey[400] // Light dark color when selected in delete mode
        : isSelected
        ? Colors.grey[300] // Selected color when not in delete mode
        : Colors.grey[50]; // Default card color

    // Get the color for the checkbox and status based on task status
    // final checkboxColor = _getColorBasedOnTaskStatus(task.taskStatus.value ?? 0);
    final statusColor = _getColorBasedOnTaskStatus(task.taskStatus.value);

    return GestureDetector(
      onTap: () {
        if (isDeleteMode) {
          // Toggle selection when in delete mode
          onSelectionChange();
        } else {
          onTap(); // Regular tap behavior
        }
      },
      onLongPress: () {
        onLongPress();
        onSelectionChange();
      },
      child: Card(
        color: cardColor,
        margin: const EdgeInsets.all(0.0),
        elevation: 5.0,
        shadowColor: Colors.grey.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14.0, 12.0, 8.0, 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Checkbox and Title Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16.0,
                        color: Colors.black87,
                        decoration: task.taskStatus.value == 1
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  // Checkbox based on taskStatus
                  GestureDetector(
                    onTap: () {
                      if (task.taskStatus.value == 1) {
                        // Uncheck - Reset task status
                        task.taskStatus.value = 2; // Set back to pending
                        controller.updateTaskStatusPeriodically(task); // Re-evaluate status
                        controller.updateTaskStatus(task);
                      } else {
                        // Check - Mark task as complete
                        task.taskStatus.value = 1;
                        controller.updateTaskStatus(task);
                      }
                    },
                    child: Icon(
                      task.taskStatus.value == 1
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      // color: checkboxColor,
                      size: 24.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),

              // Status, Start Date, and Start Time
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Start Date
                  if (task.startDate?.isNotEmpty ?? false)
                    Row(
                      children: [
                        Icon(Icons.calendar_month_rounded, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4.0),
                        Text(
                          formatDateToText(task.startDate!),
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 5.0),

                  // Start Time
                  if (task.startTime?.isNotEmpty ?? false)
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4.0),
                        Text(
                          formatTimeTo12Hour(task.startTime!),
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8.0),
              // const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: Row(
                  children: [
                    if (task.taskStatus.value != '')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          task.taskStatus.value == 1
                              ? "Completed"
                              : task.taskStatus.value == 0
                              ? "Overdue"
                              : "Pending",
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.white,
                          ),
                        ),
                      ),

                    // const SizedBox(width: 10,),
                    const Spacer(),
                    // Priority Indicator
                    if (task.priority != "No priority set" && task.priority!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: _getColorBasedOnPriority(task.priority!),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Text(
                          task.priority!,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



// Helper method to get the priority color
  Color _getColorBasedOnPriority(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

// Helper method to get the status color
  Color _getColorBasedOnTaskStatus(int taskStatus) {
    switch (taskStatus) {
      case 1:
        return Colors.green;
      case 0:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Helper method to format date
  String formatDateToText(String? date) {
    if (date == null || date.isEmpty) {
      return "Invalid Date";
    }

    try {
      DateTime taskDate = DateFormat('dd-MM-yyyy').parse(date);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime tomorrow = today.add(const Duration(days: 1));
      DateTime yesterday = today.subtract(const Duration(days: 1));

      if (taskDate == today) {
        return "Today";
      } else if (taskDate == tomorrow) {
        return "Tomorrow";
      } else if (taskDate == yesterday) {
        return "Yesterday";
      } else {
        // return DateFormat('dd MMMM yyyy').format(taskDate);
        return DateFormat('EEE, dd MMM yyyy').format(taskDate);
      }
    } catch (e) {
      log('Date parsing error: $e');
      return "Invalid Date";
    }
  }

// Helper method to format time to 12-hour format
  String formatTimeTo12Hour(String time) {
    try {
      final timeFormat = DateFormat("HH:mm");
      final dateTime = timeFormat.parse(time);
      final formattedTime = DateFormat("hh:mm a").format(dateTime);
      return formattedTime;
    } catch (e) {
      return time;
    }
  }
  
  // void _showTaskDetails(TaskModel task) async {
  //   if(_searchFocusNode.hasFocus){
  //     _searchFocusNode.unfocus();
  //     return;
  //   }
  //   log('_showTaskDetails: ${task.toString()}');
  //   if (_isDeleteMode) {
  //     _updateSelectedTaskIds(task.id!);
  //   } else {
  //     await showDialog(
  //       context: context,
  //       builder: (BuildContext context) {
  //         return TaskAlertDialog(task: task);
  //       },
  //     );
  //   }
  // }

  void _showTaskDetails(TaskModel task) async {
    log('_showTaskDetails: ${task.toString()}');
    if (_isDeleteMode) {
      _updateSelectedTaskIds(task.id!);
    } else {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        // Allows the bottom sheet to expand to full screen height if necessary
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (BuildContext context) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 700.0, // Set the max height to 600 pixels
              ),
              child: IntrinsicHeight(
                child: TaskBottomSheetContent(task: task),
              ),
              // child: IntrinsicHeight(
              //   child: TaskAlertDialog(task: task),
              // ),
            ),
          );
        },
      );
    }
  }

  // Color _getPriorityColor(String priority) {
  //   switch (priority) {
  //     case 'High':
  //       return Colors.red;
  //       // return const Color(0xFFFF9B9B);
  //     case 'Medium':
  //       return Colors.orange;
  //       // return const Color(0xFFFFD6A5);
  //     case 'Low':
  //       return Colors.green;
  //       // return const Color(0xFFFFFEC4);
  //     default:
  //       return Colors.grey;
  //   }
  // }


}
