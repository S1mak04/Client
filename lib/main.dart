import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class User {
  String username;
  String password;
  String token;
  String uuid;

  User({this.username, this.password});

  void fromMap(Map<String, dynamic> map) {
    this.token = map["token"];
    this.uuid = map["uuid"];
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    map["username"] = username;
    map["password"] = password;
    return map;
  }

  Future<int> create() async {
    http.Response resp = await http.post(
      'http://192.168.1.177:6001/user/create',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(toMap()),
    );
    int status = resp.statusCode;
    return status;
  }

  Future<Map<String, dynamic>> secure() async {
    http.Response resp = await http.get(
      'http://192.168.1.177:6001/v1/secure',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
    );
    print(resp.statusCode);
    Map<String, dynamic> body;
    if (resp.statusCode == 200) {
      body = jsonDecode(resp.body);
    }
    return body;
  }

  Future<int> auth() async {
    http.Response resp = await http.post(
      'http://192.168.1.177:6001/user/auth',
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(toMap()),
    );
    int status = resp.statusCode;
    fromMap(jsonDecode(resp.body));
    return status;
  }
}

class HomePage extends StatelessWidget {
  User usr = User();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        TextField(
          controller: usernameController,
          decoration: InputDecoration(hintText: "Write username"),
        ),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(hintText: "Write password"),
        ),
        FlatButton(
          child: Text("register"),
          onPressed: () {
            usr.username = usernameController.value.text;
            usr.password = passwordController.value.text;
            usr.create().then((statusCode) {
              if (statusCode != 201) {
                print("error");
              } else {
                usr.auth().then((value) {
                  if (value == 200) {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MainPage(
                              usr: usr,
                            )));
                  } else {
                    print("auth error");
                  }
                });
              }
            });
          },
        ),
        FlatButton(child: Text("Auth"), onPressed: () {
          usr.username = usernameController.value.text;
          usr.password = passwordController.value.text;
          usr.auth().then((value) {
            if (value == 200) {
              Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MainPage(
                              usr: usr,)));
            }
            else {
              print("Auth error");
            }
          });        },)
      ],
    ));
  }
}

class MainPage extends StatelessWidget {
  final User usr;

  const MainPage({Key key, this.usr}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        Center(
          child: Text(
            """
            Username: ${usr.username}
            Password: ${usr.password}
            User Token: ${usr.token}
            User Uuid: ${usr.uuid}
            """,
            style: TextStyle(
              color: Colors.pink,
              fontSize: 20,
            ),
          ),
        ),
        FlatButton(
          child: Text("Get Secure"),
          onPressed: () async {
            var resp = await usr.secure();
            if (resp == null) {
              print("Error");
            } else {
              print(resp["token"]["Claims"]["uuid"]);
            }
          },
        )
      ],
    ));
  }
}
