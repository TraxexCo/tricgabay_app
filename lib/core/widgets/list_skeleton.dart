import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../l10n/app_l10n.dart';

class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.loading,
    liveRegion: true,
    child: ExcludeSemantics(
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(0.6, 14),
                const SizedBox(height: 12),
                _bar(0.9, 10),
                const SizedBox(height: 8),
                _bar(0.4, 10),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _bar(double widthFactor, double height) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}
