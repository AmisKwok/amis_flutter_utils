import 'package:amis_flutter_utils/src/utils/app_logger.dart';
import 'package:hive_flutter/adapters.dart';

/// Hive工具类，用于封装Hive数据库的操作
/// 封装了Hive数据库的初始化、打开Box等操作
/// 使用单例模式，确保全局只有一个HiveUtil实例
/// 在需要使用Hive数据库的地方，直接调用`HiveUtil().init()`即可
class HiveUtil {
  /// 私有构造函数，防止外部实例化
  HiveUtil._();

  /// 单例对象
  static final HiveUtil _instance = HiveUtil._();

  /// 工厂构造函数，返回单例对象
  factory HiveUtil() => _instance;

  // 存储默认的box名称
  String _defaultBoxName = 'default_box';

  /// 初始化Hive数据库
  /// [boxName] 要使用的默认Box名称
  /// [boxNamesList] 需要打开的其他Box名称列表
  /// [adapterList] 需要注册的适配器列表
  Future<void> init({
    required String boxName,
    List<String> boxNamesList = const [],
    List<dynamic> adapterList = const [],
  }) async {
    try {
      /// 初始化Hive数据库
      await Hive.initFlutter();

      /// 注册适配器
      for (var adapter in adapterList) {
        Hive.registerAdapter(adapter);
      }

      /// 存储默认box名称
      _defaultBoxName = boxName;

      /// 构建完整的box名称列表
      final allBoxNames = [boxName, ...boxNamesList];

      /// 打开Box
      for (var name in allBoxNames) {
        await Hive.openBox(name);
      }

      AppLogger().d('HiveUtil 初始化成功，默认Box: $_defaultBoxName');
    } catch (e) {
      AppLogger().e('HiveUtil 初始化失败: $e');
    }

    return;
  }

  /// 存储数据
  /// [key] 键
  /// [value] 值
  /// [boxName] Box名称，默认为初始化时指定的box名称
  Future<void> put(
      String key,
      dynamic value, {
        String? boxName,
      }) async {
    try {
      /// 获取Box
      Box box = _getBox(boxName ?? _defaultBoxName);

      /// 存储数据
      await box.put(key, value);
    } catch (e) {
      AppLogger().e('HiveUtil 存储数据失败: $e');
    }

    return;
  }

  /// 获取数据
  /// [key] 键
  /// [boxName] Box名称，默认为初始化时指定的box名称
  /// 返回数据
  T? get<T>(String key, {String? boxName}) {
    try {
      /// 获取Box
      Box box = _getBox(boxName ?? _defaultBoxName);

      /// 获取数据
      return box.get(key) as T?;
    } catch (e) {
      AppLogger().e('HiveUtil 获取数据失败: $e');
    }

    return null;
  }

  /// 获取Box
  /// [boxName] Box名称
  /// 返回Box对象
  Box<dynamic> _getBox(String boxName) {
    return Hive.box(boxName);
  }
}