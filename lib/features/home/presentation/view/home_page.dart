import 'package:date_picker_timeline/date_picker_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:to_do_app/core/controllers/task_controller.dart';
import 'package:to_do_app/core/services/notification_services.dart';
import 'package:to_do_app/core/services/theme_services.dart';
import 'package:to_do_app/core/size_config.dart';
import 'package:to_do_app/core/theme.dart';
import 'package:to_do_app/core/widgets/custom_button.dart';
import 'package:to_do_app/core/widgets/task_tile.dart';
import 'package:to_do_app/features/add_task/data/models/task.dart';
import 'package:to_do_app/features/add_task/presentation/view/add_task_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late NotifyHelper notifyHelper;

  @override
  void initState() {
    super.initState();
    notifyHelper = NotifyHelper();
    notifyHelper.requestIOSPermissions();
    notifyHelper.initializeNotification();
    _taskController.getTasks();
  }

  final TaskController _taskController = Get.put(TaskController());
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: _appBar(),
      body: Column(
        children: [
          _addTaskBar(),
          _addDateBar(),
          const SizedBox(height: 6),
          _showTasks(),
        ],
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      leading: IconButton(
        onPressed: () => ThemeServices().switchTheme(),
        icon: Icon(
          Get.isDarkMode
              ? Icons.wb_sunny_outlined
              : Icons.nightlight_round_outlined,
          size: 24,
          color: Get.isDarkMode ? Colors.white : darkGreyClr,
        ),
      ),
      elevation: 0,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      actions: [
        IconButton(
          icon: const Icon(
            Icons.cleaning_services_outlined,
            size: 24,
            color: Colors.red,
          ),
          onPressed: () {
            notifyHelper.cancelAllNotification();
            _taskController.deleteAllTasks();
          },
        ),
        const CircleAvatar(
          backgroundImage: AssetImage('images/person.jpeg'),
          radius: 18,
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  _addTaskBar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 10, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMMd().format(DateTime.now()),
                style: subHeadingStyle,
              ),
              Text('Today', style: headingStyle),
            ],
          ),
          CustomButton(
            label: '+ Add Task',
            onTap: () async {
              await Get.to(() => const AddTaskPage());
              _taskController.getTasks();
            },
          )
        ],
      ),
    );
  }

  _addDateBar() {
    return Container(
      margin: const EdgeInsets.only(left: 10, top: 6),
      child: DatePicker(
        DateTime.now(),
        width: 70,
        height: 100,
        initialSelectedDate: DateTime.now(),
        selectedTextColor: Colors.white,
        selectionColor: primaryClr,
        dateTextStyle: GoogleFonts.lato(
          textStyle: const TextStyle(
              color: Colors.grey, fontSize: 20, fontWeight: FontWeight.w600),
        ),
        dayTextStyle: GoogleFonts.lato(
          textStyle: const TextStyle(
              color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        monthTextStyle: GoogleFonts.lato(
          textStyle: const TextStyle(
              color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        onDateChange: (newDate) => setState(() => _selectedDate = newDate),
      ),
    );
  }

  Future<void> _onRefresh() async {
    _taskController.getTasks();
  }

  _showTasks() {
    return Expanded(
      child: Obx(() {
        if (_taskController.taskList.isEmpty) {
          return _noTaskMesg();
        } else {
          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.builder(
              scrollDirection: SizeConfig.orientation == Orientation.landscape
                  ? Axis.horizontal
                  : Axis.vertical,
              itemBuilder: (BuildContext contex, int index) {
                var task = _taskController.taskList[index];
                if (task.date == DateFormat.yMd().format(_selectedDate) ||
                    task.repeat == 'Daily' ||
                    (task.repeat == 'Weekly' &&
                        _selectedDate
                                    .difference(
                                        DateFormat.yMd().parse(task.date!))
                                    .inDays %
                                7 ==
                            0) ||
                    (task.repeat == 'Monthly' &&
                        DateFormat.yMd().parse(task.date!).day ==
                            _selectedDate.day)) {
                  var hour = task.startTime.toString().split(':')[0];
                  var minutes = task.startTime.toString().split(':')[1];
                  debugPrint('My time is ' + hour);
                  debugPrint('My minutes is ' + minutes);

                  var date = DateFormat.jm().parse(task.startTime!);
                  var myTime = DateFormat('HH:mm').format(date);

                  notifyHelper.scheduledNotification(
                    int.parse(myTime.toString().split(':')[0]),
                    int.parse(myTime.toString().split(':')[1]),
                    task,
                  );
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 1375),
                    child: SlideAnimation(
                      horizontalOffset: 300,
                      child: FadeInAnimation(
                        child: GestureDetector(
                          onTap: () => showBottomSheet(context, task),
                          child: TaskTile(task),
                        ),
                      ),
                    ),
                  );
                } else {
                  return Container();
                }
              },
              itemCount: _taskController.taskList.length,
            ),
          );
        }
      }),
    );
  }

  _noTaskMesg() {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 2000),
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                direction: SizeConfig.orientation == Orientation.landscape
                    ? Axis.horizontal
                    : Axis.vertical,
                children: [
                  SizeConfig.orientation == Orientation.landscape
                      ? const SizedBox(height: 6)
                      : const SizedBox(height: 220),
                  SvgPicture.asset(
                    'images/task.svg',
                    colorFilter: ColorFilter.mode(primaryClr, BlendMode.srcIn),
                    height: 90,
                    semanticsLabel: 'Task',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                    child: Text(
                      'You do not have any tasks yet!\nAdd new tasks to make your days productive.',
                      style: subTitleStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizeConfig.orientation == Orientation.landscape
                      ? const SizedBox(height: 120)
                      : const SizedBox(height: 180),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  showBottomSheet(BuildContext contex, Task task) {
    Get.bottomSheet(
      SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.only(top: 4),
          width: SizeConfig.screenWidth,
          height: (SizeConfig.orientation == Orientation.landscape)
              ? (task.isCompleted == 1
                  ? SizeConfig.screenHeight * 0.6
                  : SizeConfig.screenHeight * 0.8)
              : (task.isCompleted == 1
                  ? SizeConfig.screenHeight * 0.3
                  : SizeConfig.screenHeight * 0.39),
          color: Get.isDarkMode ? darkHeaderClr : Colors.white,
          child: Column(
            children: [
              Flexible(
                child: Container(
                  height: 6,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              task.isCompleted == 1
                  ? Container()
                  : _buildBottomSheet(
                      label: 'Task Completed',
                      onTap: () {
                        notifyHelper.cancelNotification(task);
                        _taskController.markTaskCompleted(task.id!);
                        Get.back();
                      },
                      clr: primaryClr,
                    ),
              _buildBottomSheet(
                label: 'Delete Task',
                onTap: () {
                  notifyHelper.cancelNotification(task);
                  _taskController.deleteTask(task);
                  Get.back();
                },
                clr: Colors.red[300]!,
              ),
              Divider(color: Get.isDarkMode ? Colors.grey : darkGreyClr),
              _buildBottomSheet(
                label: 'Cancel',
                onTap: () => Get.back(),
                clr: primaryClr,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  _buildBottomSheet({
    required String label,
    required Function() onTap,
    required Color clr,
    bool isClose = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: 65,
        width: SizeConfig.screenWidth * 0.9,
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: isClose
                ? Get.isDarkMode
                    ? Colors.grey[600]!
                    : Colors.grey[300]!
                : clr,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isClose ? Colors.transparent : clr,
        ),
        child: Center(
          child: Text(
            label,
            style:
                isClose ? titleStyle : titleStyle.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
