import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'capsule/capsule_manager.dart';
import 'capsule/capsule_widget.dart';
import 'services/overlay_channel.dart';
import 'theme/nowbar_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  const entryPoint = String.fromEnvironment('ENTRY_POINT', defaultValue: 'main');
  
  if (entryPoint == 'overlay') {
    runOverlayApp();
  } else {
    runMainApp();
  }
}

void runMainApp() {
  runApp(
    const ProviderScope(
      child: NowBarApp(),
    ),
  );
}

void runOverlayApp() {
  runApp(
    const ProviderScope(
      child: OverlayApp(),
    ),
  );
}

class NowBarApp extends StatelessWidget {
  const NowBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Now Bar',
      debugShowCheckedModeBanner: false,
      theme: NowBarTheme.darkTheme,
      home: const NowBarHomeScreen(),
    );
  }
}

class NowBarHomeScreen extends ConsumerStatefulWidget {
  const NowBarHomeScreen({super.key});

  @override
  ConsumerState<NowBarHomeScreen> createState() => _NowBarHomeScreenState();
}

class _NowBarHomeScreenState extends ConsumerState<NowBarHomeScreen> {
  final OverlayChannel _overlayChannel = OverlayChannel();
  bool _hasOverlayPermission = false;
  bool _isServiceRunning = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _overlayChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _checkPermissions() async {
    final hasPermission = await _overlayChannel.checkOverlayPermission();
    final isRunning = await _overlayChannel.isNowBarRunning();
    if (mounted) {
      setState(() {
        _hasOverlayPermission = hasPermission;
        _isServiceRunning = isRunning;
      });
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onOverlayPermissionResult':
        if (mounted) {
          setState(() {
            _hasOverlayPermission = call.arguments as bool;
          });
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NowBarTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Now Bar',
                style: NowBarTheme.headlineStyle.copyWith(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Smart lock screen overlay',
                style: NowBarTheme.subtitleStyle.copyWith(
                  color: NowBarTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 60),
              _buildStatusCard(),
              const SizedBox(height: 24),
              _buildControlButtons(),
              const SizedBox(height: 40),
              _buildCapsulePreview(),
              const Spacer(),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: NowBarTheme.cardGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: NowBarTheme.glassBorder,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildStatusRow(
            'Overlay Permission',
            _hasOverlayPermission,
            _hasOverlayPermission ? 'Granted' : 'Required',
          ),
          const SizedBox(height: 12),
          _buildStatusRow(
            'Service Status',
            _isServiceRunning,
            _isServiceRunning ? 'Running' : 'Stopped',
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool isActive, String status) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? NowBarTheme.successColor : NowBarTheme.warningColor,
            boxShadow: [
              BoxShadow(
                color: (isActive ? NowBarTheme.successColor : NowBarTheme.warningColor)
                    .withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: NowBarTheme.bodyStyle,
          ),
        ),
        Text(
          status,
          style: NowBarTheme.bodyStyle.copyWith(
            color: isActive ? NowBarTheme.successColor : NowBarTheme.warningColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        if (!_hasOverlayPermission)
          _buildActionButton(
            'Grant Overlay Permission',
            NowBarTheme.warningColor,
            () async {
              await _overlayChannel.requestOverlayPermission();
            },
          ),
        const SizedBox(height: 12),
        _buildActionButton(
          _isServiceRunning ? 'Stop Now Bar' : 'Start Now Bar',
          _isServiceRunning ? NowBarTheme.errorColor : NowBarTheme.primaryBlue,
          () async {
            if (_isServiceRunning) {
              await _overlayChannel.stopNowBarService();
            } else {
              await _overlayChannel.startNowBarService();
            }
            await _checkPermissions();
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.6),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: NowBarTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildCapsulePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Capsules',
          style: NowBarTheme.subtitleStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildCapsuleChip('Battery', NowBarTheme.primaryBlue),
            _buildCapsuleChip('Weather', NowBarTheme.primaryGreen),
            _buildCapsuleChip('Music', NowBarTheme.primaryOrange),
            _buildCapsuleChip('Matches', NowBarTheme.primaryPink),
          ],
        ),
      ],
    );
  }

  Widget _buildCapsuleChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: NowBarTheme.bodyStyle.copyWith(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'One UI 8.5 Inspired',
        style: NowBarTheme.captionStyle.copyWith(
          color: NowBarTheme.textSecondary.withOpacity(0.5),
        ),
      ),
    );
  }
}

// Overlay App shown on lock screen
class OverlayApp extends StatelessWidget {
  const OverlayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: NowBarTheme.darkTheme,
      home: const OverlayScreen(),
    );
  }
}

class OverlayScreen extends ConsumerStatefulWidget {
  const OverlayScreen({super.key});

  @override
  ConsumerState<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends ConsumerState<OverlayScreen>
    with TickerProviderStateMixin {
  final OverlayChannel _overlayChannel = OverlayChannel();
  late AnimationController _bounceController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _overlayChannel.setMethodCallHandler(_handleMethodCall);
    _overlayChannel.requestOverlayContext();
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onOverlayContext':
        if (call.arguments != null) {
          ref.read(capsuleContextProvider.notifier).state =
              call.arguments as Map<dynamic, dynamic>;
        }
        break;
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onSwipeUp() {
    final capsules = ref.read(sortedCapsulesProvider);
    if (_currentIndex < capsules.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _bounceController.forward(from: 0).then((_) {
        _bounceController.reset();
      });
    } else {
      _bounceController.animateTo(0.3).then((_) {
        _bounceController.animateBack(0, 
          duration: const Duration(milliseconds: 200));
      });
    }
  }

  void _onSwipeDown() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _bounceController.forward(from: 0).then((_) {
        _bounceController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final capsules = ref.watch(sortedCapsulesProvider);
    
    if (capsules.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: SizedBox.shrink(),
      );
    }

    final currentCapsule = capsules[_currentIndex.clamp(0, capsules.length - 1)];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null) {
            if (details.primaryVelocity! < -150) {
              _onSwipeUp();
            } else if (details.primaryVelocity! > 150) {
              _onSwipeDown();
            }
          }
        },
        child: Stack(
          children: [
            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.6),
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Capsules at bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 40,
              child: AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      0,
                      -_bounceController.value * 100,
                    ),
                    child: child,
                  );
                },
                child: NowBarCapsuleView(
                  capsule: currentCapsule,
                  onSwipeUp: _onSwipeUp,
                  onSwipeDown: _onSwipeDown,
                  currentIndex: _currentIndex,
                  totalCapsules: capsules.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NowBarCapsuleView extends StatelessWidget {
  final CapsuleData capsule;
  final VoidCallback onSwipeUp;
  final VoidCallback onSwipeDown;
  final int currentIndex;
  final int totalCapsules;

  const NowBarCapsuleView({
    super.key,
    required this.capsule,
    required this.onSwipeUp,
    required this.onSwipeDown,
    required this.currentIndex,
    required this.totalCapsules,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            totalCapsules,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: index == currentIndex ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: index == currentIndex
                    ? capsule.accentColor
                    : Colors.white.withOpacity(0.3),
                boxShadow: index == currentIndex
                    ? [
                        BoxShadow(
                          color: capsule.accentColor.withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Capsule widget
        CapsuleRenderer(
          capsule: capsule,
          onSwipeUp: onSwipeUp,
          onSwipeDown: onSwipeDown,
        ),
        const SizedBox(height: 8),
        // Swipe hint
        Text(
          'Swipe up for next',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}