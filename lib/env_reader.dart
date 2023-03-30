import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart'
    show getApplicationSupportDirectory;
import 'package:path/path.dart' show separator;

class EnvReader {
  EnvReader();
  Future<void> save(String str) async {
    final envFilePath =
        '${(await getApplicationSupportDirectory()).path}$separator.env';
    File file = File(envFilePath);
    File developmentEnvFile = File('.env');
    if (await file.exists()) {
      await file.writeAsString(str);

      return;
    }

    //create development envFile
    await developmentEnvFile.create().then((value) => file
        .writeAsString(
            'THIS FILE IS NOT RESPONSIBLE OF THE CONNECTION OF YOUR DB - THE REAL FILE IS THE SUPPORT DIRECTORY OF THIS APP\n')
        .then((_) => file.writeAsStringSync(
            String.fromCharCodes(base64Decode(str)),
            mode: FileMode.append)));

    //file is created in case it does not exist.

    await file.create().then((file) {
      file.writeAsStringSync(str);
    });
  }

  Future<File> load() async {
    final envFilePath =
        '${(await getApplicationSupportDirectory()).path}$separator.env';
    print(envFilePath);
    File file = File(envFilePath);
    File developmentEnvFile = File('.env');
    //exists env file at root
    if (await file.exists()) {
      var res = _decode(file);
      Map<String, String> mapper = {};
      for (String r in res) {
        var splitter = r.trim().split('=');
        mapper.addAll({splitter[0]: splitter[1]});
      }
      _env.addAll(mapper);
      return file;
    }
    await developmentEnvFile
        .create()
        .then((value) => file.writeAsStringSync(_magicString));
    //file is created in case it does not exist.

    await file.create().then((file) => file.writeAsStringSync(_magicString));
    return file;
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
    return base64Encode(configuration.trim().codeUnits);
  }

  final Map<String, String> _env = {};
  Map<String, dynamic> get env => _env;
}

const _magicString =
    'ZGI9bXlzcWwKaG9zdD1sb2NhbGhvc3QKdXNlcj1yb290CnBhc3N3b3JkPXJvb3QKcG9ydD0zMzA2';
