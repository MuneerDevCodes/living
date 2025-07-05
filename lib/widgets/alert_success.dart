import 'package:flutter/material.dart';
import 'package:living/style/responsive_helper.dart';
import 'package:living/style/theme.dart';

class AlertSuccess extends StatelessWidget {
  final String message;
  final VoidCallback? onClose;
  const AlertSuccess(this.message, {super.key, this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: ResponsiveHelper.getAdaptiveSpacing(context) * 0.6),
      padding: ResponsiveHelper.getAdaptivePadding(context),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(
          ResponsiveHelper.getAdaptiveBorderRadius(context),
        ),
        border: Border.all(color: AppColors.success),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
          SizedBox(width: ResponsiveHelper.getAdaptiveSpacing(context) * 0.4),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
                fontSize: ResponsiveHelper.getAdaptiveFontSize(context, baseSize: 14),
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
                            icon: Icon(
                Icons.close,
                color: AppColors.success,
                size: ResponsiveHelper.getAdaptiveIconSize(context),
          ),
              splashRadius: ResponsiveHelper.getAdaptiveIconSize(context),
              onPressed: onClose,
              tooltip: 'Close',
            ),
        ],
      ),
    );
  }
}
