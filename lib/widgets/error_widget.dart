import 'package:flutter/material.dart';

class CustomErrorWidget extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryText;
  final bool compact;
  final Color? color;

  const CustomErrorWidget({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryText,
    this.compact = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactError(context);
    }
    return _buildFullError(context);
  }

  Widget _buildCompactError(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.error_outline,
            color: color ?? Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color ?? Colors.red,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    message!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              iconSize: 20,
              tooltip: retryText ?? 'Retry',
            ),
        ],
      ),
    );
  }

  Widget _buildFullError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: color ?? Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: color ?? Colors.red,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText ?? 'Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color ?? Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Network error widget
class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final bool compact;

  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: 'No Internet Connection',
      message: 'Please check your internet connection and try again.',
      icon: Icons.wifi_off,
      onRetry: onRetry,
      retryText: 'Retry',
      compact: compact,
      color: Colors.orange,
    );
  }
}

// Server error widget
class ServerErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final bool compact;

  const ServerErrorWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: 'Server Error',
      message: errorMessage ?? 'Unable to connect to the server. Please try again later.',
      icon: Icons.cloud_off,
      onRetry: onRetry,
      retryText: 'Retry',
      compact: compact,
      color: Colors.red,
    );
  }
}

// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionText ?? 'Get Started'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Permission denied widget
class PermissionDeniedWidget extends StatelessWidget {
  final String permission;
  final VoidCallback? onRequestPermission;
  final VoidCallback? onOpenSettings;
  final bool compact;

  const PermissionDeniedWidget({
    super.key,
    required this.permission,
    this.onRequestPermission,
    this.onOpenSettings,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: '$permission Permission Required',
      message: 'This app needs $permission permission to function properly. Please grant the permission to continue.',
      icon: Icons.lock_outline,
      onRetry: onRequestPermission ?? onOpenSettings,
      retryText: onRequestPermission != null ? 'Grant Permission' : 'Open Settings',
      compact: compact,
      color: Colors.orange,
    );
  }
}

// API error widget
class ApiErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final int? statusCode;
  final VoidCallback? onRetry;
  final bool compact;

  const ApiErrorWidget({
    super.key,
    this.errorMessage,
    this.statusCode,
    this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    String title = 'API Error';
    String message = errorMessage ?? 'An error occurred while communicating with the server.';
    
    if (statusCode != null) {
      switch (statusCode!) {
        case 400:
          title = 'Bad Request';
          message = 'The request was invalid. Please check your input and try again.';
          break;
        case 401:
          title = 'Unauthorized';
          message = 'You are not authorized to access this resource.';
          break;
        case 403:
          title = 'Forbidden';
          message = 'Access to this resource is forbidden.';
          break;
        case 404:
          title = 'Not Found';
          message = 'The requested resource was not found.';
          break;
        case 500:
          title = 'Server Error';
          message = 'An internal server error occurred. Please try again later.';
          break;
        case 502:
          title = 'Bad Gateway';
          message = 'The server received an invalid response. Please try again later.';
          break;
        case 503:
          title = 'Service Unavailable';
          message = 'The service is temporarily unavailable. Please try again later.';
          break;
        case 504:
          title = 'Gateway Timeout';
          message = 'The server took too long to respond. Please try again.';
          break;
      }
    }

    return CustomErrorWidget(
      title: title,
      message: message,
      icon: Icons.api,
      onRetry: onRetry,
      retryText: 'Retry',
      compact: compact,
      color: Colors.red,
    );
  }
}

// QR Scanner error widget
class QrScannerErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;
  final VoidCallback? onRequestPermission;

  const QrScannerErrorWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
    this.onRequestPermission,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: 'QR Scanner Error',
      message: errorMessage ?? 'Unable to access the camera for QR scanning.',
      icon: Icons.qr_code_scanner,
      onRetry: onRequestPermission ?? onRetry,
      retryText: onRequestPermission != null ? 'Grant Permission' : 'Try Again',
      color: Colors.orange,
    );
  }
}

// OCR error widget
class OcrErrorWidget extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const OcrErrorWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return CustomErrorWidget(
      title: 'OCR Processing Error',
      message: errorMessage ?? 'Unable to extract text from the image.',
      icon: Icons.text_fields,
      onRetry: onRetry,
      retryText: 'Try Again',
      color: Colors.purple,
    );
  }
}
