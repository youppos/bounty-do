import 'package:flutter/material.dart';
import '../../models/task_model.dart';
import '../theme/app_theme.dart';
import 'dart:ui';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onComplete;
  final bool isGrid;

  const TaskCard({
    super.key,
    required this.task,
    required this.onComplete,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    Color priorityColor = AppTheme.getPriorityColor(task.priority.index);
    
    // 列表模式 3:1 宽高比，宫格模式则1:1
    double width = MediaQuery.of(context).size.width - 32;
    double height = isGrid ? (width / 2 - 8) : width / 3;

    return Container(
      width: isGrid ? height : width,
      height: height,
      margin: EdgeInsets.only(bottom: 16, right: isGrid ? 0 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).cardColor.withOpacity(0.2),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: priorityColor.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: isGrid ? 16 : 18,
                          fontWeight: FontWeight.bold,
                          color: task.isCompleted ? Colors.grey : Colors.white,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!task.isCompleted)
                      IconButton(
                        icon: Icon(Icons.check_circle_outline, color: priorityColor, size: 28),
                        onPressed: onComplete,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      )
                    else
                      const Icon(Icons.check_circle, color: Colors.grey, size: 28),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      "+${task.coinReward}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
