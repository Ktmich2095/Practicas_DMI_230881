import 'package:flutter_dotenv/flutter_dotenv.dart';


class Environment {

  static String theMovieDbKey = dotenv.env['THE_MOVIEDB_KEY'] ?? dotenv.env['API_KEY_MOVIEBD'] ?? 'No hay api key';


}