import 'dart:convert';

void main(List<String> args) {
   print(base64Encode('db=mysql\nhost=localhost\nuser=root\npassword=root\nport=3306'.codeUnits));
 
}