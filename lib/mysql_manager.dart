import 'dart:io';

import 'package:mysql_client/mysql_client.dart';
import 'package:mysql_manager_flutter/env_reader.dart';
import 'package:mysql_manager_flutter/errors/env_reader_exceptions.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class MySQLManager {
  //attributes
  static MySQLManager? _manager;
  MySQLConnection? _conn;

  int? _timeout;

  static Map<String, dynamic> _connectionConfig = const {};

  //private constructor
  MySQLManager._();

  //getters
  ///Getter of MySQLManager instance. This is the entry point to use this class and get the connection
  ///[final manager = MySQLManager.instance]
  ///[final connection = manager.conn;]
  static MySQLManager get instance {
    _manager ??= MySQLManager._();
    return _manager!;
  }

  ///Getter of MySQLConnection object
  ///
  MySQLConnection? get conn => _conn;

  ///Initialize connection to mysql using both .env file or configuration map.
  ///
  ///if [useEnvFile] is setted to true a [config] Map<String,dynamic> is needed.
  /// It's a requirement for this [config] map to have the following structure:
  ///
  /// ``` Map<String,dynamic> config = {'db':'your_db_name','host':'your_mysql_host', 'user':'your_mysql_user', password: 'your_mysql_password', 'port': your_port}```;
  ///
  ///However, if you use .env file for the configuration, you can use this method without parameters.
  ///.env file should be located at root and each property should have exactly the same key as the config map of above
  ///keys are separated from their values with a = without spaces between them: db=YOUR_DABATABASE
  ///
  ///returns a [MySqlConnection] object which can be used to manipulate directly to query or close the connection;
  ///
  ///If there's a error in the .env file a ```BadMySQLConfigException``` will be thrown.
  ///On the other hand, when not using .env file and setting the configuration directly at [config] argument and the map
  ///has not the correct structure, a ```BadMySQLCodeConfig``` will be raised.
  Future<MySQLConnection> init(
      {bool useEnvFile = true,
      Map<String, String> config = const {},
      int? timeoutMs}) async {
    _timeout = timeoutMs;
    if (useEnvFile) {
      try {
        await _initWithEnv();
      } on BadMySQLConfigException catch (err) {
        print(err.toString());
        throw BadMySQLConfigException();
      }
    } else {
      try {
        await _selfInit(config: config);
      } on BadMySQLCodeConfigException catch (err) {
        print(err.toString());
      }
    }
    return conn!;
  }

  ///close connection
  Future<void> close() async => await _conn!.close();

  ///query
  Future<IResultSet> query(String sql, [Map<String, dynamic>? values]) async {
    if (_conn == null) {
      throw Exception('MySQL Connection has not been initialized.');
    }
    return _conn!.execute(sql, values);
  }

  //initialize with env file
  Future<void> _initWithEnv() async {
    //read .env file
    Map<String, dynamic> env = {};
    if (_connectionConfig.isEmpty) {
      final envReader = EnvReader();
      await envReader.load();
      env = envReader.env;
      if (!_isConnectionConfigCorrect(env)) {
        throw BadMySQLConfigException();
      }
      _connectionConfig = env;
    }
    final connection = await MySQLConnection.createConnection(
        host: _connectionConfig['host'],
        port: int.parse(_connectionConfig['port']),
        userName: _connectionConfig['user'],
        password: _connectionConfig['password'],
        databaseName: _connectionConfig['db']);
    await connection.connect(timeoutMs: _timeout ?? 4000);
    _conn = connection;
  }

  Future<void> _selfInit({Map<String, dynamic> config = const {}}) async {
    if (_connectionConfig.isEmpty) {
      if (!_isConnectionConfigCorrect(config)) {
        throw BadMySQLCodeConfigException();
      }
      _connectionConfig = config;
    }

    final connection = await MySQLConnection.createConnection(
        host: _connectionConfig['host'],
        port: int.parse(_connectionConfig['port']),
        userName: _connectionConfig['user'],
        password: _connectionConfig['password'],
        databaseName: _connectionConfig['db']);

    await connection.connect(timeoutMs: _timeout ?? 4000);
    _conn = connection;
  }

  bool _isConnectionConfigCorrect(Map<String, dynamic> config) {
    List<String> configArguments = ['host', 'user', 'db', 'password', 'port'];
    for (String argument in configArguments) {
      if (!config.containsKey(argument)) return false;
    }
    return true;
  }

  Map<String, String> _getConfiguration(String str) {
    str = str.trim();
    final lines = str.split('\n');
    Map<String, String> mapper = {};
    for (final line in lines) {
      final keyValue = line.split('=');
      mapper.addAll({keyValue.first: keyValue.last});
    }
    return mapper;
  }

  Future<void> saveDatabaseConfiguration(Map<String,String> config) async {
    //the configuration is correct if the map has the needed keys
    config.addAll({'db': 'mysql'});
    if (!_isConnectionConfigCorrect(config)) {
      throw BadMySQLCodeConfigException();
    }
    final envReader = EnvReader();
    final configuration = envReader.encode(config);
    await envReader.save(configuration);
  }

  Future<void> saveDatabaseConfigurationOnce(Map<String, String> config) async {
    final mPath =
        '${(await getApplicationSupportDirectory()).path}$separator.env';
    File file = File(mPath);
    if (file.existsSync()) {
      return;
    }

    if (!_isConnectionConfigCorrect(config)) {
      throw BadMySQLCodeConfigException();
    }
    final envReader = EnvReader();
    final configuration = envReader.encode(config);
    await envReader.save(configuration);
  }
}
