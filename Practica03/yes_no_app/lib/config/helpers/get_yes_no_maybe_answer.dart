import 'dart:math';

import 'package:dio/dio.dart';
import 'package:yes_no_app/domain/entities/messages.dart';
import 'package:yes_no_app/infrastructure/models/yes_no_maybe_model.dart';

class GetYesNoMaybeAnswer {

  final _dio = Dio();

  Future <Message> getAnswer() async {
    final value = Random().nextInt(11);
    final DateTime time = DateTime.now();
    final String answer = value<=2?"maybe":value<=6?"yes":"no";
    print(answer);
    // https://yes-no-wtf.vercel.app/api?$answer
    final response = await _dio.get("https://yesno.wtf/api?force=$answer");

    final yesNoMaybeModel = YesNoMaybeModel.fromJsonMap(response.data);

    return yesNoMaybeModel.toMessageEntity();
  }
}