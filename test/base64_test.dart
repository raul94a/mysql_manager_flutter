import 'dart:convert';

void main(List<String> args) {
   print(base64Encode('db=mysql\nhost=localhost\nuser=root\npassword=root\nport=3306'.codeUnits));
   print(String.fromCharCodes(base64Decode('ZGI9bXlzcWwKaG9zdD1sb2NhbGhvc3QKdXNlcj1yb290CnBhc3N3b3JkPXJvb3QKcG9ydD0zMzA2')));
}