import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/task_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/skill_controller.dart';
import '../../utils/snackbar_utils.dart';
import '../theme/app_theme.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> with SingleTickerProviderStateMixin {
  final taskController = Get.find<TaskController>();
  final themeController = Get.find<ThemeController>();
  final skillController = Get.put(SkillController());
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showWheelDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const JackpotWheelDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Coin bar
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.black38 : Colors.white60,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ]
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 30),
                  const SizedBox(width: 8),
                  Obx(() => Text(
                    taskController.totalCoins.value.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                      fontFamily: 'Inter',
                    ),
                  )),
                ],
              ),
              Obx(() => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                ),
                child: Text(
                  "x${skillController.doubleGoldCharges.value} ${'midas_touch'.tr}",
                  style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              )),
            ],
          ),
        ),
        
        TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'nav_skills'.tr),
            Tab(text: 'skin_store'.tr),
          ],
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
          dividerColor: Colors.transparent,
        ),
        
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSkillsTab(),
              _buildSkinsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSkillCard(
          title: 'midas_touch'.tr,
          desc: 'midas_touch_desc'.tr,
          cost: SkillController.costMidasTouch,
          icon: Icons.auto_awesome,
          color: Colors.amber,
          onTap: () {
            if (skillController.buyMidasTouch()) {
              SnackbarUtils.showSuccess(title: 'purchase_success'.tr, message: 'buff_activated'.tr);
            } else {
              SnackbarUtils.showError(title: 'error'.tr, message: 'insufficient_coins'.tr);
            }
          },
        ),
        _buildSkillCard(
          title: 'shield_discipline'.tr,
          desc: 'shield_discipline_desc'.tr,
          cost: SkillController.costShieldDiscipline,
          icon: Icons.shield,
          color: Colors.blue,
          onTap: () {
            if (skillController.buyShieldDiscipline()) {
              SnackbarUtils.showSuccess(title: 'purchase_success'.tr, message: 'buff_activated'.tr);
            } else {
              SnackbarUtils.showError(title: 'error'.tr, message: 'insufficient_coins'.tr);
            }
          },
        ),
        _buildSkillCard(
          title: 'time_sandglass'.tr,
          desc: 'time_sandglass_desc'.tr,
          cost: SkillController.costTimeSandglass,
          icon: Icons.hourglass_full,
          color: Colors.teal,
          onTap: () {
            if (skillController.buyTimeSandglass()) {
              SnackbarUtils.showSuccess(title: 'purchase_success'.tr, message: 'sandglass_used'.tr);
            } else {
              SnackbarUtils.showError(title: 'error'.tr, message: 'insufficient_coins'.tr);
            }
          },
        ),
        _buildSkillCard(
          title: 'jackpot_wheel'.tr,
          desc: 'jackpot_wheel_desc'.tr,
          cost: SkillController.costJackpotWheel,
          icon: Icons.casino,
          color: Colors.red,
          onTap: () {
            if (taskController.totalCoins.value >= SkillController.costJackpotWheel) {
              _showWheelDialog(context);
            } else {
              SnackbarUtils.showError(title: 'error'.tr, message: 'insufficient_coins'.tr);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSkillCard({
    required String title,
    required String desc,
    required int cost,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.white54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              elevation: 2,
            ),
            onPressed: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, size: 16, color: Colors.white),
                const SizedBox(height: 2),
                Text(
                  cost.toString(),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSkinsTab() {
    return Obx(() {
      final unlockedList = skillController.unlockedSkins;
      final currentThemeIndex = themeController.currentThemeIndex.value;
      
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          final isUnlocked = unlockedList.contains(index);
          final isEquipped = currentThemeIndex == index;
          final themeData = AppTheme.themes[index];
          final themeColors = AppTheme.getThemeBackgroundColors(index);
          
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isEquipped 
                    ? Colors.amber.shade600 
                    : Colors.white.withOpacity(0.2), 
                width: isEquipped ? 2.5 : 1
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(19),
              child: Stack(
                children: [
                  // Gradient preview background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [themeColors[0], themeColors[1]],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    ),
                  ),
                  // Glass panel cover
                  Container(
                    color: Colors.black.withOpacity(0.15),
                  ),
                  // Bottom bar with action details
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.black.withOpacity(0.55),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'theme_$index'.tr,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          if (isEquipped)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'skin_equipped'.tr,
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            )
                          else if (isUnlocked)
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 26),
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () => themeController.changeTheme(index),
                              child: Text('skin_unlocked'.tr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          else
                            ElevatedButton.icon(
                              icon: const Icon(Icons.monetization_on, size: 12, color: Colors.amber),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber.shade700,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 26),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              onPressed: () {
                                _showUnlockDialog(context, index);
                              },
                              label: Text(
                                SkillController.costSkinUnlock.toString(),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (!isUnlocked)
                    Positioned(
                      top: 10, right: 10,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.lock, color: Colors.white70, size: 14),
                      ),
                    )
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _showUnlockDialog(BuildContext context, int index) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('change_theme'.tr),
        content: Text('skin_unlock_cost'.trParams({'cost': SkillController.costSkinUnlock.toString()}) + "?"),
        actions: [
          CupertinoDialogAction(
            child: Text('time_none'.tr), // cancel
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('save'.tr), // confirm
            onPressed: () {
              Navigator.pop(context);
              if (skillController.unlockSkin(index)) {
                SnackbarUtils.showSuccess(title: 'purchase_success'.tr, message: 'purchase_success'.tr);
              } else {
                SnackbarUtils.showError(title: 'error'.tr, message: 'insufficient_coins'.tr);
              }
            },
          ),
        ],
      ),
    );
  }
}

class JackpotWheelDialog extends StatefulWidget {
  const JackpotWheelDialog({super.key});

  @override
  State<JackpotWheelDialog> createState() => _JackpotWheelDialogState();
}

class _JackpotWheelDialogState extends State<JackpotWheelDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final skillController = Get.find<SkillController>();
  
  bool _isSpinning = false;
  int _wonAmount = -1;
  double _wheelRotation = 0.0;
  
  // Possible outcomes and their segment values
  final List<int> _rewards = [0, 10, 50, 100, 200, 300];
  final List<Color> _segmentColors = [
    Colors.grey.shade400,
    Colors.green.shade400,
    Colors.blue.shade400,
    Colors.purple.shade400,
    Colors.orange.shade400,
    Colors.amber.shade700
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning) return;
    
    setState(() {
      _isSpinning = true;
      _wonAmount = -1;
    });

    final won = skillController.spinJackpot();
    if (won == -1) {
      // Insufficient coins (sanity check)
      setState(() {
        _isSpinning = false;
      });
      Navigator.pop(context);
      SnackbarUtils.showError(title: 'error'.tr, message: 'insufficient_coins'.tr);
      return;
    }

    // Determine target angle based on outcome
    int rewardIndex = _rewards.indexOf(won);
    if (rewardIndex == -1) rewardIndex = 0;
    
    // Each segment is 60 degrees (2pi / 6)
    // Align so pointer is pointing at the top (angle = 3pi/2)
    double segmentAngle = (2 * pi) / 6;
    double targetAngle = (5 * 2 * pi) + (segmentAngle * rewardIndex) + (segmentAngle / 2);
    
    final Animation<double> angleCurve = Tween<double>(begin: _wheelRotation % (2 * pi), end: targetAngle).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic)
    );

    _animationController.addListener(() {
      setState(() {
        _wheelRotation = angleCurve.value;
      });
    });

    _animationController.forward(from: 0.0).then((_) {
      setState(() {
        _isSpinning = false;
        _wonAmount = won;
        _wheelRotation = targetAngle; // normalize
      });
      
      if (won > 0) {
        SnackbarUtils.showSuccess(
          title: 'wheel_win'.trParams({'coins': won.toString()}), 
          message: 'purchase_success'.tr
        );
      } else {
        SnackbarUtils.showInfo(
          title: 'wheel_lose'.tr,
          message: 'no_quests'.tr
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: isDark ? const Color(0xFF1E1E2C) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'jackpot_wheel'.tr,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'jackpot_wheel_desc'.tr,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // The wheel canvas/graphics container
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: _wheelRotation,
                  child: CustomPaint(
                    size: const Size(200, 200),
                    painter: WheelPainter(
                      rewards: _rewards,
                      colors: _segmentColors,
                    ),
                  ),
                ),
                // Center pin
                Container(
                  width: 24, height: 24,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1)
                    ]
                  ),
                ),
                // Pointer arrow (top-pointing)
                Positioned(
                  top: 0,
                  child: CustomPaint(
                    size: const Size(18, 20),
                    painter: PointerPainter(),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            if (_wonAmount != -1)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _wonAmount > 0 
                      ? "+$_wonAmount ${'reward_coins'.tr}!" 
                      : 'wheel_lose'.tr,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _wonAmount > 0 ? Colors.amber.shade700 : Colors.grey,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!_isSpinning)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('save'.tr, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)), // Close/Confirm
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: _isSpinning ? null : _spin,
                  child: Text(
                    _isSpinning ? 'spin_button'.tr + '...' : 'spin_button'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Wheel painter
class WheelPainter extends CustomPainter {
  final List<int> rewards;
  final List<Color> colors;

  WheelPainter({required this.rewards, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.fill;
      
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    double angle = 2 * pi / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      paint.color = colors[i];
      canvas.drawArc(rect, i * angle, angle, true, paint);

      // Draw text in the middle of segment
      final textAngle = i * angle + angle / 2;
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(textAngle);
      
      textPainter.text = TextSpan(
        text: "+${rewards[i]}",
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
      );
      textPainter.layout();
      // Draw text horizontally offset to outer edge
      textPainter.paint(
        canvas, 
        Offset(radius * 0.45, -textPainter.height / 2)
      );
      
      canvas.restore();
    }
    
    // Draw outer border ring
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Top pointer paint
class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
      
    canvas.drawPath(path, paint);
    
    // Inner shadow outline
    final strokePaint = Paint()
      ..color = Colors.red.shade900
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
