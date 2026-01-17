// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '时影';

  @override
  String get projectList => '项目';

  @override
  String get createProject => '创建项目';

  @override
  String get projectName => '项目名称';

  @override
  String get projectNameHint => '输入项目名称';

  @override
  String get shootingInterval => '拍摄间隔';

  @override
  String intervalSeconds(Object seconds) {
    return '$seconds 秒';
  }

  @override
  String intervalMinutes(Object minutes) {
    return '$minutes 分钟';
  }

  @override
  String intervalHours(Object hours) {
    return '$hours 小时';
  }

  @override
  String get totalShots => '拍摄总数';

  @override
  String get totalShotsHint => '拍摄照片数量';

  @override
  String get duration => '持续时间';

  @override
  String durationMinutes(Object minutes) {
    return '$minutes 分钟';
  }

  @override
  String get cameraSettings => '相机设置';

  @override
  String get lockFocus => '锁定对焦';

  @override
  String get lockExposure => '锁定曝光';

  @override
  String get autoWhiteBalance => '自动白平衡';

  @override
  String get startShooting => '开始拍摄';

  @override
  String get stopShooting => '停止';

  @override
  String get projectRunning => '运行中';

  @override
  String get projectCompleted => '已完成';

  @override
  String get projectIdle => '空闲';

  @override
  String completedShots(Object count) {
    return '已完成：$count 张';
  }

  @override
  String nextShot(Object time) {
    return '下次拍摄：$time';
  }

  @override
  String currentBattery(Object level) {
    return '电量：$level%';
  }

  @override
  String get deleteProject => '删除项目';

  @override
  String get confirmDelete => '确定要删除此项目吗？';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get error => '错误';

  @override
  String get permissionDenied => '权限被拒绝';

  @override
  String get cameraPermissionRequired => '需要相机权限';

  @override
  String get storagePermissionRequired => '需要存储权限';

  @override
  String get noProjects => '暂无项目';

  @override
  String get tapToCreate => '点击 + 创建项目';
}
