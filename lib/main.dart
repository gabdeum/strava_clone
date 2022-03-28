import 'package:flutter/material.dart';
import 'package:strava_add_on/pages/home.dart';

void main() => runApp(MaterialApp(
  routes: {
    '/': (context) => const Home()
  },
));