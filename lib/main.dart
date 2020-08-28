import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:http/http.dart' as http;

import 'package:geolocator/geolocator.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:salat_alarm/AladhanAPI.dart';

void printHello() {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  print("[$now] Hello, world! isolate=${isolateId} function='$printHello'");
}

Future<void> main() async {
  // final int helloAlarmID = 0;
  // await AndroidAlarmManager.initialize();
  runApp(MyApp());
  // await AndroidAlarmManager.periodic(
  //     const Duration(seconds: 1), helloAlarmID, printHello);
}
// void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.access_time),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SalatTimes(),
              ),
            );
          }),
    );
  }
}

class SalatTimes extends StatelessWidget {
  Future<List<Timings>> _getSalat() async {
    // var ret = 0;
    // Salat salat;
    // while (ret != 1) {
    //   var data = await http.get("https://muslimsalat.com/daily.json");
    //   var jsonData = json.decode(data.body);
    //   salat = Salat.fromJson(jsonData);
    //   ret = salat.statusValid;
    // }
    // return salat.items;
    var location = await _getLocation();
    // int ret = 0;
    List<Timings> _items = new List<Timings>();
    var jsonData;
    while (_items.length == 0) {
      var data = await http.get(
          "http://api.aladhan.com/v1/calendar?latitude=${location.latitude.toString()}&longitude=${location.longitude.toString()}&method=5");

      jsonData = json.decode(data.body);
      // print(data.body);
      if (jsonData["data"] != null) {
        // print("items not null");
        _items = new List<Timings>();
        // print(jsonData["data"]);
        jsonData["data"].forEach((v) {
          _items.add(new Timings.fromJson(v["timings"]));
        });

        // var now = new DateTime.now();
        // print(new Timings.fromJson(jsonData["data"][now.day - 1]["timings"])
        //     .asr
        //     .substring(0, 5));
      }
    }
    return _items;
  }

  Future<Position> _getLocation() async {
    Position position = await Geolocator()
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.low);
    return position;
    // List<Placemark> placemarks = await Geolocator()
    //     .placemarkFromCoordinates(position.latitude, position.longitude);
    // placemarks.forEach((f) {
    //   print(f.toJson());
    // });
    // return placemarks[0].locality;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: _getLocation(),
          builder: (c, snapshot) {
            if (snapshot.hasData) {
              return Text(snapshot.data);
            } else if (snapshot.hasError) {
              return Container(
                child: Center(
                  child: Text("Error: ${snapshot.error}"),
                ),
              );
            }
            return Center(child: Text("loading"));
          },
        ),
      ),
      body: Container(
          child: FutureBuilder(
        future: _getSalat(),
        builder: (context, AsyncSnapshot<List<Timings>> snapshot) {
          print("future");
          if (snapshot.hasData) {
            return createListView(snapshot);
          } else if (snapshot.hasError) {
            return Container(
              child: Center(
                child: Text("Error: ${snapshot.error}"),
              ),
            );
          }
          return Container(
            child: Center(
              child: Column(
                children: <Widget>[
                  CircularProgressIndicator(),
                  Text("loading"),
                ],
              ),
            ),
          );
        },
      )),
    );
  }

  List<Widget> parseItems(Timings item) {
    var l = List<Widget>();
    var itemJson = item.toJson();

    itemJson.forEach((str, obj) {
      l.add(
        ListTile(
          title: new Text(str),
          subtitle: new Text(obj.toString()),
        ),
      );
      // l.add(new Divider(
      //   height: 2.0,
      // ));
    });
    return l;
  }

  Widget createListView(AsyncSnapshot snapshot) {
    List<Timings> values = snapshot.data;
    // print(values.length);
    return new ListView.builder(
      itemCount: values.length,
      itemBuilder: (BuildContext context, int index) {
        print("listview");
        return new Column(
          children: <Widget>[
            ...parseItems(values[index]),
            new Divider(
              height: 2.0,
            ),
          ],
        );
      },
    );
  }
}
