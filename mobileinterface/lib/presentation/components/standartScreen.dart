import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';

class StandardScreen extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final String? title;

  const StandardScreen({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                width: double.infinity,
                height: 180,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondaryLight,
                      AppColors.infoLight,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      'assets/icons/logo-inf.svg',
                      height: 80,
                    ),
                    if (title != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        title!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: AppColors.backgroundLight,
                ),
              ),
            ],
          ),

          Positioned(
            top: 140, 
            left: 0,
            right: 0,
            child: child,
          ),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
