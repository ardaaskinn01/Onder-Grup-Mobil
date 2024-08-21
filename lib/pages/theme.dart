import 'package:flutter/material.dart';

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue,
  scaffoldBackgroundColor: Colors.white,
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blue,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  // Diğer renkler ve stil tanımlamaları
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.blueGrey,
  scaffoldBackgroundColor: Colors.black,
  textTheme: TextTheme(
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.blueGrey,
    iconTheme: IconThemeData(color: Colors.white),
  ),
  // Diğer renkler ve stil tanımlamaları
);