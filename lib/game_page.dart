import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/obstacle_model.dart';
import 'widgets/draggable_player_horizontal.dart';
import 'widgets/draggable_player_vertical.dart';
import 'widgets/infinite_scroll_map.dart';

class GamePage extends StatefulWidget {
  final String playerName;
  final String selectedMap;

  const GamePage({
    super.key,
    required this.playerName,
    required this.selectedMap,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  int _counter = 0;
  int _lives = 3;
  bool _isGameOver = false;
  bool _isInvincible = false;
  bool _isVertical = true;
  Timer? _gameTimer;
  final Duration _gameTickSpeed = const Duration(milliseconds: 50);
  double _gameSpeed = 8.0;
  final List<Obstacle> _obstacles = [];
  final Random _random = Random();
  double _playerPosition = 0.0;
  int _spawnTimer = 0;
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  final List<String> _obstacleSprites = [
    'assets/items/rock.png',
    'assets/items/bush.png',
    'assets/pokemon/geodude.png',
  ];

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.play(AssetSource('audio/music.mp3'));
    _musicPlayer.setVolume(0.5);

    _startGameLoop();
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(_gameTickSpeed, (timer) {
      if (_isGameOver) {
        timer.cancel();
        _musicPlayer.stop();
        return;
      }
      _incrementCounter();
      _updateObstacles();
      _checkCollisions();
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;      
      if (_counter % 500 == 0) _gameSpeed += 1.0;
    });
  }

  void _updateObstacles() {
    setState(() {
      for (var obstacle in _obstacles) {
        if (_isVertical) {
          obstacle.y += _gameSpeed;
        } else {
          obstacle.x -= _gameSpeed;
        }
      }

      _obstacles.removeWhere((obs) {
        if (_isVertical) return obs.y > 1000;
        return obs.x < -600;
      });

      _spawnTimer++;

      if (_spawnTimer > 30) {
        // 15% de probabilidad de llamar a la función de spawn de poción, para que la recuperación no sea tan común
        if (_random.nextInt(100) < 15) {
           _spawnPotion(); 
        } else {
           // Si no, spawn de obstaculos normal
           _spawnNewObstacle(); 
        }
        _spawnTimer = 0;
      }
     
    });
  }

  void _spawnNewObstacle() {
    final sprite = _obstacleSprites[_random.nextInt(_obstacleSprites.length)];
    final size = MediaQuery.of(context).size;

    if (_isVertical) {
      double randomX = (_random.nextDouble() * 300) - 150;
      _obstacles.add(Obstacle(
        id: DateTime.now().toString(),
        imagePath: sprite,
        x: randomX,
        y: -100,
      ));
    } else {
      double randomY = (_random.nextDouble() * 400) - 200;
      _obstacles.add(Obstacle(
        id: DateTime.now().toString(),
        imagePath: sprite,
        x: size.width + 100,
        y: randomY,
      ));
    }
  }

  void _collectPotion(Obstacle potion) {
    _sfxPlayer.play(AssetSource('audio/potion.wav'));
    setState(() {
      if (_lives < 3) { // Tope de 3 vidas
        _lives++;
      }
      _obstacles.remove(potion); // Importante: Borrarla al tocarla
    });
  }

  void _checkCollisions() {
    if (_isInvincible) return;

    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    Rect playerRect;
    if (_isVertical) {
      playerRect = Rect.fromCenter(
        center: Offset(centerX + _playerPosition, screenSize.height - 150),
        width: 40, height: 40,
      );
    } else {
      playerRect = Rect.fromCenter(
        center: Offset(80, centerY + _playerPosition),
        width: 40, height: 40,
      );
    }

    for (var obstacle in _obstacles) {
      Rect obstacleRect;
      if (_isVertical) {
        obstacleRect = Rect.fromCenter(
          center: Offset(centerX + obstacle.x, obstacle.y),
          width: obstacle.width * 0.7, height: obstacle.height * 0.7,
        );
      } else {
        obstacleRect = Rect.fromCenter(
          center: Offset(obstacle.x, centerY + obstacle.y),
          width: obstacle.width * 0.7, height: obstacle.height * 0.7,
        );
      }

      if (playerRect.overlaps(obstacleRect)) {
        // Si el archivo de imagen dice "potion", es curativa
        if (obstacle.imagePath.contains('potion')) {
          _collectPotion(obstacle);
        } else {
          // Si no, es daño normal
          _handleHit();
        }
        break; 
      }
    }
  }

  void _handleHit() {
    _sfxPlayer.play(AssetSource('audio/hit.wav'));

    setState(() {
      _lives--;
      
      if (_lives <= 0) {
        _triggerGameOver();
      } else {        
        _isInvincible = true;
        Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isInvincible = false;
            });
          }
        });
      }
    });
  }

  void _spawnPotion() {
    final size = MediaQuery.of(context).size;
    // Lógica para que aparezca en la posición correcta según la orientación
    if (_isVertical) {
      double randomX = (_random.nextDouble() * 300) - 150;
      _obstacles.add(Obstacle(
        id: DateTime.now().toString(),
        imagePath: 'assets/items/potion.png', 
        x: randomX,
        y: -100,
      ));
    } else {
      double randomY = (_random.nextDouble() * 400) - 200;
      _obstacles.add(Obstacle(
        id: DateTime.now().toString(),
        imagePath: 'assets/items/potion.png', // La poción curativa
        x: size.width + 100,
        y: randomY,
      ));
    }
  }

  void _triggerGameOver() {
    setState(() {
      _isGameOver = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("¡Game Over!"),
        content: Text("Distancia recorrida: $_counter m"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text("Reintentar"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Salir"),
          )
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _counter = 0;
      _lives = 3;
      _obstacles.clear();
      _isGameOver = false;
      _isInvincible = false;
      _gameSpeed = 8.0;
    });
    _musicPlayer.resume();
    _startGameLoop();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
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
            onPressed: () {
               setState(() {
                 _isVertical = !_isVertical;
                 _obstacles.clear();
                 _playerPosition = 0;
               });
            },
          ),
        ],
      ),
      body: Center(
        child: _isVertical ? _buildVerticalLayout() : _buildHorizontalLayout(),
      ),
    );
  }

  Widget _buildPlayerWidget() {    
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: _isInvincible ? 0.5 : 1.0,
      child: _isVertical 
        ? DraggablePlayerHorizontal(
            imagePathBase: 'assets/pokemon/${widget.playerName}/${widget.playerName}_bici_vertical',
            frameCount: 3, width: 80, height: 80,
            onPositionChanged: (val) => _playerPosition = val,
          )
        : DraggablePlayerVertical(
            imagePathBase: 'assets/pokemon/${widget.playerName}/${widget.playerName}_bici_lateral',
            frameCount: 3, width: 80, height: 80,
            onPositionChanged: (val) => _playerPosition = val,
          ),
    );
  }

  Widget _buildVerticalLayout() {
    final screenSize = MediaQuery.of(context).size;
    String mapImage;
  if (widget.selectedMap == 'Parque') { //Si el mapa seleccionado es Parque, usar la imagen correspondiente
    mapImage = 'assets/maps/mapa_parque_vertical.png';
  } else { //Si no, usar la imagen de Ciudad
    mapImage = 'assets/maps/mapa_city_vertical.png'; 
  }
    return InfiniteScrollMap(
      imagePath: mapImage,
      scrollDirection: Axis.vertical,
      duration: const Duration(seconds: 10),
      reverse: true,
      child: Stack(
        children: [
          ..._obstacles.map((obstacle) => Positioned(
              left: (screenSize.width / 2) + obstacle.x - (obstacle.width / 2),
              top: obstacle.y - (obstacle.height / 2),
              child: Image.asset(obstacle.imagePath, width: obstacle.width, height: obstacle.height, fit: BoxFit.contain),
          )),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: _buildPlayerWidget(),
            ),
          ),
          _buildHUD(),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    final screenSize = MediaQuery.of(context).size;
    String mapImage;
  if (widget.selectedMap == 'Parque') { //Si el mapa seleccionado es Parque, usar la imagen correspondiente
    mapImage = 'assets/maps/mapa_parque_horizontal.png';
  } else { //Si no, usar la imagen de Ciudad
    mapImage = 'assets/maps/mapa_city_horizontal.png';
  }
    return InfiniteScrollMap(
      imagePath: mapImage,
      scrollDirection: Axis.horizontal,
      duration: const Duration(seconds: 10),
      reverse: false,
      child: Stack(
        children: [
          ..._obstacles.map((obstacle) => Positioned(
              left: obstacle.x - (obstacle.width / 2),
              top: (screenSize.height / 2) + obstacle.y - (obstacle.height / 2),
              child: Image.asset(obstacle.imagePath, width: obstacle.width, height: obstacle.height, fit: BoxFit.contain),
          )),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: _buildPlayerWidget(),
            ),
          ),
          _buildHUD(),
        ],
      ),
    );
  }


//Vidas del jugador 
Widget _buildHUD() {
    return Positioned(
      top: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8)),
            child: Text('Distancia: $_counter m',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (index) {
              // Calculamos si esta vida está activa
              bool isLifeActive = index < _lives;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0), //Espacio entre pokebolas
                child: Opacity(
                  // Si la vida está activa, opacidad 1.0 (full color)
                  // Si la vida se perdió, opacidad 0.4 (semi-transparente)
                  opacity: isLifeActive ? 1.0 : 0.4, 
                  child: Image.asset(
                    'assets/items/pokeball.png',
                    width: 30, 
                    height: 30,
                  ),
                ),
              );
            }),
          )
        ],
      ),
    );
}
}