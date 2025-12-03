import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/obstacle_model.dart';
import 'widgets/draggable_player_horizontal.dart';
import 'widgets/draggable_player_vertical.dart';
import 'widgets/infinite_scroll_map.dart';
import 'services/supabase_service.dart';
class GamePage extends StatefulWidget {
  final String playerName;
  final String selectedMap;
  final String username;

  const GamePage({
    super.key,
    required this.playerName,
    required this.selectedMap,
    required this.username,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final SupabaseService _supabaseService = SupabaseService();
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

  Future<void> _saveScoreLogic() async {
    // 1. Obtener puntaje actual (si existe)
    final currentScore = await _supabaseService.retrievePoints(playerName: widget.username);
    
    // 2. Si no tiene puntaje (null) O el nuevo (_counter) es mayor, guardamos
    if (currentScore == null || _counter > currentScore) {
       await _supabaseService.checkAndUpsertPlayer(
         playerName: widget.username, 
         score: _counter
       );
    }
  }

  Future<void> _triggerGameOver() async {
    setState(() {
      _isGameOver = true;
    });

    // Se muestra un indicador de carga mientras se guardan/cargan los datos del jugador
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int bestScore = 0;

    try {
      // Obtenemos el récord guardado en la nube
      final int? savedScore = await _supabaseService.retrievePoints(
        playerName: widget.username,
      );
      
      // Si no había nada guardado, asumimos 0
      bestScore = savedScore ?? 0;

      // Verificamos si se rompió el mejor récord
      if (_counter > bestScore) {
        bestScore = _counter; // El nuevo récord es el actual
        
        // Guardar el nuevo récord en Supabase
        await _supabaseService.checkAndUpsertPlayer(
          playerName: widget.username,
          score: _counter,
        );
      }
    } catch (e) {
      debugPrint("Error al conectar con BD: $e");
      // Si falla la conexión a internet, se muestra el score actual como mejor score
      if (_counter > bestScore) bestScore = _counter;
    }

    // Se cierra el indicador de carga (si el widget sigue vivo)
    if (mounted) {
      Navigator.pop(context); // Cierra el CircularProgressIndicator
      
      // Mostrar el diálogo final con los datos
      _showGameOverDialog(bestScore); 
    }
  }

  void _showGameOverDialog(int bestScore) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          "¡GAME OVER!",
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Puntaje Actual
            Text("Puntaje Actual", style: TextStyle(color: Colors.grey[600])),
            Text(
              "$_counter m",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            // Mejor Récord
            Text("🏆 Mejor Récord 🏆", style: TextStyle(color: Colors.orange[800])),
            Text(
              "$bestScore m",
              style: const TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold, 
                color: Colors.orange,
              ),
            ),
          ],
        ),
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
              Navigator.pop(context); // Cierra diálogo
              Navigator.pop(context); // Sale al menú
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