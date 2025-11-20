import 'dart:async';
import 'package:flutter/material.dart';
import 'widgets/draggable_player_horizontal.dart';
import 'widgets/draggable_player_vertical.dart';
import 'widgets/infinite_scroll_map.dart'; 

class GamePage extends StatefulWidget {
  final String playerName;

  const GamePage({
    super.key,
    required this.playerName,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int _counter = 0;
  // late final SupabaseService _supabaseService; // Supabase Desactivado
  // bool _isSignedIn = false; // Supabase Desactivado
  bool _isVertical = true; // true = vertical, false = horizontal
  Timer? _gameTimer; // Timer para el bucle del juego
  
  final Duration _gameTickSpeed = const Duration(milliseconds: 100);
  // final Duration _saveTickSpeed = const Duration(seconds: 5); // Supabase Desactivado

  @override
  void initState() {
    super.initState();
    // _supabaseService = SupabaseService(); // Supabase Desactivado
    _initializeData();
  }

  void _toggleOrientation() {
    setState(() {
      _isVertical = !_isVertical;
    });
  }

  Future<void> _initializeData() async {
    // --- Supabase Desactivado ---
    // (Cuando se active, usar 'widget.playerName')
    // final points = await _supabaseService.retrievePoints(
    //     playerName: widget.playerName, 
    //   );
    
    _startGameLoop();
  }

  void _startGameLoop() {
    _gameTimer?.cancel(); 
    _gameTimer = Timer.periodic(_gameTickSpeed, (timer) {
      _incrementCounter();
    });
  }
  
  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  // --- Supabase Desactivado ---
  // (Cuando se active, usar 'widget.playerName')
  // void _saveScore() {
  //   _supabaseService.checkAndUpsertPlayer(
  //     playerName: widget.playerName,
  //     score: _counter,
  //   );
  // }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.playerName.toUpperCase()} Runner'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isVertical ? Icons.swap_horiz : Icons.swap_vert),
            tooltip: _isVertical ? 'Cambiar a horizontal' : 'Cambiar a vertical',
            onPressed: _toggleOrientation,
            padding: const EdgeInsets.only(top: 8.0, right: 16.0),
          ),
        ],
      ),
      body: Center(
        child: _isVertical ? _buildVerticalLayout() : _buildHorizontalLayout(),
      ),
    );
  }

  Widget _buildVerticalLayout() {
    return InfiniteScrollMap(
      imagePath: 'assets/maps/mapa_vertical.png',
      scrollDirection: Axis.vertical,
      duration: const Duration(seconds: 10),
      reverse: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Spacer(flex: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                const Text('Distancia:'),
                const SizedBox(height: 10),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
          Padding(
            padding: const EdgeInsets.only(bottom: 40.0),
            child: DraggablePlayerHorizontal(
              imagePathBase: 'assets/pokemon/${widget.playerName}/${widget.playerName}_bici_vertical',
              frameCount: 3,
              width: 80,
              height: 80,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    return InfiniteScrollMap(
      imagePath: 'assets/maps/mapa_horizontal.png',
      scrollDirection: Axis.horizontal,
      duration: const Duration(seconds: 10),
      reverse: false, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 40.0),
            child: DraggablePlayerVertical(
              imagePathBase: 'assets/pokemon/${widget.playerName}/${widget.playerName}_bici_lateral',
              frameCount: 3,
              width: 80,
              height: 80,
            ),
          ),
          const Spacer(flex: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Distancia:'),
                const SizedBox(height: 10),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}