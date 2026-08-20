import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The six stages of the field-evidence workflow, in order. Every screen
/// that belongs to the linear flow renders a [WorkflowStepper] with its own
/// index so the officer always knows where they are and what's left —
/// this was the single biggest "hard to follow" gap in the original UI.
const List<String> kWorkflowSteps = ['Register', 'Device', 'Capture', 'Result', 'Custody', 'FSL'];

class WorkflowStepper extends StatelessWidget {
  final int currentIndex;

  const WorkflowStepper({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: List.generate(kWorkflowSteps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final leftDone = (i - 1) ~/ 2 < currentIndex;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                color: leftDone ? AppColors.accent : AppColors.border,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < currentIndex;
          final isCurrent = stepIndex == currentIndex;
          final color = isDone || isCurrent ? AppColors.accent : AppColors.border;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCurrent ? AppColors.accent : Colors.transparent,
                  border: Border.all(color: color, width: 1.6),
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 13, color: AppColors.accent)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isCurrent ? AppColors.accentOn : AppColors.textMuted,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                kWorkflowSteps[stepIndex],
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  color: isCurrent ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
