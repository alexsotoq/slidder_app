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
import 'widgets/animated_obstacle.dart';

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
  double _mapScrollPosition = 0.0;
  
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
    if (widget.selectedMap == 'Ruta 17') {
      // RUTA 17
      return {
        // Vertical
        'player_min_x': -130.0,
        'player_max_x': 130.0,
        
        // Horizontal
        'player_min_y': -160.0,
        'player_max_y': 160.0,  
        
        'spawn_x_range': 110.0,
        'spawn_y_range': 150.0, 
      };
    } else if (widget.selectedMap == 'Ruta 21') {
      // RUTA 21
      return {
        // Vertical
        'player_min_x': -140.0,
        'player_max_x': 140.0,
        
        // Horizontal
        'player_min_y': -160.0, 
        'player_max_y': 160.0,

        'spawn_x_range': 120.0,
        'spawn_y_range': 150.0,
      };
    } else { 
      // CIUDAD (Default)
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
  }

  void _dismissTutorialAndStart() {
    if (_showTutorial) {
      setState(() {
        _showTutorial = false;
      });
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
      setState(() { // Asegúrate de que esto esté dentro del setState o lo llame
        _incrementCounter();
        _updateObstacles();
        _checkCollisions();
        _handleKeyboardMovement();
        
        // NUEVA LÍNEA: Movemos el mapa a la misma velocidad que los obstáculos
        _mapScrollPosition += _gameSpeed; 
      });
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

      if (_spawnTimer > 18) {
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
    final size = MediaQuery.of(context).size;
    final config = mapConfig; // Obtiene los límites actuales
    
    // LÓGICA DE SPAWN SEGÚN EL MAPA
    if (widget.selectedMap == 'Ruta 17') {
      _spawnBiker(); // Función especial para la ruta de bicis
    } else if (widget.selectedMap == 'Ruta 21') {
      _spawnSwimmer();
    } else {
      // Lógica estándar para otros mapas (Parque/Ciudad)
      _spawnStandardObstacle(size, config);
    }
  }

  // Spawn específico para Bikers en Ruta 17
  void _spawnBiker() {
    final config = mapConfig;
    
    // Configuración para Vertical
    if (_isVertical) {
      double range = config['spawn_x_range']!;
      double randomX = (_random.nextDouble() * (range * 2)) - range;

      _obstacles.add(
        Obstacle(
          id: DateTime.now().toString(),
          imagePath: 'assets/enemies/biker/biker_vertical', 
          x: randomX,
          y: -150,
          width: 70,
          height: 90,
          isAnimated: true,
          frameCount: 4,
          animationSpeed: 120,
        ),
      );
    } else {
      final size = MediaQuery.of(context).size;
      double range = config['spawn_y_range']!;
      double randomY = (_random.nextDouble() * (range * 2)) - range;

      _obstacles.add(
        Obstacle(
          id: DateTime.now().toString(),
          imagePath: 'assets/enemies/biker/biker_horizontal', 
          x: size.width + 100,
          y: randomY, 
          width: 90,
          height: 70,
          isAnimated: true,
          frameCount: 3,
          animationSpeed: 120,
        ),
      );
    }
  }

  void _spawnSwimmer() {
    final config = mapConfig;
    
    // Aleatoriamente elige 'swimmer1' o 'swimmer2'
    // nextBool() devuelve true o false (50% probabilidad)
    String swimmerType = _random.nextBool() ? 'swimmer1' : 'swimmer2';

    // --- LÓGICA VERTICAL ---
    if (_isVertical) {
      double range = config['spawn_x_range']!;
      double randomX = (_random.nextDouble() * (range * 2)) - range;

      _obstacles.add(
        Obstacle(
          id: DateTime.now().toString(),
          // Usamos la variable swimmerType para construir la ruta
          imagePath: 'assets/enemies/swimmers/${swimmerType}_vertical', 
          x: randomX,
          y: -150,
          width: 60,
          height: 60,
          isAnimated: true,
          frameCount: 4, 
          animationSpeed: 180,
        ),
      );
    } 
    // --- LÓGICA HORIZONTAL ---
    else {
      final size = MediaQuery.of(context).size;
      double range = config['spawn_y_range']!;
      double randomY = (_random.nextDouble() * (range * 2)) - range;

      _obstacles.add(
        Obstacle(
          id: DateTime.now().toString(),
          imagePath: 'assets/enemies/swimmers/${swimmerType}_horizontal', 
          x: size.width + 100,
          y: randomY,
          width: 70, 
          height: 50,
          isAnimated: true,
          frameCount: 3, 
          animationSpeed: 180,
        ),
      );
    }
  }

  // La lógica vieja que tenías, movida aquí para ordenar
  void _spawnStandardObstacle(Size size, Map<String, double> config) {
    final sprite = _obstacleSprites[_random.nextInt(_obstacleSprites.length)];
    if (_isVertical) {
      double range = config['spawn_x_range']!;
      double randomX = (_random.nextDouble() * (range * 2)) - range;
      _obstacles.add(Obstacle(id: DateTime.now().toString(), imagePath: sprite, x: randomX, y: -100));
    } else {
      double range = config['spawn_y_range']!;
      double randomY = (_random.nextDouble() * (range * 2)) - range;
      _obstacles.add(Obstacle(id: DateTime.now().toString(), imagePath: sprite, x: size.width + 100, y: randomY));
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
   
    double pWidth;
    double pHeight;

    if (widget.selectedMap == 'Ruta 21') {
       if (_isVertical) { pWidth = 60; pHeight = 60; }
       else { pWidth = 70; pHeight = 50; }
    } else {
       pWidth = 70; pHeight = 90;
    }

    Rect playerRect;

    if (_isVertical) {
      double playerVisualY = screenSize.height - 40 - (pHeight / 2);
      playerRect = Rect.fromCenter(
        center: Offset(centerX + _playerPosition, playerVisualY),
        width: pWidth * 0.6,
        height: pHeight * 0.6,
      );
    } else {
      double playerVisualX = 40 + (pWidth / 2);
      playerRect = Rect.fromCenter(
        center: Offset(playerVisualX, centerY + _playerPosition),
        width: pWidth * 0.6,
        height: pHeight * 0.6,
      );
    }

    for (var obstacle in _obstacles) {
      Rect obstacleRect;
      double hitBoxScale = 0.7;

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
      _mapScrollPosition = 0.0;
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
    String characterName = widget.playerName;

    if (characterName == 'green') characterName = 'leaf';

    String baseFolder;
    String action;
    String suffix = _isVertical ? "vertical" : ""; 
    int currentFrameCount = 3;
    double pWidth;
    double pHeight;

    if (widget.selectedMap == 'Ruta 21') {
      // Modo surf (agua)
      baseFolder = '${characterName}swim';
      action = 'swim';
      currentFrameCount = 2;
      if (!_isVertical) suffix = "horizontal";

      if (_isVertical) {
        pWidth = 60; 
        pHeight = 60;
      } else {
        pWidth = 70;
        pHeight = 50; 
      }

    } else {
      // Modo bici
      baseFolder = characterName;
      action = 'bici';
      currentFrameCount = 3;
      if (!_isVertical) suffix = "lateral";
      
      // Tamaños estándar Bici
      pWidth = 70;
      pHeight = 90;
    }

    final String imagePathBase = 
        'assets/pokemon/$baseFolder/${characterName}_${action}_$suffix';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      opacity: _isInvincible ? 0.5 : 1.0,
      child: _isVertical
          ? DraggablePlayerHorizontal(
              key: _horizontalKey,
              imagePathBase: imagePathBase,
              frameCount: currentFrameCount,
              width: pWidth,
              height: pHeight,
              onPositionChanged: (val) => _playerPosition = val,
              minX: config['player_min_x']!,
              maxX: config['player_max_x']!,
            )
          : DraggablePlayerVertical(
              key: _verticalKey,
              imagePathBase: imagePathBase,
              frameCount: currentFrameCount,
              width: pWidth,
              height: pHeight,
              onPositionChanged: (val) => _playerPosition = val,
              minY: config['player_min_y']!,
              maxY: config['player_max_y']!,
            ),
    );
  }

  Widget _buildVerticalLayout() {
    final screenSize = MediaQuery.of(context).size;

    String mapImage;
    if (widget.selectedMap == 'Ruta 17') {       
       mapImage = 'assets/maps/mapa_ruta17_vertical.png'; 
    } else if (widget.selectedMap == 'Ruta 21') {
       mapImage = 'assets/maps/mapa_ruta21_vertical.png';
    } else {
       mapImage = 'assets/maps/mapa_city_vertical.png'; 
    }

    return InfiniteScrollMap(
      imagePath: mapImage,
      scrollDirection: Axis.vertical,
      scrollOffset: _mapScrollPosition,
      reverse: false,
      child: Stack(
        children: [
          ..._obstacles.map(
            (obstacle) => Positioned(
              left: (screenSize.width / 2) + obstacle.x - (obstacle.width / 2),
              top: obstacle.y - (obstacle.height / 2),
              child: AnimatedObstacle(obstacle: obstacle),
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
    
    // Selección de mapa
    String mapImage;
    if (widget.selectedMap == 'Ruta 17') {
      mapImage = 'assets/maps/mapa_ruta17_horizontal.png';
    } else if (widget.selectedMap == 'Ruta 21') {
      mapImage = 'assets/maps/mapa_ruta21_horizontal.png';
    } else {
      mapImage = 'assets/maps/mapa_city_horizontal.png';
    }

    return InfiniteScrollMap(
      imagePath: mapImage,
      scrollDirection: Axis.horizontal,
      scrollOffset: _mapScrollPosition,
      reverse: true,
      child: Stack(
        children: [
          ..._obstacles.map(
            (obstacle) => Positioned(
              // Cálculo de posición horizontal
              left: obstacle.x - (obstacle.width / 2),
              top: (screenSize.height / 2) + obstacle.y - (obstacle.height / 2),          
              child: AnimatedObstacle(obstacle: obstacle),
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