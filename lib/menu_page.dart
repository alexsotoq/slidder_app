import 'package:flutter/material.dart';
import 'game_page.dart';
import 'player_select_page.dart';
import 'map_select_page.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  String _selectedMap = 'Mapa';
  String _selectedPlayer = 'red';

  // Animación del personaje
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // Animación del fondo infinito
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();

    // 1. Personaje flotando
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // 2. Fondo Scrolleando Infinitamente
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15), // Ajusta la velocidad aquí
    )..repeat();
  }

  @override
  void dispose() {
    _floatController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. FONDO INFINITO (Solo Asset Local)
          _buildInfiniteBackground(),

          // 2. CAPA OSCURA (Para que se vea mejor el texto)
          Container(
            color: Colors.black.withOpacity(0.6), // Ajusta la oscuridad aquí
          ),

          // 3. CONTENIDO DEL MENÚ
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  _buildPixelTitle(),
                  const SizedBox(height: 40),
                  AnimatedBuilder(
                    animation: _floatAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnimation.value),
                        child: _buildPixelCharacterWithBike(),
                      );
                    },
                  ),
                  const SizedBox(height: 60),
                  _PixelArtButton(
                    text: "JUGAR",
                    color: const Color(0xFFE8A87C),
                    darkColor: const Color(0xFFD38B5D),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => GamePage(
                            playerName: _selectedPlayer,
                            selectedMap: _selectedMap,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _PixelArtButton(
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
                        setState(() {
                          _selectedPlayer = result;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _PixelArtButton(
                    text: "ELEGIR MAPA",
                    color: const Color(0xFF72E78B),
                    darkColor: const Color(0xFF5DA35D),
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
                        setState(() {
                          _selectedMap = result;
                        });
                      }
                    },
                  ),
                  const Spacer(flex: 2),
                  Text(
                    "VERSION 1.0",
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 8,
                      color: Colors.white.withOpacity(0.6),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Lógica del scroll infinito vertical
  Widget _buildInfiniteBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;
            final offset = _backgroundController.value * height;

            return Stack(
              children: [
                // Imagen principal bajando
                Positioned(
                  top: offset,
                  left: 0,
                  right: 0,
                  height: height,
                  child: _buildBackgroundImage(),
                ),
                // Copia de la imagen justo arriba para el bucle
                Positioned(
                  top: offset - height,
                  left: 0,
                  right: 0,
                  height: height,
                  child: _buildBackgroundImage(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Carga ÚNICAMENTE el asset local
  Widget _buildBackgroundImage() {
    return Image.asset(
      'assets/seamless-pokeball-pattern-vector-11290309.png',
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  // --- Widgets existentes sin cambios ---

  Widget _buildPixelTitle() {
    return Column(
      children: [
        Stack(
          children: [
            Positioned(
              top: 4,
              left: 4,
              child: Text(
                "POKEMON",
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 32,
                  color: Colors.black.withOpacity(0.3),
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

  Widget _buildPixelCharacterWithBike() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _buildPixelFrame(
          child: Center(
            child: Image.asset(
              'assets/players/${_selectedPlayer == 'red' ? 'red_player.png' : 'player_green.png'}',
              height: 120,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.none,
            ),
          ),
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
              return const Icon(Icons.directions_bike, size: 70, color: Colors.white);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPixelFrame({required Widget child}) {
    return Stack(
      children: [
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: Colors.black26,
              border: Border.all(color: Colors.black38, width: 4),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
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
              Positioned(
                top: 10,
                left: 10,
                child: _buildCornerLines(),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Transform.rotate(
                  angle: 1.5708,
                  child: _buildCornerLines(),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 10,
                child: Transform.rotate(
                  angle: -1.5708,
                  child: _buildCornerLines(),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 10,
                child: Transform.rotate(
                  angle: 3.1416,
                  child: _buildCornerLines(),
                ),
              ),
              child,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCornerLines() {
    return SizedBox(
      width: 10,
      height: 10,
      child: CustomPaint(
        painter: CornerLinesPainter(),
      ),
    );
  }
}

class _PixelArtButton extends StatefulWidget {
  final String text;
  final Color color;
  final Color darkColor;
  final VoidCallback onPressed;

  const _PixelArtButton({
    required this.text,
    required this.color,
    required this.darkColor,
    required this.onPressed,
  });

  @override
  State<_PixelArtButton> createState() => _PixelArtButtonState();
}

class _PixelArtButtonState extends State<_PixelArtButton> {
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
              if (!_isPressed)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 280,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
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
                      ? _lightenColor(widget.color)
                      : widget.color,
                  border: Border.all(color: widget.darkColor, width: 4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isHovered && !_isPressed
                      ? [
                    BoxShadow(
                      color: widget.color.withOpacity(0.4),
                      blurRadius: 15,
                      spreadRadius: 2,
                    )
                  ]
                      : [],
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.5), width: 2),
                      left: BorderSide(color: Colors.white.withOpacity(0.5), width: 2),
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

  Color _lightenColor(Color color) {
    return Color.fromRGBO(
      (color.red + 30).clamp(0, 255),
      (color.green + 30).clamp(0, 255),
      (color.blue + 30).clamp(0, 255),
      1,
    );
  }
}

class CornerLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFAB91)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.miter;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..moveTo(0, 0)
      ..lineTo(0, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}