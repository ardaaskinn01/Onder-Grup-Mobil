import 'package:flutter/material.dart';
import 'package:onderliftmobil/pages/themeprovider.dart';
import 'package:provider/provider.dart';
import 'package:onderliftmobil/pages/languageprovider.dart';

class AyarlarScreen extends StatefulWidget {
  @override
  _AyarlarScreenState createState() => _AyarlarScreenState();
}

class _AyarlarScreenState extends State<AyarlarScreen> {
  void _changeLanguage(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            languageProvider.selectedLanguage == 'Türkçe'
                ? 'Dil Seçin'
                : 'Choose the Language',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Türkçe'),
                leading: Radio<String>(
                  value: 'Türkçe',
                  groupValue: context.watch<LanguageProvider>().selectedLanguage,
                  onChanged: (String? value) {
                    context.read<LanguageProvider>().changeLanguage(value!);
                    Navigator.of(context).pop();
                  },
                ),
              ),
              ListTile(
                title: Text('İngilizce'),
                leading: Radio<String>(
                  value: 'İngilizce',
                  groupValue: context.watch<LanguageProvider>().selectedLanguage,
                  onChanged: (String? value) {
                    context.read<LanguageProvider>().changeLanguage(value!);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                languageProvider.selectedLanguage == 'Türkçe'
                    ? 'İptal'
                    : 'Cancel',
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.selectedLanguage == 'Türkçe'
              ? 'Ayarlar'
              : 'Preferences',
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              languageProvider.selectedLanguage == 'Türkçe'
                  ? 'Gece Modu'
                  : 'Night Mode',
            ),
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ),
          ListTile(
            title: Text(
              languageProvider.selectedLanguage == 'Türkçe'
                  ? 'Dil Seçimi'
                  : 'Language',
            ),
            onTap: () => _changeLanguage(context),
          ),
        ],
      ),
    );
  }
}