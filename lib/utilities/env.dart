// lib/env/env.dart
// ignore_for_file: non_constant_identifier_names

import 'package:envied/envied.dart';
part 'env.g.dart';



@Envied(path: '.env', obfuscate: true)
final class Env {
  @EnviedField(varName: 'GOOGLE_PLACES_API_KEY')
  static final String GOOGLE_PLACES_API_KEY = _Env.GOOGLE_PLACES_API_KEY;
  @EnviedField(varName: 'GRAPHHOPPER_API_KEY')
  static final String GRAPHHOPPER_API_KEY = _Env.GRAPHHOPPER_API_KEY;
}
