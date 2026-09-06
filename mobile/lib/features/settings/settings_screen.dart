import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/remote/server_url.dart';
import 'sync_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(serverUrlProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('SINKRONISASI'),
          ),
          const SyncTile(),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text('SERVER'),
          ),
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('URL server'),
            subtitle: Text(url),
            trailing: TextButton(
              onPressed: () => _editDialog(context, ref, url),
              child: const Text('Ubah'),
            ),
          ),
          const _TestConnectionTile(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Isi IP LAN laptop, mis. http://192.168.1.10:3000. '
              'Laptop & HP harus satu WiFi + backend nyala.',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editDialog(
      BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('URL Server'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'http://192.168.1.10:3000',
            ),
            validator: (v) => (v == null || !isValidServerUrl(v))
                ? 'Format salah (http:// atau https:// + host)'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (saved == true) {
      await ref.read(serverUrlProvider.notifier).set(controller.text);
    }
  }
}

class _TestConnectionTile extends ConsumerStatefulWidget {
  const _TestConnectionTile();

  @override
  ConsumerState<_TestConnectionTile> createState() => _TestConnectionTileState();
}

class _TestConnectionTileState extends ConsumerState<_TestConnectionTile> {
  bool _testing = false;
  String? _result;
  bool _ok = false;

  Future<void> _test() async {
    setState(() {
      _testing = true;
      _result = null;
    });
    final url = ref.read(serverUrlProvider);
    try {
      final dio = Dio(BaseOptions(
        baseUrl: url,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      final res = await dio.get<Map<String, dynamic>>('/health');
      final ok = res.statusCode == 200 && res.data?['status'] == 'ok';
      setState(() {
        _ok = ok;
        _result = ok ? 'Backend OK' : 'Respons ga sesuai (HTTP ${res.statusCode})';
      });
    } on DioException catch (e) {
      setState(() {
        _ok = false;
        _result = e.response != null
            ? 'HTTP ${e.response?.statusCode}'
            : 'Ga kejangkau — cek IP / WiFi / backend nyala';
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: const Icon(Icons.wifi_tethering),
      title: const Text('Test koneksi'),
      subtitle: _result == null
          ? null
          : Text(
              _result!,
              style: TextStyle(color: _ok ? scheme.primary : scheme.error),
            ),
      trailing: _testing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : OutlinedButton(onPressed: _test, child: const Text('Cek')),
    );
  }
}
