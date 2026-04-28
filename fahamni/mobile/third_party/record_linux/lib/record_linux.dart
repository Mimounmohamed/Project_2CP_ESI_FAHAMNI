import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:record_platform_interface/record_platform_interface.dart';

const String _fmediaBin = 'fmedia';
const String _pipeProcName = 'record_linux';

class RecordLinux extends RecordPlatform {
  static void registerWith() {
    RecordPlatform.instance = RecordLinux();
  }

  RecordState _state = RecordState.stop;
  String? _path;
  StreamController<RecordState>? _stateStreamCtrl;

  @override
  Future<void> create(String recorderId) async {}

  @override
  Future<void> dispose(String recorderId) {
    _stateStreamCtrl?.close();
    return stop(recorderId);
  }

  @override
  Future<Amplitude> getAmplitude(String recorderId) {
    return Future<Amplitude>.value(
      Amplitude(current: -160.0, max: -160.0),
    );
  }

  @override
  Future<bool> hasPermission(String recorderId, {bool request = true}) {
    return Future<bool>.value(true);
  }

  @override
  Future<bool> isEncoderSupported(
    String recorderId,
    AudioEncoder encoder,
  ) async {
    switch (encoder) {
      case AudioEncoder.aacLc:
      case AudioEncoder.aacHe:
      case AudioEncoder.flac:
      case AudioEncoder.opus:
      case AudioEncoder.wav:
        return true;
      default:
        return false;
    }
  }

  @override
  Future<bool> isPaused(String recorderId) {
    return Future<bool>.value(_state == RecordState.pause);
  }

  @override
  Future<bool> isRecording(String recorderId) {
    return Future<bool>.value(_state == RecordState.record);
  }

  @override
  Stream<RecordState> onStateChanged(String recorderId) {
    _stateStreamCtrl ??= StreamController<RecordState>(
      onCancel: () {
        _stateStreamCtrl?.close();
        _stateStreamCtrl = null;
      },
    );

    return _stateStreamCtrl!.stream;
  }

  @override
  Future<void> pause(String recorderId) async {
    if (_state == RecordState.record) {
      await _callFMedia(<String>['--globcmd=pause'], recorderId: recorderId);
      _updateState(RecordState.pause);
    }
  }

  @override
  Future<void> resume(String recorderId) async {
    if (_state == RecordState.pause) {
      await _callFMedia(<String>['--globcmd=unpause'], recorderId: recorderId);
      _updateState(RecordState.record);
    }
  }

  @override
  Future<void> start(
    String recorderId,
    RecordConfig config, {
    required String path,
  }) async {
    await stop(recorderId);

    final File file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }

    final bool supported = await isEncoderSupported(recorderId, config.encoder);
    if (!supported) {
      throw Exception('${config.encoder} is not supported.');
    }

    String numChannels;
    if (config.numChannels == 6) {
      numChannels = '5.1';
    } else if (config.numChannels == 8) {
      numChannels = '7.1';
    } else if (config.numChannels == 1 || config.numChannels == 2) {
      numChannels = config.numChannels.toString();
    } else {
      throw Exception('${config.numChannels} config is not supported.');
    }

    await _callFMedia(
      <String>[
        '--notui',
        '--background',
        '--record',
        '--out=$path',
        '--rate=${config.sampleRate}',
        '--channels=$numChannels',
        '--globcmd=listen',
        '--gain=6.0',
        if (config.device != null) '--dev-capture=${config.device!.id}',
        ..._getEncoderSettings(config.encoder, config.bitRate),
      ],
      onStarted: () {
        _path = path;
        _updateState(RecordState.record);
      },
      consumeOutput: false,
      recorderId: recorderId,
    );
  }

  @override
  Future<Stream<Uint8List>> startStream(
    String recorderId,
    RecordConfig config,
  ) {
    return Future<Stream<Uint8List>>.error(
      UnsupportedError(
        'Audio stream recording is not supported by the patched Linux backend.',
      ),
    );
  }

  @override
  Future<String?> stop(String recorderId) async {
    final String? path = _path;

    await _callFMedia(<String>['--globcmd=stop'], recorderId: recorderId);
    await _callFMedia(<String>['--globcmd=quit'], recorderId: recorderId);

    _updateState(RecordState.stop);

    return path;
  }

  @override
  Future<void> cancel(String recorderId) async {
    final String? path = await stop(recorderId);

    if (path != null) {
      final File file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  @override
  Future<List<InputDevice>> listInputDevices(String recorderId) async {
    final StreamController<List<int>> outStreamCtrl =
        StreamController<List<int>>();

    final List<String> out = <String>[];
    outStreamCtrl.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String chunk) {
      out.add(chunk);
    });

    try {
      await _callFMedia(
        <String>['--list-dev'],
        recorderId: '',
        outStreamCtrl: outStreamCtrl,
      );

      return _listInputDevices(recorderId, out);
    } finally {
      outStreamCtrl.close();
    }
  }

  List<String> _getEncoderSettings(AudioEncoder encoder, int bitRate) {
    switch (encoder) {
      case AudioEncoder.aacLc:
        return <String>['--aac-profile=LC', ..._getAacQuality(bitRate)];
      case AudioEncoder.aacHe:
        return <String>['--aac-profile=HEv2', ..._getAacQuality(bitRate)];
      case AudioEncoder.flac:
        return <String>['--flac-compression=6', '--format=int16'];
      case AudioEncoder.opus:
        final int rate = (bitRate ~/ 1000).clamp(6, 510);
        return <String>['--opus.bitrate=$rate'];
      case AudioEncoder.wav:
        return <String>[];
      default:
        return <String>[];
    }
  }

  List<String> _getAacQuality(int bitRate) {
    final int quality = (bitRate ~/ 1000).clamp(8, 800).toInt();
    return <String>['--aac-quality=$quality'];
  }

  Future<void> _callFMedia(
    List<String> arguments, {
    required String recorderId,
    StreamController<List<int>>? outStreamCtrl,
    VoidCallback? onStarted,
    bool consumeOutput = true,
  }) async {
    final Process process = await Process.start(_fmediaBin, <String>[
      '--globcmd.pipe-name=$_pipeProcName$recorderId',
      ...arguments,
    ]);

    if (onStarted != null) {
      onStarted();
    }

    if (consumeOutput) {
      final StreamController<List<int>> out =
          outStreamCtrl ?? StreamController<List<int>>();
      if (outStreamCtrl == null) {
        out.stream.listen((List<int> _) {});
      }

      process.stdout.listen(out.add);
      process.stderr.listen(out.add);
    }

    final int code = await process.exitCode;
    if (code != 0) {
      throw Exception('fmedia exited with code $code.');
    }
  }

  List<InputDevice> _listInputDevices(String recorderId, List<String> lines) {
    final List<InputDevice> devices = <InputDevice>[];
    final RegExp pattern = RegExp(r'^\s*(\d+)\.\s+(.*)$');

    for (final String line in lines) {
      final RegExpMatch? match = pattern.firstMatch(line);
      if (match == null) {
        continue;
      }

      final String id = match.group(1) ?? '';
      final String label = match.group(2) ?? '';
      if (id.isEmpty || label.isEmpty) {
        continue;
      }

      devices.add(InputDevice(id: id, label: label));
    }

    return devices;
  }

  void _updateState(RecordState state) {
    _state = state;
    _stateStreamCtrl?.add(state);
  }
}


