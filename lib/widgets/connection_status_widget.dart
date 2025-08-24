import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../utils/app_colors.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final bool showDetails;
  final bool compact;

  const ConnectionStatusWidget({
    super.key,
    this.showDetails = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        if (compact) {
          return _buildCompactStatus(appState);
        }
        
        return _buildFullStatus(context, appState);
      },
    );
  }

  Widget _buildCompactStatus(AppStateProvider appState) {
    final color = _getStatusColor(appState.connectionStatus);
    final icon = _getStatusIcon(appState.connectionStatus);
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: color,
          size: 16,
        ),
        const SizedBox(width: 4),
        Text(
          _getStatusText(appState.connectionStatus),
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFullStatus(BuildContext context, AppStateProvider appState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getStatusColor(appState.connectionStatus).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(appState.connectionStatus).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(appState.connectionStatus),
            color: _getStatusColor(appState.connectionStatus),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(appState.connectionStatus),
                  style: TextStyle(
                    color: _getStatusColor(appState.connectionStatus),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (showDetails) ...[
                  const SizedBox(height: 4),
                  Text(
                    _getStatusDescription(appState),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  if (appState.lastHealthCheck != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Last check: ${_formatLastCheck(appState.lastHealthCheck!)}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          if (appState.connectionStatus == ConnectionStatus.disconnected)
            IconButton(
              onPressed: () => appState.retryConnection(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Retry connection',
              iconSize: 18,
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return AppColors.connected;
      case ConnectionStatus.disconnected:
        return AppColors.disconnected;
      case ConnectionStatus.checking:
        return AppColors.connecting;
    }
  }

  IconData _getStatusIcon(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return Icons.cloud_done;
      case ConnectionStatus.disconnected:
        return Icons.cloud_off;
      case ConnectionStatus.checking:
        return Icons.cloud_sync;
    }
  }

  String _getStatusText(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.checking:
        return 'Checking...';
    }
  }

  String _getStatusDescription(AppStateProvider appState) {
    switch (appState.connectionStatus) {
      case ConnectionStatus.connected:
        return appState.isServerHealthy 
            ? 'Server is healthy and ready'
            : 'Server connected but not healthy';
      case ConnectionStatus.disconnected:
        return appState.errorMessage ?? 'Unable to connect to server';
      case ConnectionStatus.checking:
        return 'Checking server connection...';
    }
  }

  String _formatLastCheck(DateTime lastCheck) {
    final now = DateTime.now();
    final difference = now.difference(lastCheck);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

// Mini connection indicator for app bars
class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: _getStatusColor(appState.connectionStatus),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return AppColors.connected;
      case ConnectionStatus.disconnected:
        return AppColors.disconnected;
      case ConnectionStatus.checking:
        return AppColors.connecting;
    }
  }
}

// Animated connection status indicator
class AnimatedConnectionIndicator extends StatefulWidget {
  final double size;

  const AnimatedConnectionIndicator({
    super.key,
    this.size = 12,
  });

  @override
  State<AnimatedConnectionIndicator> createState() => _AnimatedConnectionIndicatorState();
}

class _AnimatedConnectionIndicatorState extends State<AnimatedConnectionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateProvider>(
      builder: (context, appState, child) {
        final color = _getStatusColor(appState.connectionStatus);
        final shouldAnimate = appState.connectionStatus == ConnectionStatus.checking;

        if (shouldAnimate) {
          return AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: color.withOpacity(_animation.value),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        } else {
          return Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          );
        }
      },
    );
  }

  Color _getStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return AppColors.connected;
      case ConnectionStatus.disconnected:
        return AppColors.disconnected;
      case ConnectionStatus.checking:
        return AppColors.connecting;
    }
  }
}
