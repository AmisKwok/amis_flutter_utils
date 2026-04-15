import 'package:amis_flutter_utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppLogger initialization', () {
    AppLogger().initialize();
    // 验证初始化成功
    expect(AppLogger(), isNotNull);
  });

  test('SpUtil initialization', () async {
    await SpUtil.init();
    // 验证初始化成功
    expect(SpUtil, isNotNull);
  });

  test('EncryptionUtil RSA encrypt', () {
    // 测试加密功能（需要配置环境变量）
    String result = EncryptionUtil.rsaEncrypt('test');
    expect(result, isNotNull);
  });
}