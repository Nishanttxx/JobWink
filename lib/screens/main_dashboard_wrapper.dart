import 'package:flutter/material.dart';
import '../screens/job_prediction_screen.dart';
import '../screens/resume_editor_screen.dart';
import '../screens/swipe_matcher_screen.dart';
import '../widgets/app_layout.dart';

class MainDashboardWrapper extends StatefulWidget {
  final int initialIndex;

  const MainDashboardWrapper({
    super.key,
    this.initialIndex = 2,
  });

  @override
  State<MainDashboardWrapper> createState() => _MainDashboardWrapperState();
}

class _MainDashboardWrapperState extends State<MainDashboardWrapper> {
  late PageController _pageController;
  late int _currentIndex;
  final GlobalKey<ResumeEditorScreenState> _resumeEditorKey = GlobalKey<ResumeEditorScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
      case 2:
        return 'AI Resume Tailoring Studio';
      case 1:
        return 'Swipe Job Matcher';
      case 3:
        return 'Job Match ML Prediction';
      case 4:
        return 'ATS Score Analysis';
      default:
        return 'JobWink Workspace';
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = _resumeEditorKey.currentState;

    return AppLayout(
      activeIndex: _currentIndex,
      title: _getTabTitle(_currentIndex),
      activeSubSectionIndex: editorState?.activeSubSectionIndex ?? 0,
      sectionCounts: editorState?.sectionCounts,
      onSubSectionSelected: (subIndex) {
        if (_currentIndex != 2 && _currentIndex != 0) {
          _pageController.jumpToPage(2);
          setState(() {
            _currentIndex = 2;
          });
        }
        _resumeEditorKey.currentState?.handleSubSectionSelected(subIndex);
      },
      onResumePreview: () {
        if (_currentIndex != 2 && _currentIndex != 0) {
          _pageController.jumpToPage(2);
          setState(() {
            _currentIndex = 2;
          });
        }
        _resumeEditorKey.currentState?.handleSubSectionSelected(0);
      },
      onGenerate: () {
        if (_currentIndex != 2 && _currentIndex != 0) {
          _pageController.jumpToPage(2);
          setState(() {
            _currentIndex = 2;
          });
        }
        _resumeEditorKey.currentState?.handleGenerate();
      },
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: [
          ResumeEditorScreen(key: _resumeEditorKey),
          const SwipeMatcherScreen(),
          ResumeEditorScreen(key: _resumeEditorKey),
          const JobPredictionScreen(),
          const ResumeEditorScreen(initialTab: 3),
        ],
      ),
    );
  }
}
