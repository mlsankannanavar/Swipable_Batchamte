import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/logging_provider.dart';
import '../screens/log_viewer_screen.dart';
import '../utils/app_colors.dart';

class LogButtonWidget extends StatelessWidget {
  final bool isSmall;
  final VoidCallback? onPressed;

  const LogButtonWidget({
    super.key,
    this.isSmall = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: isSmall ? 50 : 60,
      right: 16,
      child: Consumer<LoggingProvider>(
        builder: (context, loggingProvider, child) {
          return FloatingActionButton(
            onPressed: onPressed ?? () => _showLogScreen(context),
            backgroundColor: AppColors.logButtonBackground,
            foregroundColor: AppColors.logButtonIcon,
            mini: isSmall,
            heroTag: "log_button_${isSmall ? 'small' : 'large'}",
            tooltip: 'View Application Logs',
            child: Stack(
              children: [
                Icon(
                  Icons.terminal,
                  size: isSmall ? 18 : 24,
                  color: AppColors.logButtonIcon,
                ),
                if (loggingProvider.hasNewErrors)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: isSmall ? 6 : 8,
                      height: isSmall ? 6 : 8,
                      decoration: const BoxDecoration(
                        color: AppColors.logButtonBadge,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (loggingProvider.hasLogs && !loggingProvider.hasNewErrors)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: isSmall ? 4 : 6,
                      height: isSmall ? 4 : 6,
                      decoration: const BoxDecoration(
                        color: AppColors.logInfo,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogScreen(BuildContext context) {
    // Track user action
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Log viewer opened');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LogViewerScreen(),
        fullscreenDialog: true,
      ),
    );
  }
}

// Alternative implementation for bottom sheet style
class LogButtonBottomSheet extends StatelessWidget {
  final bool isSmall;

  const LogButtonBottomSheet({
    super.key,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: isSmall ? 50 : 60,
      right: 16,
      child: Consumer<LoggingProvider>(
        builder: (context, loggingProvider, child) {
          return FloatingActionButton(
            onPressed: () => _showLogBottomSheet(context),
            backgroundColor: AppColors.logButtonBackground,
            foregroundColor: AppColors.logButtonIcon,
            mini: isSmall,
            heroTag: "log_button_bottom_sheet_${isSmall ? 'small' : 'large'}",
            tooltip: 'View Application Logs',
            child: Stack(
              children: [
                Icon(
                  Icons.bug_report,
                  size: isSmall ? 18 : 24,
                  color: AppColors.logButtonIcon,
                ),
                if (loggingProvider.hasNewErrors)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: isSmall ? 6 : 8,
                      height: isSmall ? 6 : 8,
                      decoration: const BoxDecoration(
                        color: AppColors.logButtonBadge,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                if (loggingProvider.logCount > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.logInfo,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        loggingProvider.logCount > 99 
                            ? '99+' 
                            : loggingProvider.logCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmall ? 8 : 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogBottomSheet(BuildContext context) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Log bottom sheet opened');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: LogViewerScreen(
            scrollController: scrollController,
            isBottomSheet: true,
          ),
        ),
      ),
    );
  }
}

// Compact log status indicator
class LogStatusIndicator extends StatelessWidget {
  final double size;
  final bool showCount;

  const LogStatusIndicator({
    super.key,
    this.size = 24,
    this.showCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LoggingProvider>(
      builder: (context, loggingProvider, child) {
        Color iconColor = AppColors.logInfo;
        IconData iconData = Icons.circle;
        
        if (loggingProvider.hasNewErrors) {
          iconColor = AppColors.logError;
          iconData = Icons.error;
        } else if (loggingProvider.hasErrors) {
          iconColor = AppColors.logWarning;
          iconData = Icons.warning;
        } else if (loggingProvider.hasLogs) {
          iconColor = AppColors.logSuccess;
          iconData = Icons.check_circle;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              color: iconColor,
              size: size,
            ),
            if (showCount && loggingProvider.hasLogs) ...[
              const SizedBox(width: 4),
              Text(
                loggingProvider.logCount > 999 
                    ? '999+' 
                    : loggingProvider.logCount.toString(),
                style: TextStyle(
                  fontSize: size * 0.6,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

// Mini log button for app bars
class MiniLogButton extends StatelessWidget {
  const MiniLogButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LoggingProvider>(
      builder: (context, loggingProvider, child) {
        return IconButton(
          onPressed: () => _navigateToLogs(context),
          tooltip: 'View Logs (${loggingProvider.logCount})',
          icon: Stack(
            children: [
              const Icon(Icons.terminal),
              if (loggingProvider.hasNewErrors)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.logError,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToLogs(BuildContext context) {
    final loggingProvider = Provider.of<LoggingProvider>(context, listen: false);
    loggingProvider.logApp('Mini log button pressed');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LogViewerScreen(),
      ),
    );
  }
}
