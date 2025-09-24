import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/app_colors.dart';

class StandardScreen extends StatelessWidget {
  final Widget child;
  final Widget? bottomNavigationBar;
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;

  const StandardScreen({
    super.key,
    required this.child,
    this.bottomNavigationBar,
    this.title,
    this.showBackButton = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 35, bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (showBackButton)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          )
                        else
                          const SizedBox(width: 48),
                        
                        if (actions != null)
                          Row(
                            children: actions!.map((action) => 
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: action,
                              ),
                            ).toList(),
                          )
                        else
                          const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 6),
                  
                  SvgPicture.asset(
                    'assets/icons/logo-inf.svg',
                    height: 75,
                  ),
                  
                  if (title != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.grey[50],
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}