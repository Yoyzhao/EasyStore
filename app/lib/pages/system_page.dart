import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/system_provider.dart';

class SystemPage extends StatefulWidget {
  const SystemPage({super.key});

  @override
  State<SystemPage> createState() => _SystemPageState();
}

class _SystemPageState extends State<SystemPage> {
  final _maxSizeCtrl = TextEditingController();
  final _extensionsCtrl = TextEditingController();
  bool _allowExternalIp = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final systemProvider = Provider.of<SystemProvider>(context, listen: false);
    await systemProvider.fetchSettings();
    setState(() {
      _maxSizeCtrl.text = systemProvider.settings['upload']['max_size_mb']
          .toString();
      _extensionsCtrl.text =
          (systemProvider.settings['upload']['allowed_extensions'] as List)
              .join(', ');
      _allowExternalIp = systemProvider.settings['access']['allow_external_ip'];
    });
  }

  Future<void> _saveSettings() async {
    final systemProvider = Provider.of<SystemProvider>(context, listen: false);
    final exts = _extensionsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final newSettings = {
      'upload': {
        'max_size_mb': int.tryParse(_maxSizeCtrl.text) ?? 5,
        'allowed_extensions': exts,
      },
      'access': {'allow_external_ip': _allowExternalIp},
    };

    final success = await systemProvider.saveSettings(newSettings);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('设置保存成功')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('设置保存失败')));
      }
    }
  }

  Future<void> _handleBackup() async {
    final systemProvider = Provider.of<SystemProvider>(context, listen: false);
    final success = await systemProvider.backup();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('备份下载成功')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('备份失败或取消')));
      }
    }
  }

  Future<void> _handleRestore() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('高危操作确认'),
          content: const Text('恢复数据将覆盖当前系统的所有数据（包括数据库和上传的图片）。此操作不可逆！是否确认恢复？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认恢复', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        final systemProvider = Provider.of<SystemProvider>(
          context,
          listen: false,
        );
        final success = await systemProvider.restore(result.files.single.path!);
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('系统数据恢复成功！请重启服务以确保数据生效。')),
            );
          } else {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('恢复数据失败')));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final systemProvider = Provider.of<SystemProvider>(context);

    if (systemProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('系统设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '上传限制设置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 400,
                  child: TextFormField(
                    controller: _maxSizeCtrl,
                    decoration: const InputDecoration(
                      labelText: '最大文件大小 (MB)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '控制系统允许上传的单个文件最大体积',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 400,
                  child: TextFormField(
                    controller: _extensionsCtrl,
                    decoration: const InputDecoration(
                      labelText: '允许的格式后缀 (逗号分隔)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '控制系统允许上传的文件后缀类型',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 32),

                const Text(
                  '访问安全设置',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('允许外部 IP 访问 API'),
                  subtitle: const Text('开发环境下是否允许跨域与外部网络请求本服务'),
                  value: _allowExternalIp,
                  onChanged: (val) {
                    setState(() => _allowExternalIp = val);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('保存设置'),
                ),

                const SizedBox(height: 48),
                const Divider(),
                const SizedBox(height: 32),

                const Text(
                  '备份与恢复',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.blue.withAlpha(26),
                          border: Border.all(color: Colors.blue.withAlpha(77)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.download, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  '数据备份',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '将当前的数据库文件、系统配置以及所有上传的图片附件打包下载到本地。建议定期备份以防数据丢失。',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleBackup,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text('下载系统备份'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.red.withAlpha(26),
                          border: Border.all(color: Colors.red.withAlpha(77)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.upload, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  '数据恢复',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              '上传之前下载的 .zip 备份文件进行数据恢复。\n⚠️ 警告：此操作将覆盖当前系统所有数据，请谨慎操作！',
                              style: TextStyle(color: Colors.black54),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _handleRestore,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade50,
                                  foregroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                                child: const Text('上传备份并恢复'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
