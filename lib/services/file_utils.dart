import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:xml/xml.dart';
import 'package:sqflite/sqflite.dart';

class XmlFiles {

  String xmlFileName;

  XmlFiles({required this.xmlFileName});

  Future<List<Map<String,Object?>>> getXmlContent(BuildContext context) async {

    final String _xmlString = await DefaultAssetBundle.of(context).loadString("assets/$xmlFileName.xml");
    final XmlDocument _document = XmlDocument.parse(_xmlString);
    final Iterable<XmlElement> _courses = _document.findAllElements("Trackpoint");

    List<Map<String,Object?>> _listData = _courses.map((e) => {
      "lat" : num.tryParse(e.findAllElements("LatitudeDegrees").first.children.first.toString()),
      "lon" : num.tryParse(e.findAllElements("LongitudeDegrees").first.children.first.toString()),
      "alt" : num.tryParse(e.findElements("AltitudeMeters").first.children.first.toString()),
      "dist" : num.tryParse(e.findElements("DistanceMeters").first.children.first.toString()),
    }
    ).toList();

    print('XML data fetched');

    return _listData;

  }

  Future<Database> createDb() async {
    String _databasesPath = await getDatabasesPath();
    String _path = '$_databasesPath/courses.db';

    await deleteDatabase(_path);
    Database _database = await openDatabase(_path, version: 1,
        onCreate: (Database db, int version) async {
          // When creating the db, create the table
          await db.execute(
              'CREATE TABLE $xmlFileName (id INTEGER PRIMARY KEY, lat REAL, lon REAL, alt REAL, dist REAL)');
        });

    print('Db created');
    
    return _database;
    
  }
  
  insertDb(List<Map<String,Object?>> listData, Database? db) async {

    if(db != null){
      Batch _batch = db.batch();
      listData.forEach((element) {
        _batch.insert(xmlFileName, element);
      });
      await _batch.commit();

      print('Insert done with ${listData.length} elements');
    }
    else{print('Insert failed: Database null');}

  }

  Future<List<Map<String, Object?>>> queryDb(Database? db, double? lat, double? lon) async {

    Map getOrthoProj(double xA, double yA, double xB, double yB, double x, double y){

      final double xV = xB-xA;
      final double yV = yB-yA;
      final xVyV = sqrt(pow(xV, 2) + pow(yV, 2));

      final double lambda = ((x-xA)*xV + (y-yA)*yV) / xVyV;

      final double xH = xA + lambda * xV / xVyV;
      final double yH = yA + lambda * yV / xVyV;

      return {
        "lat" : xH,
        "lon" : yH
      };

    }

    List<Map<String, Object?>> result = [];
    Map newPoint = {};

    if(db != null){

      Map<String, Object?> _pointO = (await db.rawQuery('SELECT id, lat, lon, alt, dist, MIN((${lat ?? 0.0} - lat)*(${lat ?? 0.0} - lat) + (${lon ?? 0.0} - lon)*(${lon ?? 0.0} - lon)) as min FROM $xmlFileName'))[0];
      Map<String, Object?> _pointA = (await db.query(xmlFileName, where: 'id = ${(_pointO['id'] as num)-1}'))[0];
      Map<String, Object?> _pointB = (await db.query(xmlFileName, where: 'id = ${(_pointO['id'] as num)+1}'))[0];
      result.addAll([_pointA, _pointO, _pointB]);

      double xA = result[0]['lat'] as double;
      double yA = result[0]['lon'] as double;
      double xO = result[1]['lat'] as double;
      double yO = result[1]['lon'] as double;
      double xB = result[2]['lat'] as double;
      double yB = result[2]['lon'] as double;
      double x = lat ?? result[0]['lat'] as double;
      double y = lon ?? result[0]['lon'] as double;

      print('initialPoint: $x,$y');

      double theta1 = acos(((xA-xO)*(x-xO)+(yA-yO)*(y-yO))
          /(sqrt(pow((yA-yO), 2)+pow((xA-xO), 2))*sqrt(pow((y-yO), 2)+pow((x-xO), 2))));
      double theta2 = acos(((xB-xO)*(x-xO)+(yB-yO)*(y-yO))
          /(sqrt(pow((yB-yO), 2)+pow((xB-xO), 2))*sqrt(pow((y-yO), 2)+pow((x-xO), 2))));

      if(theta1 < pi/2 && theta2 > pi/2){
        newPoint = getOrthoProj(xO, yO, xA, yA, x, y);
      }
      else if(theta1 > pi/2 && theta2 < pi/2) {
        newPoint = getOrthoProj(xO, yO, xB, yB, x, y);
      }
      else {
        newPoint = {
          "lat" : xO,
          "lon" : yO,
          "alt" : result[1]['alt'],
          "dist" : result[1]['dist'],
        };
      }

    }
    else{print('Query failed: Database null');}

    print('resultPoints: $result');

    print('newPoint: ${newPoint['lat']},${newPoint['lon']}');

    return result;

  }

}