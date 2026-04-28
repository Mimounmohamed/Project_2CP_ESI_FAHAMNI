import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

// --- ATTACHMENT FEATURE START ---
class ComposerAttachment {
  const ComposerAttachment({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.mimeType,
    required this.kind,
    required this.localPath,
    this.bytes,
  });

  final String id;
  final String name;
  final int sizeBytes;
  final String mimeType;
  final String kind;
  final String localPath;
  final Uint8List? bytes;

  bool get isImage => kind == 'image';
}
// --- ATTACHMENT FEATURE END ---

class MessageInput extends StatefulWidget {
  const MessageInput({
    super.key,
    this.controller,
    this.onSend,
    this.onAiPressed,
    this.onVoicePressed,
    this.onSendVoice,
    this.attachmentUploadProgress = const <String, double>{},
    this.voiceUploadProgress,
  });

  final TextEditingController? controller;
  final Future<void> Function(String text, List<ComposerAttachment> attachments)?
      onSend;
  final VoidCallback? onAiPressed;
  final VoidCallback? onVoicePressed;
  // --- VOICE FEATURE START ---
  final Future<void> Function(String localPath, Duration duration)? onSendVoice;
  final double? voiceUploadProgress;
  // --- VOICE FEATURE END ---
  // --- ATTACHMENT FEATURE START ---
  final Map<String, double> attachmentUploadProgress;
  // --- ATTACHMENT FEATURE END ---

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  late final TextEditingController _internalController;
  final ImagePicker _imagePicker = ImagePicker();
  // --- VOICE FEATURE START ---
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _previewPlayer = AudioPlayer();
  static const Duration _maxVoiceDuration = Duration(minutes: 5);
  Timer? _recordingTicker;
  Duration _recordingDuration = Duration.zero;
  Duration _voicePreviewDuration = Duration.zero;
  String? _voicePreviewPath;
  bool _isRecording = false;
  bool _isVoiceSending = false;
  bool _voicePreviewReady = false;
  // --- VOICE FEATURE END ---
  TextEditingController get _controller =>
      widget.controller ?? _internalController;
  bool _isTextEmpty = true;
  bool _isSending = false;
  // --- ATTACHMENT FEATURE START ---
  final List<ComposerAttachment> _attachments = <ComposerAttachment>[];
  static const int _maxAttachments = 5;
  static const int _maxAttachmentBytes = 20 * 1024 * 1024;
  // --- ATTACHMENT FEATURE END ---

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController();
    _controller.addListener(_handleTextChanged);
    _handleTextChanged();
  }

  @override
  void didUpdateWidget(covariant MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      final TextEditingController oldController =
          oldWidget.controller ?? _internalController;
      oldController.removeListener(_handleTextChanged);
      _controller.addListener(_handleTextChanged);
      _handleTextChanged();
    }
  }

  void _handleTextChanged() {
    if (!mounted) return;
    final bool nextIsEmpty = _controller.text.isEmpty;
    if (_isTextEmpty == nextIsEmpty) return;
    setState(() {
      _isTextEmpty = nextIsEmpty;
    });
  }

  Future<void> _handleSend() async {
    if (_isSending || widget.onSend == null) {
      return;
    }

    if (_controller.text.trim().isEmpty && _attachments.isEmpty) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await widget.onSend!(
        _controller.text,
        List<ComposerAttachment>.from(_attachments),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _attachments.clear();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // --- ATTACHMENT FEATURE START ---
  Future<void> _showAttachmentSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AttachmentOptionTile(
                  icon: Icons.perm_media_outlined,
                  title: 'Photo / Video',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showMediaSourceSheet();
                  },
                ),
                const SizedBox(height: 12),
                _AttachmentOptionTile(
                  icon: Icons.insert_drive_file_outlined,
                  title: 'File',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickFileAttachment();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMediaSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AttachmentOptionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Gallery Photos',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickGalleryImages();
                  },
                ),
                const SizedBox(height: 12),
                _AttachmentOptionTile(
                  icon: Icons.video_library_outlined,
                  title: 'Gallery Video',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickGalleryVideo();
                  },
                ),
                const SizedBox(height: 12),
                _AttachmentOptionTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Camera Photo',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickCameraImage();
                  },
                ),
                const SizedBox(height: 12),
                _AttachmentOptionTile(
                  icon: Icons.videocam_outlined,
                  title: 'Camera Video',
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickCameraVideo();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickGalleryImages() async {
    final List<XFile> files = await _imagePicker.pickMultiImage();
    if (files.isEmpty) {
      return;
    }
    await _addXFiles(
      files: files,
      mimeTypeResolver: (XFile file) => _imageMimeType(file.path),
      kindResolver: (_) => 'image',
    );
  }

  Future<void> _pickGalleryVideo() async {
    final XFile? file = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
    );
    if (file == null) {
      return;
    }
    await _addXFiles(
      files: <XFile>[file],
      mimeTypeResolver: (XFile value) => _videoMimeType(value.path),
      kindResolver: (_) => 'file',
    );
  }

  Future<void> _pickCameraImage() async {
    final XFile? file = await _imagePicker.pickImage(source: ImageSource.camera);
    if (file == null) {
      return;
    }
    await _addXFiles(
      files: <XFile>[file],
      mimeTypeResolver: (XFile value) => _imageMimeType(value.path),
      kindResolver: (_) => 'image',
    );
  }

  Future<void> _pickCameraVideo() async {
    final XFile? file = await _imagePicker.pickVideo(source: ImageSource.camera);
    if (file == null) {
      return;
    }
    await _addXFiles(
      files: <XFile>[file],
      mimeTypeResolver: (XFile value) => _videoMimeType(value.path),
      kindResolver: (_) => 'file',
    );
  }

  Future<void> _pickFileAttachment() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
      type: FileType.custom,
      allowedExtensions: const <String>[
        'pdf',
        'doc',
        'docx',
        'txt',
        'zip',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
      ],
    );

    if (result == null || !mounted) {
      return;
    }

    for (final PlatformFile file in result.files) {
      if (!_canAcceptMoreAttachments()) {
        break;
      }
      if (file.size > _maxAttachmentBytes) {
        _showToast('${file.name} exceeds the 20 MB limit.');
        continue;
      }
      if ((file.path ?? '').isEmpty) {
        _showToast('Unable to attach ${file.name}.');
        continue;
      }

      _attachments.add(
        ComposerAttachment(
          id: '${DateTime.now().microsecondsSinceEpoch}_${file.name}',
          name: file.name,
          sizeBytes: file.size,
          mimeType: _inferMimeTypeFromName(file.name),
          kind: 'file',
          localPath: file.path!,
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addXFiles({
    required List<XFile> files,
    required String Function(XFile file) mimeTypeResolver,
    required String Function(XFile file) kindResolver,
  }) async {
    for (final XFile file in files) {
      if (!_canAcceptMoreAttachments()) {
        break;
      }

      final int size = await file.length();
      if (size > _maxAttachmentBytes) {
        _showToast('${file.name} exceeds the 20 MB limit.');
        continue;
      }

      final Uint8List? bytes = kindResolver(file) == 'image'
          ? await file.readAsBytes()
          : null;

      _attachments.add(
        ComposerAttachment(
          id: '${DateTime.now().microsecondsSinceEpoch}_${file.name}',
          name: file.name,
          sizeBytes: size,
          mimeType: mimeTypeResolver(file),
          kind: kindResolver(file),
          localPath: file.path,
          bytes: bytes,
        ),
      );
    }

    if (mounted) {
      setState(() {});
    }
  }

  bool _canAcceptMoreAttachments() {
    if (_attachments.length >= _maxAttachments) {
      _showToast('You can attach up to $_maxAttachments files.');
      return false;
    }
    return true;
  }

  void _removeAttachment(String attachmentId) {
    setState(() {
      _attachments.removeWhere((ComposerAttachment a) => a.id == attachmentId);
    });
  }

  String _inferMimeTypeFromName(String fileName) {
    final String lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowerName.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerName.endsWith('.gif')) {
      return 'image/gif';
    }
    if (lowerName.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lowerName.endsWith('.mp4')) {
      return 'video/mp4';
    }
    if (lowerName.endsWith('.mov')) {
      return 'video/quicktime';
    }
    if (lowerName.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (lowerName.endsWith('.doc')) {
      return 'application/msword';
    }
    if (lowerName.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lowerName.endsWith('.xls')) {
      return 'application/vnd.ms-excel';
    }
    if (lowerName.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lowerName.endsWith('.ppt')) {
      return 'application/vnd.ms-powerpoint';
    }
    if (lowerName.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lowerName.endsWith('.txt')) {
      return 'text/plain';
    }
    if (lowerName.endsWith('.zip')) {
      return 'application/zip';
    }
    return 'application/octet-stream';
  }

  String _imageMimeType(String path) => _inferMimeTypeFromName(path);

  String _videoMimeType(String path) => _inferMimeTypeFromName(path);

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  // --- ATTACHMENT FEATURE END ---

  // --- VOICE FEATURE START ---
  Future<void> _handleVoiceLongPressStart() async {
    if (_isRecording || _isVoiceSending || widget.onSendVoice == null) {
      return;
    }

    final bool granted = await _ensureMicrophonePermission();
    if (!granted) {
      widget.onVoicePressed?.call();
      return;
    }

    await _discardVoicePreview(deleteFile: true);

    final Directory tempDirectory = await getTemporaryDirectory();
    final String recordingPath =
        '${tempDirectory.path}/voice_${DateTime.now().microsecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: recordingPath,
    );

    _recordingTicker?.cancel();
    _recordingDuration = Duration.zero;

    if (mounted) {
      setState(() {
        _isRecording = true;
      });
    }

    _recordingTicker = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
      if (_recordingDuration >= _maxVoiceDuration) {
        _handleVoiceLongPressEnd(autoStopped: true);
      }
    });
  }

  Future<void> _handleVoiceLongPressEnd({bool autoStopped = false}) async {
    if (!_isRecording) {
      return;
    }

    _recordingTicker?.cancel();
    _recordingTicker = null;

    final String? path = await _audioRecorder.stop();

    if (!mounted) {
      return;
    }

    setState(() {
      _isRecording = false;
    });

    if ((path ?? '').isEmpty) {
      return;
    }

    _voicePreviewPath = path;
    _voicePreviewDuration = _recordingDuration;
    await _prepareVoicePreview();

    if (autoStopped && mounted) {
      _showToast('Maximum voice duration reached. Review and send your message.');
    }
  }

  Future<void> _prepareVoicePreview() async {
    if ((_voicePreviewPath ?? '').isEmpty) {
      return;
    }

    await _previewPlayer.setFilePath(_voicePreviewPath!);
    final Duration? duration = _previewPlayer.duration;
    if (!mounted) {
      return;
    }
    setState(() {
      _voicePreviewReady = true;
      _voicePreviewDuration = duration ?? _voicePreviewDuration;
    });
  }

  Future<void> _toggleVoicePreviewPlayback() async {
    if (!_voicePreviewReady) {
      return;
    }

    if (_previewPlayer.playing) {
      await _previewPlayer.pause();
      return;
    }

    await _previewPlayer.play();
  }

  Future<void> _discardVoicePreview({bool deleteFile = false}) async {
    final String? path = _voicePreviewPath;
    await _previewPlayer.stop();
    await _previewPlayer.seek(Duration.zero);
    if (deleteFile && (path ?? '').isNotEmpty) {
      final File file = File(path!);
      if (await file.exists()) {
        await file.delete();
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _voicePreviewPath = null;
      _voicePreviewDuration = Duration.zero;
      _voicePreviewReady = false;
      _isVoiceSending = false;
    });
  }

  Future<void> _sendVoicePreview() async {
    if ((_voicePreviewPath ?? '').isEmpty ||
        widget.onSendVoice == null ||
        _isVoiceSending) {
      return;
    }

    setState(() {
      _isVoiceSending = true;
    });

    try {
      await widget.onSendVoice!(
        _voicePreviewPath!,
        _voicePreviewDuration,
      );
      await _discardVoicePreview(deleteFile: false);
    } finally {
      if (mounted) {
        setState(() {
          _isVoiceSending = false;
        });
      }
    }
  }

  Future<bool> _ensureMicrophonePermission() async {
    PermissionStatus status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }

    status = await Permission.microphone.request();
    if (status.isGranted) {
      return true;
    }

    if (!mounted) {
      return false;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Microphone access needed'),
          content: const Text(
            'Please allow microphone access so you can record voice messages.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open settings'),
            ),
          ],
        );
      },
    );

    return false;
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  // --- VOICE FEATURE END ---

  void _showToast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  void dispose() {
    _recordingTicker?.cancel();
    _controller.removeListener(_handleTextChanged);
    _internalController.dispose();
    _audioRecorder.dispose();
    _previewPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(20, 0, 0, 128),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- VOICE FEATURE START ---
              if (_isRecording) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.4, end: 1),
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeInOut,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: child,
                          );
                        },
                        onEnd: () {
                          if (mounted && _isRecording) {
                            setState(() {});
                          }
                        },
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Recording ${_formatDuration(_recordingDuration)}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFB91C1C),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Release to stop',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if ((_voicePreviewPath ?? '').isNotEmpty) ...[
                StreamBuilder<Duration>(
                  stream: _previewPlayer.positionStream,
                  builder: (context, snapshot) {
                    final Duration position = snapshot.data ?? Duration.zero;
                    final double maxMillis =
                        _voicePreviewDuration.inMilliseconds > 0
                            ? _voicePreviewDuration.inMilliseconds.toDouble()
                            : 1;
                    final double currentMillis =
                        position.inMilliseconds.clamp(0, maxMillis.toInt()).toDouble();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: _toggleVoicePreviewPlayback,
                                icon: Icon(
                                  _previewPlayer.playing
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_fill,
                                  color: const Color(0xFF000080),
                                  size: 30,
                                ),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                  ),
                                  child: Slider(
                                    value: currentMillis,
                                    max: maxMillis,
                                    onChanged: (double value) {
                                      _previewPlayer.seek(
                                        Duration(milliseconds: value.round()),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                '${_formatDuration(position)} / ${_formatDuration(_voicePreviewDuration)}',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                          if (widget.voiceUploadProgress != null) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: widget.voiceUploadProgress,
                              minHeight: 4,
                              backgroundColor: const Color(0xFFE2E8F0),
                              color: const Color(0xFF000080),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () => _discardVoicePreview(
                                  deleteFile: true,
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isVoiceSending ? null : _sendVoicePreview,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF000080),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Send'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
              // --- VOICE FEATURE END ---
              // --- ATTACHMENT FEATURE START ---
              if (_attachments.isNotEmpty)
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachments.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final ComposerAttachment attachment = _attachments[index];
                      final double? uploadProgress =
                          widget.attachmentUploadProgress[attachment.id];
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: attachment.isImage ? 60 : 190,
                            padding: attachment.isImage
                                ? EdgeInsets.zero
                                : const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: attachment.isImage
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: Image.file(
                                          File(attachment.localPath),
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) =>
                                              const ColoredBox(
                                                color: Color(0xFFE2E8F0),
                                                child: Icon(Icons.image_outlined),
                                              ),
                                        ),
                                      ),
                                      if (uploadProgress != null &&
                                          uploadProgress < 1)
                                        Center(
                                          child: CircularProgressIndicator(
                                            value: uploadProgress,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                    ],
                                  )
                                : Row(
                                    children: [
                                      const Icon(
                                        Icons.insert_drive_file_outlined,
                                        size: 20,
                                        color: Color(0xFF000080),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              attachment.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1F2937),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _formatFileSize(
                                                attachment.sizeBytes,
                                              ),
                                              style: GoogleFonts.inter(
                                                fontSize: 11,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                            if (uploadProgress != null &&
                                                uploadProgress < 1)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 6,
                                                ),
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    value: uploadProgress,
                                                    strokeWidth: 2.5,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: InkWell(
                              onTap: () => _removeAttachment(attachment.id),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F172A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              if (_attachments.isNotEmpty) const SizedBox(height: 10),
              // --- ATTACHMENT FEATURE END ---
              Row(
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.sentiment_satisfied_alt_outlined,
                      color: Color(0xFF000080),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.nunito(fontSize: 14),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) {
                        if (!_isSending) {
                          _handleSend();
                        }
                      },
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        hintStyle: TextStyle(color: Color(0xFF1F2937)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // --- ATTACHMENT FEATURE START ---
                  GestureDetector(
                    onTap: _showAttachmentSheet,
                    child: const Icon(
                      Icons.attach_file_outlined,
                      color: Color(0xFF1F2937),
                      size: 24,
                    ),
                  ),
                  // --- ATTACHMENT FEATURE END ---
                  if (_isTextEmpty &&
                      _attachments.isEmpty &&
                      (_voicePreviewPath ?? '').isEmpty) ...[
                    const SizedBox(width: 10),
                    // --- VOICE FEATURE START ---
                    GestureDetector(
                      onLongPressStart: (_) => _handleVoiceLongPressStart(),
                      onLongPressEnd: (_) => _handleVoiceLongPressEnd(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _isRecording
                              ? const Color(0xFFFEE2E2)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isRecording ? Icons.mic : Icons.mic_none_outlined,
                          color: _isRecording
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF1F2937),
                          size: 24,
                        ),
                      ),
                    ),
                    // --- VOICE FEATURE END ---
                  ] else
                    Transform.rotate(
                      angle: -45 * (3.14159 / 180),
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: Color(0xFF000080),
                          size: 28,
                        ),
                        onPressed: _isSending ? null : _handleSend,
                      ),
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: widget.onAiPressed,
                    icon: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF000080),
                      size: 22,
                    ),
                    tooltip: 'AI Assistant',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- ATTACHMENT FEATURE START ---
class _AttachmentOptionTile extends StatelessWidget {
  const _AttachmentOptionTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF000080)),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1F2937),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// --- ATTACHMENT FEATURE END ---


