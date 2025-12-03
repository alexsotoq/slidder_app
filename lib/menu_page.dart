import 'package:flutter/material.dart';
import 'game_page.dart'; // Asegúrate de que tu GamePage acepte el parámetro mapName
import 'player_select_page.dart';
import 'map_select_page.dart'; // Nueva página importada
import 'credits_page.dart'; // Nueva página importada

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  // Jugador seleccionado actualmente ('red' o 'green')
  String _selectedPlayer = 'red';

  // Mapa seleccionado actualmente (nuevo estado)
  String _selectedMap = 'Parque';

  // Controlador para animación de flotación del personaje (arriba/abajo)
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  // Controlador para scroll infinito del fondo
  late AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();

    // Configura animación que se repite en reversa (sube y baja)
    // Duración: 2 segundos por ciclo completo
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // Define rango de movimiento vertical: -8px a +8px
    // Usa curva easeInOut para movimiento suave
    _floatAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Configura scroll continuo del fondo (sin reversa)
    // Duración: 15 segundos por ciclo completo
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    // Limpia controladores para evitar memory leaks
    _floatController.dispose();
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Capa 1: Fondo con patrón seamless animado
          _buildScrollingBackground(),

          // Capa 2: Overlay azul semitransparente para mejorar contraste
          Container(color: Colors.blueAccent.withOpacity(0.75)),

          // Capa 3: Contenido del menú
          SafeArea(
            child: Center(
              // SingleChildScrollView agregado para evitar overflow en pantallas pequeñas
              // debido a los nuevos botones
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildTitle(),
                    const SizedBox(height: 30),

                    // Personaje con animación de flotación
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

                    // --- SECCIÓN DE BOTONES ---

                    // 1. Botón para iniciar juego
                    _PixelButton(
                      text: "JUGAR",
                      color: const Color(0xFFE8A87C), // Naranja suave
                      darkColor: const Color(0xFFD38B5D),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          // NOTA: Asegúrate de actualizar el constructor de GamePage
                          // para recibir el mapa si es necesario.
                          builder: (context) => GamePage(
                            playerName: _selectedPlayer,
                            selectedMap: _selectedMap,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 2. Botón para seleccionar personaje
                    _PixelButton(
                      text: "ELEGIR JUGADOR",
                      color: const Color(0xFFE57373), // Rojo suave
                      darkColor: const Color(0xFFD35D5D),
                      onPressed: () async {
                        // Abre página de selección y espera resultado
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerSelectPage(
                              currentPlayer: _selectedPlayer,
                            ),
                          ),
                        );
                        // Actualiza jugador seleccionado si hay resultado
                        if (result != null)
                          setState(() => _selectedPlayer = result);
                      },
                    ),

                    const SizedBox(height: 12),

                    // 3. Botón para seleccionar mapa (NUEVO)
                    _PixelButton(
                      text: "ELEGIR MAPA",
                      color: const Color(0xFF81C784),
                      // Verde suave (Estilo Planta/Bosque)
                      darkColor: const Color(0xFF519657),
                      onPressed: () async {
                        // Navega a la selección de mapa y espera el string del mapa
                        final result = await Navigator.push<String>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MapSelectPage(currentMap: _selectedMap),
                          ),
                        );
                        // Actualiza el mapa si el usuario eligió uno
                        if (result != null)
                          setState(() => _selectedMap = result);
                      },
                    ),

                    const SizedBox(height: 12),

                    // 4. Botón de Créditos (NUEVO)
                    _PixelButton(
                      text: "CREDITOS",
                      color: const Color(0xFF64B5F6),
                      // Azul suave (Estilo Agua/Hielo)
                      darkColor: const Color(0xFF2286C3),
                      onPressed: () {
                        // Navegación simple a página informativa
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreditsPage(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    // Versión de la app y Mapa seleccionado
                    Column(
                      children: [
                        /*
                        Text(
                          "MAPA: ${_selectedMap.toUpperCase()}",
                          style: const TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 10,
                            color: Color(0xFF81C784), // Verde claro para destacar
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        */
                        const Text(
                          "VERSION 1.0",
                          style: TextStyle(
                            fontFamily: 'PressStart2P',
                            fontSize: 8,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
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

  /// Construye fondo con patrón seamless que se desplaza infinitamente
  ///
  /// Funciona con dos capas idénticas que se mueven verticalmente
  /// Cuando una sale por abajo, la otra entra por arriba = loop perfecto
  Widget _buildScrollingBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Altura del patrón original en píxeles
            const patternHeight = 1000.0;

            // Calcula offset actual usando módulo para loop infinito
            // Value va de 0.0 a 1.0, multiplicado por altura da píxeles
            final offset =
                (_backgroundController.value * patternHeight) % patternHeight;

            return ClipRect(
              child: Stack(
                children: [
                  // Genera dos capas: una en offset actual, otra en offset - altura
                  // Esto asegura que siempre haya cobertura total durante el scroll
                  for (var i = -1; i <= 0; i++)
                    Positioned(
                      left: 0,
                      top: offset + (i * patternHeight),
                      child: Container(
                        width: constraints.maxWidth,
                        // Altura extra para cubrir durante transición
                        height: constraints.maxHeight + patternHeight,
                        decoration: const BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(
                              'assets/seamless-pokeball-pattern-vector-11290309.png',
                            ),
                            repeat: ImageRepeat.repeat,
                            // Repite horizontalmente
                            fit: BoxFit.none,
                            // No estira la imagen
                            scale: 2.0,
                            // Hace la imagen más pequeña (2x = mitad de tamaño)
                            filterQuality: FilterQuality
                                .none, // Sin suavizado para pixel art
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Construye el título "POKEMON RUNNER" con efecto de sombra
  Widget _buildTitle() {
    return Column(
      children: [
        Stack(
          children: [
            // Sombra negra desplazada 4px abajo y derecha
            Positioned(
              top: 4,
              left: 4,
              child: Text(
                "POKEMON",
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 32,
                  color: Colors.black,
                  height: 1, // Sin espacio entre líneas
                ),
              ),
            ),
            // Texto principal amarillo
            const Text(
              "POKEMON",
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 32,
                color: Color(0xFFFDD835), // Amarillo Pokémon
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Badge "RUNNER" con bordes pixel art
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE57373),
            // Rojo claro
            border: Border.all(color: const Color(0xFFD35D5D), width: 3),
            // Borde rojo oscuro
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

  /// Construye frame del personaje con decoraciones de esquina y bicicleta
  Widget _buildCharacterFrame() {
    return Stack(
      clipBehavior: Clip.none, // Permite elementos fuera del contenedor
      children: [
        // Frame decorativo con sombra
        Stack(
          children: [
            // Frame principal
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                // Color crema
                border: Border.all(color: const Color(0xFFE8A87C), width: 5),
                // Borde naranja
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
                  // Genera decoraciones en las 4 esquinas
                  // i=0: top-left, i=1: top-right, i=2: bottom-left, i=3: bottom-right
                  for (var i = 0; i < 4; i++)
                    Positioned(
                      top: i == 0 || i == 1 ? 10 : null,
                      bottom: i == 2 || i == 3 ? 10 : null,
                      left: i == 0 || i == 2 ? 10 : null,
                      right: i == 1 || i == 3 ? 10 : null,
                      child: Transform.rotate(
                        // CORRECCIÓN: Asignamos manualmente los ángulos correctos
                        // 0: 0° (TL), 1: 90° (TR), 2: 270° (BL), 3: 180° (BR)
                        angle: [0.0, 1.5708, 4.71239, 3.14159][i],
                        child: CustomPaint(
                          size: const Size(10, 10),
                          painter: _CornerPainter(),
                        ),
                      ),
                    ),
                  // Imagen del personaje seleccionado
                  Center(
                    child: Image.asset(
                      'assets/players/${_selectedPlayer == 'red' ? 'red_player.png' : 'player_green.png'}',
                      height: 120,
                      fit: BoxFit.contain,
                      filterQuality:
                          FilterQuality.none, // Sin suavizado para pixel art
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        // Bicicleta posicionada abajo a la derecha (fuera del frame)
        Positioned(
          bottom: -50,
          right: -45,
          child: Image.network(
            'https://static.vecteezy.com/system/resources/thumbnails/066/411/833/small_2x/pixel-art-yellow-bicycle-with-brown-saddle-png.png',
            width: 140,
            height: 140,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            // Muestra ícono si falla la carga
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

/// Botón estilo pixel art con efectos hover y presionado (Reutilizable)
class _PixelButton extends StatefulWidget {
  final String text;
  final Color color; // Color principal del botón
  final Color darkColor; // Color del borde
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
  bool _isPressed = false; // Botón está siendo presionado
  bool _isHovered = false; // Mouse está sobre el botón

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
          // Escala ligeramente al hacer hover (excepto cuando está presionado)
          scale: _isHovered && !_isPressed ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: Stack(
            children: [
              // Botón principal que se mueve cuando se presiona
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 280,
                height: 56,
                // Desplaza hacia la sombra cuando está presionado
                margin: EdgeInsets.only(
                  top: _isPressed ? 6 : 0,
                  left: _isPressed ? 6 : 0,
                ),
                decoration: BoxDecoration(
                  // Color más claro al hacer hover (mezcla 15% con blanco)
                  color: _isHovered && !_isPressed
                      ? Color.lerp(widget.color, Colors.white, 0.15)
                      : widget.color,
                  border: Border.all(color: widget.darkColor, width: 4),
                  borderRadius: BorderRadius.circular(12),
                  // Glow effect al hacer hover
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
                    // Borde de highlight en top y left para efecto 3D
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
                            blurRadius: 0, // Sin blur para efecto pixel art
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

/// Dibuja decoración en forma de "L" para las esquinas del frame
class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0xFFFFAB91) // Naranja claro
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round; // Extremos redondeados

    // Dibuja línea horizontal (de izquierda a derecha)
    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);

    // Dibuja línea vertical (de arriba a abajo)
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
