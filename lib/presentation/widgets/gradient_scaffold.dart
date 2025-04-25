import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class GradientScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final LinearGradient? customGradient;

  const GradientScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.customGradient,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Scaffold(
      appBar: appBar,
      body: Container(
        decoration: BoxDecoration(
          gradient: customGradient ?? themeProvider.scaffoldGradient,
        ),
        child: body,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

// Custom painter for smoother gradients
class GradientPainter extends CustomPainter {
  final LinearGradient gradient;

  GradientPainter({required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    // Create a rect for the entire canvas
    final Rect rect = Offset.zero & size;
    
    // Create a paint with the gradient
    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    
    // Draw a rectangle with the gradient
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(GradientPainter oldDelegate) => 
      oldDelegate.gradient != gradient;
} 