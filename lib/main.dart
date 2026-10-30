import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'nest/core/nest_theme.dart';
import 'nest/nest_app.dart';
import 'nest/state/cart_controller.dart';
import 'nest/state/custom_pieces_controller.dart';
import 'nest/state/favorites_controller.dart';
import 'nest/state/room_board_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: NestColors.cream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // If saved data can't be loaded, the app still opens (just without saving).
  try {
    await favoritesController.load();
    await cartController.load();
    // Custom pieces must load before rooms (rooms refer to them by id).
    await customPieces.load();
    await roomBoardController.load();
  } catch (error) {
    debugPrint('NEST: could not load saved data: $error');
  }

  runApp(const NestApp());
}
