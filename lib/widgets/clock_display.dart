import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ClockDisplay extends StatelessWidget {
  final bool isLarge;

  const ClockDisplay({super.key, this.isLarge = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

        return Text(
          time,
          style: TextStyle(
            fontSize: isLarge ? 56 : 32,
            fontWeight: FontWeight.w300,
            color: AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
