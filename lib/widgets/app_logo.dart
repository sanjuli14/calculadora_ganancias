import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double fontSize;
  final Color? cuentasColor;
  final Color? clarasColor;
  final bool withIcon;

  const AppLogo({
    super.key,
    this.fontSize = 22,
    this.cuentasColor,
    this.clarasColor,
    this.withIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (withIcon) ...[
          Container(
            width: fontSize * 1.3,
            height: fontSize * 1.3,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, AppColors.turquoise],
              ),
              borderRadius: BorderRadius.circular(fontSize * 0.4),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Cuentas',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: cuentasColor ?? AppColors.navy,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: ' Claras',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: clarasColor ?? AppColors.emerald,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
