import 'dart:io';

import 'package:glu4_dart/glu4_dart.dart';

void main(List<String> args) {
  Prediction prediction =
      Prediction(order: 1, predH: 4, alarmTh: 54, shutoffAlarm: 5, mu: 0.675);
  while (true) {
    print('Insert current glucose: ');
    double? glucosenow = double.tryParse(stdin.readLineSync()!);
    print('Predicted glucose in 20 min = ${prediction.predict(glucosenow)}');
  }
}
