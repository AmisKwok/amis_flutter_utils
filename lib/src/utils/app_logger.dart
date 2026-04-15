import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 应用级日志管理工具类
/// 提供统一的日志记录功能，支持不同环境配置和日志级别控制
/// 支持真正的 Android Logcat Tag 过滤功能
/// 支持自动获取调用者类名作为 tag
class AppLogger {
  /// 单例实例
  static final AppLogger _instance = AppLogger._internal();

  /// 获取单例实例
  factory AppLogger() => _instance;

  /// 私有构造函数，防止外部实例化
  AppLogger._internal();

  /// 日志核心对象
  late final Logger _logger;

  /// 初始化标记，防止重复初始化
  bool _isInitialized = false;

  /// 应用名称，解析失败时作为后备 tag
  String _appName = 'App';

  /// 初始化日志配置
  /// 必须在 main() 中调用，建议在 runApp() 之前
  ///
  /// [参数说明]:
  /// - [dateTimeFormat]: 时间显示格式配置
  ///   - `DateTimeFormat.none`: 不显示时间戳
  ///   - `DateTimeFormat.microsecond`: 显示微秒级时间(HH:mm:ss.SSSSSS)
  ///   - `DateTimeFormat.onlyTimeAndSinceStart`: 显示时间及应用启动后时长
  /// - [printError]: 是否打印错误堆栈信息(默认true)
  /// - [methodCount]: 开发环境下打印的调用栈方法数(默认2)
  /// - [errorMethodCount]: 错误日志打印的调用栈方法数(默认8)
  /// - [lineLength]: 日志行最大字符数(默认120，用于自动换行)
  /// - [colors]: 是否使用ANSI颜色输出(默认true)
  /// - [level]: 日志记录级别(默认Level.trace，记录所有日志)
  ///
  /// 示例:
  /// ```dart
  /// void main() {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   AppLogger().initialize();  // 同步初始化，不阻塞启动
  ///   runApp(MyApp());
  /// }
  /// ```
  void initialize({
    DateTimeFormatter dateTimeFormat = DateTimeFormat.none,
    bool printError = true,
    int methodCount = 2,
    int errorMethodCount = 8,
    int lineLength = 120,
    bool colors = true,
    Level level = Level.trace,
  }) {
    // 防止重复初始化
    if (_isInitialized) {
      if (kDebugMode) {
        _logToLogcat('AppLogger', '警告: AppLogger已经被初始化', Level.warning);
      }
      return;
    }

    // 设置全局日志级别
    Logger.level = level;

    // 创建日志记录器实例
    _logger = Logger(
      // 配置日志格式化输出
      printer: PrettyPrinter(
        methodCount: methodCount, // 开发环境调用栈深度
        errorMethodCount: errorMethodCount, // 错误调用栈深度
        lineLength: lineLength, // 行宽限制(自动换行)
        colors: colors, // 是否使用颜色
        dateTimeFormat: dateTimeFormat, // 时间显示格式
      ),
      // 配置日志过滤器
      filter: _isProduction() ? ProductionFilter() : DevelopmentFilter(),
      output: _LogcatOutput(),
    );

    _isInitialized = true;

    // 异步获取应用名称，不阻塞启动
    _loadAppName();
  }

  /// 异步加载应用名称
  /// 在后台执行，不影响启动速度
  Future<void> _loadAppName() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appName = packageInfo.appName;
      // 如果应用名称为空，则使用包名最后一段
      if (_appName.isEmpty) {
        _appName = packageInfo.packageName.split('.').last;
      }
    } catch (e) {
      // 获取失败时使用默认值
      _appName = 'App';
    }
  }

  /// 判断是否为生产环境
  ///
  /// 默认返回false(开发环境)，实际项目中可通过环境变量判断
  /// 例如: const bool.fromEnvironment('dart.vm.product')
  bool _isProduction() {
    return false;
  }

  /// 自动获取调用者的类名
  /// 通过解析调用栈来获取调用日志方法的类名
  ///
  /// 返回格式化后的类名(PascalCase)，解析失败时返回应用名称
  String _getCallerClassName() {
    try {
      final stackTrace = StackTrace.current.toString();
      final lines = stackTrace.split('\n');

      // 遍历调用栈，找到调用日志方法的位置
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        // 跳过 AppLogger 内部方法调用
        if (line.contains('AppLogger.') &&
            !line.contains('_getCallerClassName')) {
          if (i + 1 < lines.length) {
            final callerLine = lines[i + 1];
            // 使用正则表达式提取文件路径
            final match =
                RegExp(r'package:[^/]+/(.+)\.dart').firstMatch(callerLine);
            if (match != null) {
              final filePath = match.group(1) ?? '';
              final parts = filePath.split('/');
              // 获取文件名（不含扩展名）
              final fileName = parts.isNotEmpty ? parts.last : filePath;
              if (fileName.isNotEmpty && fileName != 'app_logger') {
                return _formatClassName(fileName);
              }
            }
          }
        }
      }
    } catch (e) {
      // 解析失败时返回应用名称
    }

    return _appName;
  }

  /// 格式化类名
  /// 将 snake_case 或 camelCase 转换为 PascalCase
  ///
  /// 例如:
  /// - login_page -> LoginPage
  /// - user_service -> UserService
  /// - network-manager -> NetworkManager
  String _formatClassName(String fileName) {
    if (fileName.isEmpty) return _appName;

    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < fileName.length; i++) {
      final char = fileName[i];
      if (char == '_' || char == '-') {
        // 遇到分隔符，下一个字符大写
        capitalizeNext = true;
      } else {
        buffer.write(capitalizeNext ? char.toUpperCase() : char);
        capitalizeNext = false;
      }
    }

    return buffer.toString();
  }

  /// 输出日志到 Logcat
  /// 使用 dart:developer 的 log 函数，支持真正的 Tag 过滤
  ///
  /// [tag] 日志标签
  /// [message] 日志消息
  /// [level] 日志级别
  /// [error] 错误对象
  /// [stackTrace] 堆栈信息
  void _logToLogcat(String tag, dynamic message, Level level,
      {dynamic error, StackTrace? stackTrace}) {
    // 生产环境不输出日志
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

  /// 将 Logger 级别转换为系统日志级别
  ///
  /// 级别对应关系:
  /// - trace/debug -> 500 (VERBOSE/DEBUG)
  /// - info -> 800 (INFO)
  /// - warning -> 900 (WARNING)
  /// - error -> 1000 (ERROR)
  /// - fatal -> 2000 (ASSERT)
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

  /// 记录trace级别日志(最详细，开发调试用)
  ///
  /// [message] 日志消息
  /// [tag] 日志标签，不填则自动获取调用者类名
  /// [error] 错误对象
  /// [stackTrace] 堆栈信息
  void t(dynamic message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    final actualTag = tag ?? _getCallerClassName();
    _logToLogcat(actualTag, message, Level.trace,
        error: error, stackTrace: stackTrace);
    _logger.t(message, error: error, stackTrace: stackTrace);
  }

  /// 记录debug级别日志(调试信息)
  ///
  /// [message] 日志消息
  /// [tag] 日志标签，不填则自动获取调用者类名
  /// [error] 错误对象
  /// [stackTrace] 堆栈信息
  void d(dynamic message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    final actualTag = tag ?? _getCallerClassName();
    _logToLogcat(actualTag, message, Level.debug,
        error: error, stackTrace: stackTrace);
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// 记录info级别日志(普通信息)
  ///
  /// [message] 日志消息
  /// [tag] 日志标签，不填则自动获取调用者类名
  /// [error] 错误对象
  /// [stackTrace] 堆栈信息
  void i(dynamic message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    final actualTag = tag ?? _getCallerClassName();
    _logToLogcat(actualTag, message, Level.info,
        error: error, stackTrace: stackTrace);
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// 记录warning级别日志(警告信息)
  ///
  /// [message] 日志消息
  /// [tag] 日志标签，不填则自动获取调用者类名
  /// [error] 错误对象
  /// [stackTrace] 堆栈信息
  void w(dynamic message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    final actualTag = tag ?? _getCallerClassName();
    _logToLogcat(actualTag, message, Level.warning,
        error: error, stackTrace: stackTrace);
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// 记录error级别日志(错误信息)
  ///
  /// [message] 日志消息
  /// [tag] 日志标签，不填则自动获取调用者类名
  /// [error] 错误对象
  /// [stackTrace] 堆栈信息
  void e(dynamic message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    final actualTag = tag ?? _getCallerClassName();
    _logToLogcat(actualTag, message, Level.error,
        error: error, stackTrace: stackTrace);
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// 记录wtf级别日志(严重错误，What a Terrible Failure)
  ///
  /// [message] 日志消息
  /// [tag] 日志标签，不填则自动获取调用者类名
  /// [error] 错误对象
  /// [stackTrace] 堆栈信息
  void wtf(dynamic message,
      {String? tag, dynamic error, StackTrace? stackTrace}) {
    final actualTag = tag ?? _getCallerClassName();
    _logToLogcat(actualTag, message, Level.fatal,
        error: error, stackTrace: stackTrace);
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// 自定义日志输出类
/// 同时输出到控制台和 Logcat
class _LogcatOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // 输出到控制台（所有平台）
    final lines = event.lines;
    for (final line in lines) {
      // ignore: avoid_print
      print(line);
    }
  }
}
