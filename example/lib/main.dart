import 'package:example/blend_page.dart';
import 'package:example/draw_page.dart';
import 'package:example/scale_page.dart';
import 'package:flutter/material.dart';

import 'more_page.dart';
import 'rotate_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BufferImage Demo',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const MyHomePage(title: 'BufferImage Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late List<Widget> _childs;

  @override
  void initState() {
    super.initState();
    _childs = [
      const ScalePage(),
      const RotatePage(),
      const BlendPage(),
      const DrawPage(),
      const MorePage()
    ];
    _pageController = PageController(initialPage: 0);
    _pageController.addListener(_onPageChange);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _pageController.animateToPage(
        _selectedIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _onPageChange() {
    if (_pageController.page != null &&
        _pageController.page!.toInt() != _selectedIndex) {
      setState(() {
        _selectedIndex = _pageController.page!.toInt();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: _childs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: const Color.fromARGB(120, 0, 0, 0),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.aspect_ratio), label: 'Scale'),
          BottomNavigationBarItem(
              icon: Icon(Icons.screen_rotation), label: 'Rotate'),
          BottomNavigationBarItem(icon: Icon(Icons.layers), label: 'Blend'),
          BottomNavigationBarItem(icon: Icon(Icons.collections), label: 'Draw'),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
