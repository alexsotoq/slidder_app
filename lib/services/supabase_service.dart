import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Servicio centralizado para gestionar todas las interacciones con Supabase.
/// 
/// Encapsula autenticación, consultas y operaciones CRUD en la tabla 'players'.
class SupabaseService {
  final SupabaseClient _client;

  /// Constructor. Recibe el cliente de Supabase (por defecto usa Supabase.instance.client).
  SupabaseService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Obtiene el cliente de Supabase (útil si necesitas acceso directo en casos especiales).
  SupabaseClient get client => _client;

  /// Obtiene el usuario actualmente autenticado.
  User? get currentUser => _client.auth.currentUser;

  /// Obtiene la sesión actual.
  Session? get currentSession => _client.auth.currentSession;

  /// Stream que emite cambios en el estado de autenticación.
  Stream<AuthState> get onAuthStateChange => _client.auth.onAuthStateChange;

  // --- NUEVO ---
  Future<void> _ensureAuth() async {
    final session = _client.auth.currentSession;
    if (session == null) {
      debugPrint('⚠️ No hay sesión. Autenticando...');
      final email = dotenv.env['AUTH_EMAIL'];
      final password = dotenv.env['AUTH_PASSWORD'];
      if (email != null && password != null) {
        await signIn(email: email, password: password);
      }
    }
  }

  // ============================================================================
  // AUTENTICACIÓN
  // ============================================================================

  /// Inicia sesión con email y contraseña.
  /// 
  /// Retorna `true` si la autenticación fue exitosa, `false` en caso contrario.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        debugPrint('❌ Error signing in: No session returned');
        return false;
      } else {
        debugPrint('✅ User signed in: ${response.user?.email}');
        return true;
      }
    } catch (error) {
      debugPrint('❌ Error inesperado al hacer sign in: $error');
      return false;
    }
  }

  /// Cierra la sesión actual.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      debugPrint('✅ Usuario deslogueado.');
    } catch (error) {
      debugPrint('❌ Error al hacer sign out: $error');
    }
  }

  // ============================================================================
  // OPERACIONES EN LA TABLA 'players'
  // ============================================================================

  /// Inserta un nuevo jugador en la tabla 'players'.
  /// 
  /// Si no hay sesión activa, intenta hacer sign-in primero usando credenciales del .env.
  /// 
  /// Parámetros:
  /// - [playerName]: Nombre del jugador.
  /// - [points]: Puntos iniciales del jugador.
  /// - [userId]: ID del usuario propietario (opcional, por defecto usa un ID fijo).
  Future<void> insertPlayer({
    required String playerName,
    required int points,
    String? userId,
  }) async {
    final session = _client.auth.currentSession;
    final user = _client.auth.currentUser;

    debugPrint('session: $session');
    debugPrint('user id: ${user?.id}');

    if (session == null || user == null) {
      // Intenta autenticarse si no hay sesión usando credenciales del .env
      debugPrint('⚠️ No hay sesión activa. Intentando autenticar...');
      final email = dotenv.env['AUTH_EMAIL'];
      final password = dotenv.env['AUTH_PASSWORD'];
      
      if (email != null && password != null) {
        await signIn(email: email, password: password);
      } else {
        debugPrint('❌ No se encontraron credenciales en .env');
        return;
      }
    }

    try {
      final newPlayer = {
        'player_name': playerName,
        'points': points,
        'user_id': userId ?? '3843a525-e9d5-414c-9994-dbb81aa4f633',
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('players').insert(newPlayer);

      debugPrint('✅ Jugador insertado exitosamente: $playerName');
    } on PostgrestException catch (error) {
      debugPrint('❌ Error al insertar jugador: ${error.message}');
    } catch (error) {
      debugPrint('❌ Error inesperado al insertar: $error');
    }
  }

  /// Actualiza los puntos de un jugador existente en la tabla 'players'.
  /// 
  /// Filtra por el nombre del jugador.
  /// 
  /// Parámetros:
  /// - [playerName]: Nombre del jugador a actualizar.
  /// - [points]: Nuevos puntos del jugador.
  Future<void> updatePlayer({
    required String playerName,
    required int points,
  }) async {
    // 1. Aseguramos login antes de nada
    await _ensureAuth();

    try {
      // Definimos los datos a actualizar
      final updatedData = {
        'points': points,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // 2. Ejecutamos el update y usamos .select() para confirmar
      // Guardamos la respuesta en una variable para verificar si funcionó
      final response = await _client
          .from('players')
          .update(updatedData)
          .eq('player_name', playerName)
          .select(); 

      // Verificamos si la lista de respuesta está vacía (significa que no encontró al jugador para actualizar)
      if (response.isEmpty) {
        debugPrint('⚠️ ALERTA: La actualización se ejecutó pero no modificó nada. Revisa permisos RLS o el nombre exacto.');
      } else {
        debugPrint('✅ Jugador $playerName actualizado correctamente en la Nube.');
      }

    } catch (error) {
      debugPrint('❌ Error update: $error');
    }
  }

  /// Verifica si un jugador existe. Si existe, lo actualiza; si no, lo inserta (UPSERT).
  /// 
  /// Parámetros:
  /// - [playerName]: Nombre del jugador.
  /// - [score]: Puntos a asignar o actualizar.
  Future<void> checkAndUpsertPlayer({
    required String playerName,
    required int score,
  }) async {
    try {
      final response = await _client
          .from('players')
          .select('id, player_name, points')
          .eq('player_name', playerName)
          .limit(1);

      if (response.isNotEmpty) {
        // Jugador existe → UPDATE
        final existingPlayer = response.first;
        final existingPlayerName = existingPlayer['player_name'] as String;
        final existingPoints = existingPlayer['points'] as int;

        debugPrint(
            'Jugador $playerName | $existingPlayerName encontrado. Actualizando puntuación de $existingPoints a $score...');

        await updatePlayer(playerName: playerName, points: score);
      } else {
        // Jugador NO existe → INSERT
        debugPrint(
            'Jugador $playerName no encontrado. Insertando nuevo registro...');

        await insertPlayer(playerName: playerName, points: score);
      }
    } on PostgrestException catch (error) {
      debugPrint('❌ Error de Supabase al buscar jugador: ${error.message}');
    } catch (error) {
      debugPrint('❌ Error inesperado: $error');
    }
  }

  /// Recupera los puntos de un jugador desde la tabla 'players'.
  /// 
  /// Retorna los puntos si el jugador existe, o `null` si no se encuentra.
  /// 
  /// Parámetros:
  /// - [playerName]: Nombre del jugador a buscar.
  Future<int?> retrievePoints({required String playerName}) async {
    try {
      final response = await _client
          .from('players')
          .select('points')
          .eq('player_name', playerName)
          .limit(1);

      if (response.isNotEmpty) {
        final playerData = response.first;
        final points = playerData['points'] as int;
        debugPrint('✅ Puntos recuperados para $playerName: $points');
        return points;
      } else {
        debugPrint('⚠️ Jugador $playerName no encontrado.');
        return null;
      }
    } catch (error) {
      debugPrint('❌ Error inesperado al recuperar puntos: $error');
      return null;
    }
  }
}
