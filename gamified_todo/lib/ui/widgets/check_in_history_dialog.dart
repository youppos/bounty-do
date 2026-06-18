import 'package:flutter/material.dart';
import '../../models/check_in_model.dart';

void showCheckInHistoryDialog(BuildContext context, CheckInModel item) {
  showDialog(
    context: context,
    builder: (context) {
      DateTime focusedMonth = DateTime.now();
      return StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final primaryColor = Theme.of(context).primaryColor;

          // Days in grid calculation (Monday to Sunday)
          final firstDay = DateTime(focusedMonth.year, focusedMonth.month, 1);
          final weekdayOfFirst = firstDay.weekday; // 1 = Monday, 7 = Sunday
          final prefixEmptyDays = weekdayOfFirst - 1;
          final daysInMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 0).day;
          
          final gridDays = <DateTime>[];
          final prevMonth = DateTime(focusedMonth.year, focusedMonth.month - 1, 1);
          final prevMonthDays = DateTime(focusedMonth.year, focusedMonth.month, 0).day;
          
          // Trailing days from previous month
          for (int i = prefixEmptyDays - 1; i >= 0; i--) {
            gridDays.add(DateTime(prevMonth.year, prevMonth.month, prevMonthDays - i));
          }
          // Days of current month
          for (int i = 1; i <= daysInMonth; i++) {
            gridDays.add(DateTime(focusedMonth.year, focusedMonth.month, i));
          }
          // Leading days from next month to complete the grid (multiple of 7)
          final totalCells = gridDays.length;
          int nextMonthDaysNeeded = 0;
          if (totalCells % 7 != 0) {
            nextMonthDaysNeeded = 7 - (totalCells % 7);
          }
          final nextMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 1);
          for (int i = 1; i <= nextMonthDaysNeeded; i++) {
            gridDays.add(DateTime(nextMonth.year, nextMonth.month, i));
          }

          // Calculate checked-in count for focusedMonth
          int checkInCount = 0;
          for (int i = 1; i <= daysInMonth; i++) {
            final dStr = "${focusedMonth.year}-${focusedMonth.month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}";
            if (item.history.contains(dStr)) {
              checkInCount++;
            }
          }

          String monthYearStr = "${focusedMonth.year}年${focusedMonth.month}月";

          return Dialog(
            backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Container(
              width: 320,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '打卡历程',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        color: isDark ? Colors.white54 : Colors.black45,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(height: 1, color: Colors.white12),
                  const SizedBox(height: 12),
                  // Month Navigator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        color: isDark ? Colors.white70 : Colors.black87,
                        onPressed: () {
                          setModalState(() {
                            focusedMonth = DateTime(focusedMonth.year, focusedMonth.month - 1, 1);
                          });
                        },
                      ),
                      Text(
                        monthYearStr,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: isDark ? Colors.white70 : Colors.black87,
                        onPressed: () {
                          setModalState(() {
                            focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + 1, 1);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Title of the check-in
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Weekday headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['一', '二', '三', '四', '五', '六', '日'].map((w) {
                      return SizedBox(
                        width: 32,
                        child: Text(
                          w,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // Month Days Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: gridDays.length,
                    itemBuilder: (context, index) {
                      final day = gridDays[index];
                      final isCurrentMonth = day.month == focusedMonth.month;
                      final isToday = day.year == DateTime.now().year &&
                          day.month == DateTime.now().month &&
                          day.day == DateTime.now().day;
                      
                      String dateStr = "${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
                      final isChecked = item.history.contains(dateStr);

                      Color? textColor;
                      BoxDecoration? decoration;

                      if (!isCurrentMonth) {
                        textColor = isDark ? Colors.white10 : Colors.black12;
                      } else {
                        if (isChecked) {
                          textColor = Colors.white;
                          decoration = const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          );
                        } else if (isToday) {
                          textColor = primaryColor;
                          decoration = BoxDecoration(
                            border: Border.all(color: primaryColor, width: 1.5),
                            shape: BoxShape.circle,
                          );
                        } else {
                          textColor = isDark ? Colors.white70 : Colors.black87;
                        }
                      }

                      return Center(
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: decoration,
                          alignment: Alignment.center,
                          child: Text(
                            day.day.toString(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isChecked || isToday ? FontWeight.bold : FontWeight.normal,
                              color: textColor,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Footer Stats
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "本月已打卡: $checkInCount 天",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
