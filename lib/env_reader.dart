import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart'
    show getApplicationSupportDirectory;
import 'package:path/path.dart' as path;

class EnvReader {
  EnvReader();
  Future<void> save(String str) async {
    final envFilePath =
        '${(await getApplicationSupportDirectory()).path}${path.separator}.env';
    File file = File(envFilePath);
    if (await file.exists()) {
      await file.writeAsString(str);
      return;
    }
    //file is created in case it does not exist.

    await file.create().then((file) {
      file.writeAsStringSync(str);
    });
  }

  Future<void> load() async {
    final envFilePath =
        '${(await getApplicationSupportDirectory()).path}${path.separator}.env';
    print(envFilePath);
    File file = File(envFilePath);
    //exists env file at root
    if (await file.exists()) {
      var res = _decode(file);
      Map<String, String> mapper = {};
      for (String r in res) {
        var splitter = r.trim().split('=');
        mapper.addAll({splitter[0]: splitter[1]});
      }
      _env.addAll(mapper);
      return;
    }
    //file is created in case it does not exist.

    await file.create().then((file) {
      file.writeAsStringSync(_magicString);
    });
  }

  List<String> _decode(File file) {
    final read = file.readAsStringSync();
    final bytes = base64Decode(read);
    return String.fromCharCodes(bytes).split('\n');
  }

  String encode(Map<String, String> config) {
    String configuration = '';
    final keys = config.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      String value = config[key]!;
      if (i < keys.length - 1) {
        configuration += '$key=$value\n';
      } else {
        configuration += '$key=$value';
      }
    }
    return configuration;
  }

  final Map<String, String> _env = {};
  Map<String, dynamic> get env => _env;
}

const _magicString =
    'ZGI9bXlzcWwKaG9zdD1sb2NhbGhvc3QKdXNlcj1yb290CnBhc3N3b3JkPXJvb3QKcG9ydD0zMzA2';
