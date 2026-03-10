import 'package:flutter/material.dart';

class Bare extends StatelessWidget {
  final int a;
  final int b;
  const Bare(this.a, this.b, {super.key});
  int get currentStep => a;
  int get currentStep1 => b;
  int get totalSteps => 2;
  double get progress1 => currentStep1 / totalSteps;
  double get progress => (currentStep - 0.9) / totalSteps;
  int get percent => (progress1 * 100).round();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 2,
        bottom: 0,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Step 1 of 2',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xff1f2937),
                  fontFamily: 'Nunito',
                  height: 24 / 16,
                ),
              ),
              Text(
                '$percent% complete',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Color(0xFF000080),
                  fontFamily: 'Nunito',
                  height: 20 / 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF000080)),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Academic Details & Preferences',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  color: Color(0xff64748b),
                  fontFamily: 'Nunito',
                  height: 20 / 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}