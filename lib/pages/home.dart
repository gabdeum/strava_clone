import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:strava_add_on/services/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  XmlFiles newXmlFile = XmlFiles(xmlFileName: 'Test_1');
  Database? database;
  List<Map<String,Object?>> listData = [];
  List<Map<String,Object?>> results = [];
  StreamSubscription? locationSubscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Scaffold(
        appBar: AppBar(
          title: const Center(child: Text('Get data from XML file')),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10.0,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                      onPressed: () async {
                        Stream<LocationData>? locationStream = await getLocation();
                        locationSubscription = locationStream?.listen((event) async {
                          results = await newXmlFile.queryDb(database, event.latitude, event.longitude);
                          setState(() {});
                        });
                      },
                      child: const Text('Get location stream')),
                  const SizedBox(width: 10.0,),
                  OutlinedButton(
                      onPressed: () {
                        locationSubscription?.cancel();
                      },
                      child: const Text('Stop location sub')),
                ],
              ),
              const SizedBox(height: 10.0,),
              OutlinedButton(
                  onPressed: () async {
                    listData = await newXmlFile.getXmlContent(context);
                    database = await newXmlFile.createDb();
                    await newXmlFile.insertDb(listData, database);
                  },
                  child: const Text('Initialize data')),
              const SizedBox(height: 10.0,),
              const Center(child: Text('lat:  - lon: ')),
              const SizedBox(height: 10.0,),
              OutlinedButton(
                  onPressed: () async {

                  },
                  child: const Text('Query Db')),
              Expanded(child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemCount:(results).length,
                  itemBuilder: (context, index) => Text('id: ${results[index]['id']} - lat: ${results[index]['lat']} - lon: ${results[index]['lon']}', style: const TextStyle(fontSize: 12.0),)
              )),
            ],
          ),
        ),
      )
    );
  }

  Future<Stream<LocationData>?> getLocation() async {

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    Location location = Location();
    Stream<LocationData>? _locationStream;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        print('Location service not enabled');
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        print('Location denied by user');
      }
    }

    _locationStream = location.onLocationChanged;

    return _locationStream;

  }

}
