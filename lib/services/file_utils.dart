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
  
  insertDb(List<Map<String,Object?>> listData, Database db) async {

    Batch _batch = db.batch();
    listData.forEach((element) {
      _batch.insert(xmlFileName, element);
    });
    await _batch.commit();

    print('Insert done with ${listData.length} elements');

  }

  Future<List<Map<String, Object?>>> queryDb(Database db) async {

    List<Map<String, Object?>> result = await db.rawQuery('SELECT id, lat, lon, MIN(lat * lat + lon * lon) FROM $xmlFileName');
    print(result);

    return result;

  }

}