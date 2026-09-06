import 'dart:ui';
import 'package:flutter/material.dart';

import '../models/marks_model.dart';
import '../services/marks_service.dart';

class MarksScreen extends StatefulWidget {
  const MarksScreen({super.key, required this.marksService});
  final MarksService marksService;

  @override
  State<MarksScreen> createState() => _MarksScreenState();
}

class _MarksScreenState extends State<MarksScreen> {
  List<CourseMarks> _marks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMarks();
  }

  Future<void> _loadMarks() async {
    try {
      final marks = await widget.marksService.getMarks();
      if (!mounted) return;
      setState(() {
        _marks = marks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'CIA Marks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Background Canvas
          Positioned.fill(child: _buildBackgroundCanvas()),

          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_error != null)
            Center(
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            )
          else
            SafeArea(
              child: ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _marks.length,
                separatorBuilder: (_, __) => const SizedBox(height: 20),
                itemBuilder: (context, index) =>
                    _buildCourseCard(_marks[index]),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COURSE CARD
  // ---------------------------------------------------------------------------
  Widget _buildCourseCard(CourseMarks course) {
    return _GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top: Course Code - Course Title
          Text(
            '${course.courseCode} - ${course.courseName}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 18),

          // Middle: Component Boxes (Expanded Row)
          if (!course.marksAvailable)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.pending_actions_rounded,
                    color: Colors.white54,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Marks not available yet',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            )
          else ...[
            Row(
              children: course.components
                  .map(
                    (c) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _buildComponentBox(c),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.white24, height: 1),
            ),

            // Bottom: Total 50 | 100
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${course.totals?.outOf100.toStringAsFixed(1) ?? '--'} / 100',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // INDIVIDUAL COMPONENT BOX
  // ---------------------------------------------------------------------------
  Widget _buildComponentBox(MarkComponent component) {
    final hasMark = component.mark != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            component.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasMark ? '${component.mark}' : '--',
            style: TextStyle(
              color: hasMark ? Colors.white : Colors.white38,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '/${component.maxMark.toInt()}',
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // BACKGROUND CANVAS
  // ---------------------------------------------------------------------------
  Widget _buildBackgroundCanvas() {
    return Container(
      color: const Color(0xFF0F0E17),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x33FF9500),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x338B0000),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 90, sigmaY: 90),
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// REUSABLE GLASS CONTAINER
// ---------------------------------------------------------------------------
class _GlassContainer extends StatelessWidget {
  const _GlassContainer({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final r = borderRadius ?? BorderRadius.circular(24);

    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: r,
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
