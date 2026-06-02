import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class AdminShortsUploadPage extends StatefulWidget {
  const AdminShortsUploadPage({super.key});

  @override
  State<AdminShortsUploadPage> createState() => _AdminShortsUploadPageState();
}


class _AdminShortsUploadPageState extends State<AdminShortsUploadPage> {
  static const String _createDraftUrl =
      'https://createshortsvideodraft-uuyhs3r7gq-uc.a.run.app';

  static const String _publishUrl =
      'https://us-central1-amasya-son-dakika.cloudfunctions.net/publishShortsVideo';

  static const String _cdnHostname = 'vz-4f8f1583-226.b-cdn.net';

  static const String _bunnyStreamApiKey = 'fc822158-84bf-42e6-9e9a7e7b15f1-319e-454b';

  final Dio _dio = Dio();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _sourceNameController =
  TextEditingController(text: 'Amasya Son Dakika');
  final TextEditingController _sourceUsernameController =
  TextEditingController(text: '@amasyasondakika');
  final TextEditingController _sourceUrlController =
  TextEditingController(text: 'https://instagram.com/amasyasondakika');
  final TextEditingController _channelController =
  TextEditingController(text: 'Video Gündem');

  PlatformFile? _selectedFile;
  bool _uploading = false;
  double _progress = 0;
  String? _message;

  @override
  void dispose() {
    _titleController.dispose();
    _sourceNameController.dispose();
    _sourceUsernameController.dispose();
    _sourceUrlController.dispose();
    _channelController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
      withData: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (file.size > 50 * 1024 * 1024) {
      setState(() {
        _message = 'Video 50 MB üzerinde olamaz.';
      });
      return;
    }

    setState(() {
      _selectedFile = file;
      _message = null;
    });
  }

  Future<void> _upload() async {
    final file = _selectedFile;
    final title = _titleController.text.trim();

    if (file == null || file.path == null) {
      setState(() => _message = 'Lütfen bir video seç.');
      return;
    }

    if (title.isEmpty) {
      setState(() => _message = 'Başlık zorunlu.');
      return;
    }

    setState(() {
      _uploading = true;
      _progress = 0;
      _message = 'Video hazırlanıyor...';
    });

    try {
      final draftRes = await _dio.post(
        _createDraftUrl,
        data: {
          'title': title,
          'description': '',
          'sourceName': _sourceNameController.text.trim(),
          'sourceUsername': _sourceUsernameController.text.trim(),
          'sourcePlatform': 'instagram',
          'sourceUrl': _sourceUrlController.text.trim(),
          'channelName': _channelController.text.trim(),
        },
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

      final data = Map<String, dynamic>.from(draftRes.data as Map);

      final docId = data['docId']?.toString() ?? '';
      final videoId = data['videoId']?.toString() ?? '';
      final uploadUrl = data['uploadUrl']?.toString() ?? '';

      debugPrint('DRAFT RESPONSE: $data');
      debugPrint('BUNNY UPLOAD URL: $uploadUrl');

      if (docId.isEmpty || videoId.isEmpty || uploadUrl.isEmpty) {
        throw Exception('Upload bilgileri alınamadı.');
      }

      setState(() {
        _message = 'Video Bunny’ye yükleniyor...';
      });

      final videoFile = File(file.path!);
      final videoBytes = await videoFile.readAsBytes();
      final uploadRes = await _dio.put(
        uploadUrl,
        data: videoBytes,
        options: Options(
          headers: {
            'AccessKey': _bunnyStreamApiKey.trim(),
            'Content-Type': 'application/octet-stream',
          },
          responseType: ResponseType.plain,
          validateStatus: (status) => true,
        ),
        onSendProgress: (sent, total) {
          if (total <= 0) return;
          setState(() {
            _progress = sent / total;
          });
        },
      );

      debugPrint('BUNNY STATUS: ${uploadRes.statusCode}');
      debugPrint('BUNNY RESPONSE: ${uploadRes.data}');

      if (uploadRes.statusCode != 200 && uploadRes.statusCode != 201) {
        throw Exception(
          'Bunny upload hatası: ${uploadRes.statusCode} ${uploadRes.data}',
        );
      }

      setState(() {
        _message = 'Video yayına alınıyor...';
      });

      await _dio.post(
        _publishUrl,
        data: {
          'docId': docId,
          'videoId': videoId,
          'cdnHostname': _cdnHostname,
        },
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
          validateStatus: (status) => true,
        ),
      );

      setState(() {
        _uploading = false;
        _progress = 1;
        _message = 'Video başarıyla yüklendi.';
        _selectedFile = null;
        _titleController.clear();
      });
    } catch (e) {
      setState(() {
        _uploading = false;
        _message = 'Yükleme hatası: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _selectedFile?.name ?? 'Video seçilmedi';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shorts Video Yükle'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Field(controller: _titleController, label: 'Başlık'),
          _Field(controller: _sourceNameController, label: 'Kaynak adı'),
          _Field(
            controller: _sourceUsernameController,
            label: 'Kaynak kullanıcı adı',
          ),
          _Field(controller: _sourceUrlController, label: 'Kaynak linki'),
          _Field(controller: _channelController, label: 'Kanal'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _uploading ? null : _pickVideo,
            icon: const Icon(Icons.video_file_rounded),
            label: Text(fileName),
          ),
          const SizedBox(height: 14),
          if (_uploading) ...[
            LinearProgressIndicator(value: _progress == 0 ? null : _progress),
            const SizedBox(height: 12),
          ],
          ElevatedButton.icon(
            onPressed: _uploading ? null : _upload,
            icon: const Icon(Icons.cloud_upload_rounded),
            label: const Text('Videoyu Yükle'),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(
              _message!,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}