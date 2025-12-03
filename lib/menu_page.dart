import 'package:flutter/material.dart';
import 'global_background.dart';
import 'game_page.dart';
import 'player_select_page.dart';
import 'map_select_page.dart';
import 'credits_page.dart';
import 'services/supabase_service.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  final TextEditingController _userController = TextEditingController();
// Instancia tu servicio
final SupabaseService _supabaseService = SupabaseService();
  String _selectedPlayer = 'red';
  String _selectedMap = 'Parque';
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SIN GlobalBackgroundWrapper aquí (ahora está en main.dart)
    return Scaffold(
      body: Stack(
        children: [
          // Usa el fondo global compartido
          const ScrollingBackground(),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildTitle(),
                    const SizedBox(height: 30),

                    AnimatedBuilder(
                      animation: _floatAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatAnimation.value),
                          child: _buildCharacterFrame(),
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // Botón JUGAR
                    _PixelButton(
                      text: "JUGAR",
                      color: const Color(0xFFE8A87C),
                      darkColor: const Color(0xFFD38B5D),
                      onPressed: () {
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => AlertDialog(
                            title: const Text("Ingresa un username"),
                            content: TextField(
                              controller: _userController,
                              decoration: const InputDecoration(hintText: "Ej. AshKetchum"),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  if (_userController.text.isNotEmpty) {
                                    final username = _userController.text.trim();
                                    
                                    if (context.mounted) {
                                      Navigator.pop(context); 
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GamePage(
                                            playerName: _selectedPlayer,
                                            selectedMap: _selectedMap,
                                            username: username, // <--- Se pasa el username aquí
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text("LISTO"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    // Botón ELEGIR JUGADOR
                    _PixelButton(
                      text: "ELEGIR JUGADOR",
                      color: const Color(0xFFE57373),
                      darkColor: const Color(0xFFD35D5D),
                      onPressed: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerSelectPage(
                              currentPlayer: _selectedPlayer,
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() => _selectedPlayer = result);
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // Botón ELEGIR MAPA
                    _PixelButton(
                      text: "ELEGIR MAPA",
                      color: const Color(0xFF81C784),
                      darkColor: const Color(0xFF519657),
                      onPressed: () async {
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MapSelectPage(
                              currentMap: _selectedMap,
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() => _selectedMap = result);
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // Botón CRÉDITOS
                    _PixelButton(
                      text: "CREDITOS",
                      color: const Color(0xFF64B5F6),
                      darkColor: const Color(0xFF2286C3),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreditsPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "VERSION 1.0",
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 8,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Stack(
          children: [
            Positioned(
              top: 4,
              left: 4,
              child: Text(
                "POKEMON",
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 32,
                  color: Colors.black,
                  height: 1,
                ),
              ),
            ),
            const Text(
              "POKEMON",
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 32,
                color: Color(0xFFFDD835),
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE57373),
            border: Border.all(color: const Color(0xFFD35D5D), width: 3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            "RUNNER",
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 16,
              color: Colors.white,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterFrame() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Stack(
          children: [
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                border: Border.all(color: const Color(0xFFE8A87C), width: 5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE8A87C).withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  for (var i = 0; i < 4; i++)
                    Positioned(
                      top: i == 0 || i == 1 ? 10 : null,
                      bottom: i == 2 || i == 3 ? 10 : null,
                      left: i == 0 || i == 2 ? 10 : null,
                      right: i == 1 || i == 3 ? 10 : null,
                      child: Transform.rotate(
                        angle: [0.0, 1.5708, 4.71239, 3.14159][i],
                        child: CustomPaint(
                          size: const Size(10, 10),
                          painter: _CornerPainter(),
                        ),
                      ),
                    ),
                  Center(
                    // para seleccionar entre cuatro personajes
                    child: Image.asset(
                      _selectedPlayer == 'red' ? 'assets/players/red_player.png' :
                      _selectedPlayer == 'green' ? 'assets/players/player_green.png' :
                      _selectedPlayer == 'brandon' ? 'assets/players/brandon_player.png' :
                      'assets/players/may_player.png',

                      height: 120,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          bottom: -50,
          right: -45,
          child: Image.network(
            'https://static.vecteezy.com/system/resources/thumbnails/066/411/833/small_2x/pixel-art-yellow-bicycle-with-brown-saddle-png.png',
            width: 140,
            height: 140,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.directions_bike,
                size: 70,
                color: Colors.white,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PixelButton extends StatefulWidget {
  final String text;
  final Color color;
  final Color darkColor;
  final VoidCallback onPressed;

  const _PixelButton({
    required this.text,
    required this.color,
    required this.darkColor,
    required this.onPressed,
  });

  @override
  State<_PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<_PixelButton> {
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
          curve: Curves.easeOut,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 280,
                height: 56,
                margin: EdgeInsets.only(
                  top: _isPressed ? 6 : 0,
                  left: _isPressed ? 6 : 0,
                ),
                decoration: BoxDecoration(
                  color: _isHovered && !_isPressed
                      ? Color.lerp(widget.color, Colors.white, 0.15)
                      : widget.color,
                  border: Border.all(color: widget.darkColor, width: 4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isHovered && !_isPressed
                      ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ]
                      : [],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                      left: BorderSide(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.text,
                      style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 14,
                        color: Colors.white,
                        height: 1,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFAB91)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}