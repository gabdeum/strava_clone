import 'dart:async';
import 'package:strava_add_on/services/file_utils.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  bool xmlData = false;
  XmlFiles newXmlFile = XmlFiles(xmlFileName: 'Paris_Marathon_route');

  @override
  void initState() {
    super.initState();
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
              OutlinedButton(
                  onPressed: () async {
                    await newXmlFile.getXmlContent(context);
                    xmlData = true;
                    setState(() {});
                  },
                  child: const Text('Read from file')),
              const SizedBox(height: 10.0,),
              Text(xmlData ? 'Has data' : 'No data yet')
            ],
          ),
        ),
      )
    );
  }

  getLocation() async {

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    Location location = Location();
    Stream<LocationData> _locationStream;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationStream = location.onLocationChanged;

    return _locationStream;

  }

}
