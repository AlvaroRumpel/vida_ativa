import 'package:flutter/material.dart';

class SlotSkeleton extends StatefulWidget {
  const SlotSkeleton({super.key});

  @override
  State<SlotSkeleton> createState() => _SlotSkeletonState();
}

class _SlotSkeletonState extends State<SlotSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (context, child) {
        return Column(
          children: List.generate(4, (index) {
            return Opacity(
              opacity: _opacity.value,
              child: Container(
                height: 72,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
