import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 应用级日志管理工具类
/// 提供统一的日志记录功能，支持不同环境配置和日志级别控制
/// 支持真正的 Android Logcat Tag 过滤功能
/// 支持自动获取调用者类名作为 tag
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();

  factory AppLogger() => _instance;

  AppLogger._internal();

  late final Logger _logger;
  bool _isInitialized = false;
  String _appName = 'App';

  /// 初始化日志配置
  /// 必须在 main() 中调用，建议在 runApp() 之前
  ///
  /// 示例:
  /// ```dart
  /// void main() async {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   await AppLogger().initialize();
  ///   runApp(MyApp());
  /// }
  /// ```
  Future<void> initialize({
    DateTimeFormatter dateTimeFormat = DateTimeFormat.none,
    bool printError = true,
    int methodCount = 2,
    int errorMethodCount = 8,
    int lineLength = 120,
    bool colors = true,
    Level level = Level.trace,
  }) async {
    if (_isInitialized) {
      if (kDebugMode) {
        _logToLogcat('AppLogger', '警告: AppLogger已经被初始化', Level.warning);
      }
      return;
    }

    // 获取应用名称
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appName = packageInfo.appName;
      if (_appName.isEmpty) {
        _appName = packageInfo.packageName.split('.').last;
      }
    } catch (e) {
      _appName = 'App';
    }

    Logger.level = level;

    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: methodCount,
        errorMethodCount: errorMethodCount,
        lineLength: lineLength,
        colors: colors,
        dateTimeFormat: dateTimeFormat,
      ),
      filter: _isProduction() ? ProductionFilter() : DevelopmentFilter(),
      output: _LogcatOutput(),
    );

    _isInitialized = true;
  }

  bool _isProduction() {
    return false;
  }

  /// 自动获取调用者的类名
  /// 通过解析调用栈来获取调用日志方法的类名
  String _getCallerClassName() {
    try {
      final stackTrace = StackTrace.current.toString();
      final lines = stackTrace.split('\n');

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.contains('AppLogger.') &&
            !line.contains('_getCallerClassName')) {
          if (i + 1 < lines.length) {
            final callerLine = lines[i + 1];
            final match =
                RegExp(r'package:[^/]+/(.+)\.dart').firstMatch(callerLine);
            if (match != null) {
              final filePath = match.group(1) ?? '';
              final parts = filePath.split('/');
              final fileName = parts.isNotEmpty ? parts.last : filePath;
              if (fileName.isNotEmpty && fileName != 'app_logger') {
                return _formatClassName(fileName);
              }
            }
          }
        }
      }
    } catch (e) {
      // 解析失败
    }

    return _appName;
  }

  /// 格式化类名
  /// 将 snake_case 或 camelCase 转换为 PascalCase
  String _formatClassName(String fileName) {
    if (fileName.isEmpty) return _appName;

    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < fileName.length; i++) {
      final char = fileName[i];
      if (char == '_' || char == '-') {
        capitalizeNext = true;
      } else {
        buffer.write(capitalizeNext ? char.toUpperCase() : char);
        capitalizeNext = false;
      }
    }

    return buffer.toString();
  }

  void _logToLogcat(String tag, dynamic message, Level level,
      {dynamic error, StackTrace? stackTrace}) {
    if (_isProduction()) return;

    final messageStr = message?.toString() ?? '';

    developer.log(
      messageStr,
      time: DateTime.now(),
      name: tag,
      level: _levelToInt(level),
      error: error,
      stackTrace: stackTrace,
    );
  }

  int _levelToInt(Level level) {
    switch (level) {
      case Level.trace:
      case Level.debug:
        return 500;
      case Level.info:
        return 800;
      case Level.warning:
        return 900;
      case Level.error:
        return 1000;
      case Level.fatal:
        return 2000;
      default:
        return 800;
    }
  }

  void t(dynamic message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    final actualTag = tag ?? _getCallerClassName();
    _logToLogcat(actualTag, message, Level.trace,
        error: error, stackTrace: stackTrace);
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  void d(dynamic message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    final actualTag = tag ?? _getCallerClassName();
    _logToLogcat(actualTag, message, Level.debug,
        error: error, stackTrace: stackTrace);
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  void i(dynamic message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    final actualTag = tag ?? _getCallerClassName();
    _logToLogcat(actualTag, message, Level.info,
        error: error, stackTrace: stackTrace);
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  void w(dynamic message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    final actualTag = tag ?? _getCallerClassName();
    _logToLogcat(actualTag, message, Level.warning,
        error: error, stackTrace: stackTrace);
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void e(dynamic message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    final actualTag = tag ?? _getCallerClassName();
    _logToLogcat(actualTag, message, Level.error,
        error: error, stackTrace: stackTrace);
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void f(dynamic message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    final actualTag = tag ?? _getCallerClassName();
    _logToLogcat(actualTag, message, Level.fatal,
        error: error, stackTrace: stackTrace);
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

class _LogcatOutput extends LogOutput {
  @override
  void output(OutputEvent event) {}
}
