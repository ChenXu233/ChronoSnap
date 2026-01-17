import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  /// 导出项目照片为 ZIP 文件
  /// 返回生成的 ZIP 文件路径
  Future<String> exportProjectToZip({
    required String projectName,
    required String storagePath,
    void Function(int current, int total)? onProgress,
  }) async {
    // 获取项目照片目录
    final directory = await getApplicationDocumentsDirectory();
    final projectDir = Directory('${directory.path}/$storagePath');

    if (!await projectDir.exists()) {
      throw Exception('项目照片目录不存在: ${projectDir.path}');
    }

    // 获取所有照片文件
    final files = projectDir.listSync(recursive: true).where((entity) {
      return entity is File && _isImageFile(entity.path);
    }).cast<File>().toList();

    if (files.isEmpty) {
      throw Exception('没有找到照片文件');
    }

    // 按文件名排序
    files.sort((a, b) => a.path.compareTo(b.path));

    // 创建 ZIP
    final encoder = ZipEncoder();
    final archive = Archive();

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final bytes = await file.readAsBytes();
      final fileName = file.path.split(Platform.pathSeparator).last;

      archive.addFile(ArchiveFile(
        '$projectName/$fileName',
        bytes.length,
        bytes,
      ));

      onProgress?.call(i + 1, files.length);
    }

    // 生成 ZIP 文件
    final zipBytes = encoder.encode(archive)!;
    final zipDir = Directory('${directory.path}/exports');

    if (!await zipDir.exists()) {
      await zipDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final zipFileName = '${projectName}_$timestamp.zip';
    final zipFile = File('${zipDir.path}/$zipFileName');
    await zipFile.writeAsBytes(zipBytes);

    return zipFile.path;
  }

  /// 分享 ZIP 文件
  Future<void> shareZip(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'ChronoSnap 项目导出');
  }

  /// 检查项目是否有照片
  Future<bool> hasPhotos(String storagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final projectDir = Directory('${directory.path}/$storagePath');

    if (!await projectDir.exists()) return false;

    return projectDir.listSync().any((entity) {
      return entity is File && _isImageFile(entity.path);
    });
  }

  /// 获取照片数量
  Future<int> getPhotoCount(String storagePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final projectDir = Directory('${directory.path}/$storagePath');

    if (!await projectDir.exists()) return 0;

    return projectDir.listSync(recursive: true).where((entity) {
      return entity is File && _isImageFile(entity.path);
    }).length;
  }

  bool _isImageFile(String path) {
    final ext = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }
}
