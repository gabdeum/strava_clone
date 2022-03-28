import 'package:flutter/cupertino.dart';
import 'package:xml/xml.dart';
import 'package:sqflite/sqflite.dart';

class XmlFiles {

  String xmlFileName;

  XmlFiles({required this.xmlFileName});

  Future<List<Map>> getXmlContent(BuildContext context) async {

    final String _xmlString = await DefaultAssetBundle.of(context).loadString("assets/$xmlFileName.xml");
    final XmlDocument _document = XmlDocument.parse(_xmlString);
    final Iterable<XmlElement> _courses = _document.findAllElements("Trackpoint");

    List<Map> _listData = _courses.map((e) => {
      "lat" : e.findAllElements("LatitudeDegrees").first.children.first,
      "lon" : e.findAllElements("LongitudeDegrees").first.children.first,
      "alt" : e.findElements("AltitudeMeters").first.children.first,
      "dist" : e.findElements("DistanceMeters").first.children.first,
    }
    ).toList();

    return _listData;

  }

  

}