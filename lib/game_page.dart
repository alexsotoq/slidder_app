import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NECESARIO para detectar teclas
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
  
  // --- VARIABLES DE ESTADO ---
  bool _showTutorial = true; // NUEVO: Controla si se muestra el mensaje de inicio
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
  
  // Audio
  final AudioPlayer _musicPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  
  final List<String> _obstacleSprites = [
    'assets/items/rock.png',
    'assets/items/bush.png',
    'assets/pokemon/geodude.png',
  ];

  // --- CONTROLES DE TECLADO ---
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  // Llaves globales para controlar a los jugadores
  final GlobalKey<DraggablePlayerVerticalState> _verticalKey = GlobalKey();
  final GlobalKey<DraggablePlayerHorizontalState> _horizontalKey = GlobalKey();


  // CONFIGURACIÓN DE LÍMITES POR MAPA
  Map<String, double> get mapConfig {
    if (widget.selectedMap == 'Parque') {
      return {
        'player_min_x': -200.0, 
        'player_max_x': 150.0, 
        'player_min_y': -130.0,  
        'player_max_y': 40.0,    
        'spawn_x_range': 100.0,
        'spawn_y_range': 45.0,
      };
    } else { // MAPA CIUDAD
      return {
        'player_min_x': -250.0,
        'player_max_x': 150.0,
        'player_min_y': -120.0, 
        'player_max_y': 80.0,   
        'spawn_x_range': 140.0,
        'spawn_y_range': 100.0,
      };
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await _musicPlayer.setReleaseMode(ReleaseMode.loop);
    await _musicPlayer.play(AssetSource('audio/music.mp3'));
    _musicPlayer.setVolume(0.5);
    
    // NOTA: Ya no iniciamos el loop aquí automáticamente.
    // Esperamos a que el usuario quite el tutorial.
  }

  // --- NUEVO: Función para ocultar tutorial e iniciar el juego ---
  void _dismissTutorialAndStart() {
    if (_showTutorial) {
      setState(() {
        _showTutorial = false;
      });
      // Iniciamos el motor del juego
      _startGameLoop();
    }
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(_gameTickSpeed, (timer) {
      if (_isGameOver) {
        timer.cancel();
        _musicPlayer.stop();
        return;
      }
      
      // Si el tutorial sigue activo (por seguridad), no avanzamos
      if (_showTutorial) return;

      _incrementCounter();
      _updateObstacles();
      _checkCollisions();
      _handleKeyboardMovement();
    });
  }

  void _handleKeyboardMovement() {
    const double keyboardSpeed = 15.0; 

    if (_isVertical) {
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || 
          _pressedKeys.contains(LogicalKeyboardKey.keyA)) {
        _horizontalKey.currentState?.movePlayer(-keyboardSpeed);
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) || 
          _pressedKeys.contains(LogicalKeyboardKey.keyD)) {
        _horizontalKey.currentState?.movePlayer(keyboardSpeed);
      }
    } else {
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp) || 
          _pressedKeys.contains(LogicalKeyboardKey.keyW)) {
        _verticalKey.currentState?.movePlayer(-keyboardSpeed); 
      }
      if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown) || 
          _pressedKeys.contains(LogicalKeyboardKey.keyS)) {
        _verticalKey.currentState?.movePlayer(keyboardSpeed);
      }
    }
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
        if (_random.nextInt(100) < 15) {
          _spawnPotion();
        } else {
          _spawnNewObstacle();
        }
        _spawnTimer = 0;
      }
    });
  }

  void _spawnNewObstacle() {
    final sprite = _obstacleSprites[_random.nextInt(_obstacleSprites.length)];
    final size = MediaQuery.of(context).size;
    final config = mapConfig;

    if (_isVertical) {
      double range = config['spawn_x_range']!;
      double randomX = (_random.nextDouble() * (range * 2)) - range;

      _obstacles.add(
        Obstacle(
          id: DateTime.now().toString(),
          imagePath: sprite,
          x: randomX,
          y: -100,
        ),
      );
    } else {
      double range = config['spawn_y_range']!;
      double randomY = (_random.nextDouble() * (range * 2)) - range;

      _obstacles.add(
        Obstacle(
          id: DateTime.now().toString(),
          imagePath: sprite,
          x: size.width + 100,
          y: randomY,
        ),
      );
    }
  }

  void _spawnPotion() {
    final size = MediaQuery.of(context).size;
    final config = mapConfig;

    if (_isVertical) {
      double range = config['spawn_x_range']!;
      double randomX = (_random.nextDouble() * (range * 2)) - range;
      
      _obstacles.add(
        Obstacle(
          id: DateTime.now().toString(),
          imagePath: 'assets/items/potion.png',
          x: randomX,
          y: -100,
        ),
      );
    } else {
      double range = config['spawn_y_range']!;
      double randomY = (_random.nextDouble() * (range * 2)) - range;
      
      _obstacles.add(
        Obstacle(
          id: DateTime.now().toString(),
          imagePath: 'assets/items/potion.png',
          x: size.width + 100,
          y: randomY,
        ),
      );
    }
  }

  void _collectPotion(Obstacle potion) {
    _sfxPlayer.play(AssetSource('audio/potion.wav'));
    setState(() {
      if (_lives < 3) {
        _lives++;
      }
      _obstacles.remove(potion);
    });
  }

  void _checkCollisions() {
    if (_isInvincible) return;

    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    Rect playerRect;
    if (_isVertical) {
      // Hitbox optimizado para llantas
      playerRect = Rect.fromCenter(
        center: Offset(centerX + _playerPosition, (screenSize.height - 150) + 20),
        width: 16, 
        height: 16, 
      );
    } else {
      playerRect = Rect.fromCenter(
        center: Offset(80, centerY + _playerPosition),
        width: 30,
        height: 20, 
      );
    }

    for (var obstacle in _obstacles) {
      Rect obstacleRect;
      double hitBoxScale = 0.5; 

      if (_isVertical) {
        obstacleRect = Rect.fromCenter(
          center: Offset(centerX + obstacle.x, obstacle.y),
          width: obstacle.width * hitBoxScale,
          height: obstacle.height * hitBoxScale,
        );
      } else {
        obstacleRect = Rect.fromCenter(
          center: Offset(obstacle.x, centerY + obstacle.y),
          width: obstacle.width * hitBoxScale,
          height: obstacle.height * hitBoxScale,
        );
      }

      if (playerRect.overlaps(obstacleRect)) {
        if (obstacle.imagePath.contains('potion')) {
          _collectPotion(obstacle);
        } else {
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

  Future<void> _triggerGameOver() async {
    setState(() {
      _isGameOver = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    int bestScore = 0;

    try {
      final int? savedScore = await _supabaseService.retrievePoints(
        playerName: widget.username,
      );

      bestScore = savedScore ?? 0;

      if (_counter > bestScore) {
        bestScore = _counter;

        await _supabaseService.checkAndUpsertPlayer(
          playerName: widget.username,
          score: _counter,
        );
      }
    } catch (e) {
      debugPrint("Error al conectar con BD: $e");
      if (_counter > bestScore) bestScore = _counter;
    }

    if (mounted) {
      Navigator.pop(context);
      _showGameOverDialog(bestScore);
    }
  }

  void _showGameOverDialog(int bestScore) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent, // Hacemos transparente el fondo del Dialog nativo
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1), // El color crema de tu menú
            border: Border.all(color: const Color(0xFFD38B5D), width: 4), // Borde grueso naranja oscuro
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "¡GAME OVER!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PressStart2P', // Fuente pixelada
                  fontSize: 18,
                  color: Colors.red,
                  shadows: [
                    Shadow(color: Colors.black26, offset: Offset(2, 2)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              Text("Puntaje Actual", 
                style: TextStyle(
                  fontFamily: 'PressStart2P', 
                  fontSize: 10, 
                  color: Colors.grey[700]
                )
              ),
              const SizedBox(height: 8),
              Text(
                "$_counter m",
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 20, 
                  color: Colors.black
                ),
              ),
              
              const SizedBox(height: 20),
              Container(
                height: 2, 
                width: 100, 
                color: const Color(0xFFD38B5D).withOpacity(0.5)
              ), // Separador
              const SizedBox(height: 20),

              const Text(
                "MEJOR RECORD",
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 10,
                  color: Color(0xFFE65100), // Naranja fuerte
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.orange, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    "$bestScore m",
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 20,
                      color: Colors.orange,
                      shadows: [
                        Shadow(color: Colors.black26, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.emoji_events, color: Colors.orange, size: 24),
                ],
              ),
              
              const SizedBox(height: 30),

              // Botones de Acción
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón Salir (Texto simple)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: Text(
                      "SALIR",
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        color: Colors.red[400],
                        fontSize: 10,
                      ),
                    ),
                  ),
                  // Botón Reintentar (Estilo Botón Pixel)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetGame();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81C784), // Verde Gameboy
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                        side: const BorderSide(color: Color(0xFF388E3C), width: 2)
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    child: const Text(
                      "REINTENTAR",
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
      _playerPosition = 0.0;
      _showTutorial = true; // Volvemos a mostrar el tutorial al reiniciar
    });
    _musicPlayer.resume();
    // No iniciamos loop aquí, esperamos al tutorial de nuevo
    _focusNode.requestFocus(); 
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _musicPlayer.dispose();
    _sfxPlayer.dispose();
    _focusNode.dispose(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true, 
      onKey: (event) {
        // Lógica para detectar teclas
        if (event is RawKeyDownEvent) {
          // Si el tutorial está activo y presionan una tecla, iniciamos
          if (_showTutorial) {
            _dismissTutorialAndStart();
          }
          setState(() {
            _pressedKeys.add(event.logicalKey);
          });
        } else if (event is RawKeyUpEvent) {
          setState(() {
            _pressedKeys.remove(event.logicalKey);
          });
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 1. CAPA DEL JUEGO (FONDO Y JUGADOR)
            Center(
              child: _isVertical
                  ? _buildVerticalLayout()
                  : _buildHorizontalLayout(),
            ),

            // 2. CAPA DE TUTORIAL (OVERLAY)
            // Se muestra solo si _showTutorial es true
            if (_showTutorial)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _dismissTutorialAndStart, // Clic/Tap inicia el juego
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    color: Colors.black.withOpacity(0.7),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "¡EMPIEZA A JUGAR!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'PressStart2P',
                              color: Color(0xFFFDD835),
                              fontSize: 18,
                              shadows: [
                                Shadow(color: Colors.black, offset: Offset(2, 2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildTutorialOption(
                                icon: Icons.mouse,
                                label: "Arrastra",
                              ),
                              const SizedBox(width: 30),
                              const Text("O", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                              const SizedBox(width: 30),
                              _buildTutorialOption(
                                icon: Icons.keyboard,
                                label: "Presiona una tecla",
                              ),
                            ],
                          ),
                          const SizedBox(height: 50),
                          // Animación simple de texto
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(seconds: 1),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: child,
                              );
                            },
                            child: const Text(
                              "- Toca o presiona una tecla para iniciar -",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // 3. CAPA DE UI (HUD y BOTONES)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón Volver
                      _BackButton(onPressed: () => Navigator.pop(context)),

                      // HUD de distancia y vidas (Solo visible si NO estamos en tutorial para que se vea limpio, o lo dejamos visible)
                      // Lo dejaremos visible para que se vea "listo"
                      _buildHUD(),

                      // Botón Cambiar Orientación (Deshabilitado visualmente si hay tutorial? No, dejémoslo funcional)
                      _OrientationButton(
                        isVertical: _isVertical,
                        onPressed: () {
                          // Si cambian orientación, reseteamos todo, incluyendo mostrar tutorial
                          setState(() {
                            _isVertical = !_isVertical;
                            _obstacles.clear();
                            _playerPosition = 0;
                            _showTutorial = true; 
                            _gameTimer?.cancel(); // Pausar si estaba corriendo
                            _focusNode.requestFocus(); 
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para los íconos del tutorial
  Widget _buildTutorialOption({required IconData icon, required String label}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerWidget() {
    final config = mapConfig;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: _isInvincible ? 0.5 : 1.0,
      child: _isVertical
          ? DraggablePlayerHorizontal(
              key: _horizontalKey,
              imagePathBase:
                  'assets/pokemon/${widget.playerName}/${widget.playerName}_bici_vertical',
              frameCount: 3,
              width: 80,
              height: 80,
              onPositionChanged: (val) => _playerPosition = val,
              minX: config['player_min_x']!,
              maxX: config['player_max_x']!,
            )
          : DraggablePlayerVertical(
              key: _verticalKey,
              imagePathBase:
                  'assets/pokemon/${widget.playerName}/${widget.playerName}_bici_lateral',
              frameCount: 3,
              width: 80,
              height: 80,
              onPositionChanged: (val) => _playerPosition = val,
              minY: config['player_min_y']!,
              maxY: config['player_max_y']!,
            ),
    );
  }

  Widget _buildVerticalLayout() {
    final screenSize = MediaQuery.of(context).size;
    String mapImage;
    if (widget.selectedMap == 'Parque') {
      mapImage = 'assets/maps/mapa_parque_vertical.png';
    } else {
      mapImage = 'assets/maps/mapa_city_vertical.png';
    }
    // NOTA: Podrías querer que el mapa NO se mueva si está en tutorial.
    // Para eso, pasa duration: Duration.zero o similar, pero InfiniteScrollMap
    // usa un controlador interno. Por ahora lo dejamos moviéndose como "fondo animado"
    // mientras esperas, queda bonito.
    return InfiniteScrollMap(
      imagePath: mapImage,
      scrollDirection: Axis.vertical,
      duration: const Duration(seconds: 10),
      reverse: true,
      child: Stack(
        children: [
          ..._obstacles.map(
            (obstacle) => Positioned(
              left: (screenSize.width / 2) + obstacle.x - (obstacle.width / 2),
              top: obstacle.y - (obstacle.height / 2),
              child: Image.asset(
                obstacle.imagePath,
                width: obstacle.width,
                height: obstacle.height,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: _buildPlayerWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalLayout() {
    final screenSize = MediaQuery.of(context).size;
    String mapImage;
    if (widget.selectedMap == 'Parque') {
      mapImage = 'assets/maps/mapa_parque_horizontal.png';
    } else {
      mapImage = 'assets/maps/mapa_city_horizontal.png';
    }
    return InfiniteScrollMap(
      imagePath: mapImage,
      scrollDirection: Axis.horizontal,
      duration: const Duration(seconds: 10),
      reverse: false,
      child: Stack(
        children: [
          ..._obstacles.map(
            (obstacle) => Positioned(
              left: obstacle.x - (obstacle.width / 2),
              top: (screenSize.height / 2) + obstacle.y - (obstacle.height / 2),
              child: Image.asset(
                obstacle.imagePath,
                width: obstacle.width,
                height: obstacle.height,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: _buildPlayerWidget(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHUD() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          border: Border.all(color: const Color(0xFFFDD835), width: 3),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_counter M',
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 14,
                color: Color(0xFFFDD835),
                height: 1,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              width: 2,
              height: 24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                bool isLifeActive = index < _lives;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: Opacity(
                    opacity: isLifeActive ? 1.0 : 0.25,
                    child: Image.asset(
                      'assets/items/pokeball.png',
                      width: 22,
                      height: 22,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// Botón Volver estilizado
class _BackButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _BackButton({required this.onPressed});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isHovered && !_isPressed ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: EdgeInsets.only(
              top: _isPressed ? 3 : 0,
              left: _isPressed ? 3 : 0,
            ),
            decoration: BoxDecoration(
              color: _isHovered && !_isPressed
                  ? Color.lerp(const Color(0xFF64B5F6), Colors.white, 0.15)
                  : const Color(0xFF64B5F6),
              border: Border.all(color: const Color(0xFF2286C3), width: 3),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                  left: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
              child: Text(
                "< VOLVER",
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 9,
                  color: Colors.white,
                  height: 1,
                  shadows: [
                    Shadow(color: Colors.black45, offset: Offset(1, 1)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Botón de orientación estilizado
class _OrientationButton extends StatefulWidget {
  final bool isVertical;
  final VoidCallback onPressed;
  const _OrientationButton({required this.isVertical, required this.onPressed});

  @override
  State<_OrientationButton> createState() => _OrientationButtonState();
}

class _OrientationButtonState extends State<_OrientationButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onPressed();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isHovered && !_isPressed ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: EdgeInsets.only(
              top: _isPressed ? 3 : 0,
              left: _isPressed ? 3 : 0,
            ),
            decoration: BoxDecoration(
              color: _isHovered && !_isPressed
                  ? Color.lerp(const Color(0xFFE8A87C), Colors.white, 0.15)
                  : const Color(0xFFE8A87C),
              border: Border.all(color: const Color(0xFFD38B5D), width: 3),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                  left: BorderSide(
                    color: Colors.white.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isVertical ? Icons.swap_horiz : Icons.swap_vert,
                    color: Colors.white,
                    size: 16,
                    shadows: const [
                      Shadow(color: Colors.black45, offset: Offset(1, 1)),
                    ],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "GIRAR",
                    style: const TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 8,
                      color: Colors.white,
                      height: 1,
                      shadows: [
                        Shadow(color: Colors.black45, offset: Offset(1, 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}