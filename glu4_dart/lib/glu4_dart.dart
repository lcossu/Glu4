import 'package:ml_linalg/linalg.dart';

/// Prediction class keeping all the information and parameters required to perdorm real time glucose prediction.
class Prediction {
  /// order of the underlying autoregressive model
  int order;

  /// prediction horizon (in steps)
  int predH;

  /// forgetting factor of the autoregressive model
  double mu;

  /// last triggered alarm
  int lastAlarm = 0;

  /// glucose level threshold to trigger the alarm
  int alarmTh;

  /// number of steps to shutoff any triggered alarm
  int shutoffAlarm;

  late Matrix _P;
  late Matrix _ahat;
  late Matrix _psi;
  late int _startup;
  int _step = 0;
  bool _afterNan = false;
  List<double>? _lastpred;

  Prediction(
      {required this.order,
      required this.predH,
      required this.alarmTh,
      required this.shutoffAlarm,
      required this.mu}) {
    _init();
  }

  /// reset the prediction memory
  void reset() {
    _init();
    lastAlarm = 0;
    _lastpred = null;
  }

  void _init() {
    _P = Matrix.diagonal(List.filled(order, 10));
    _ahat = Matrix.row(List.filled(order, 1 / order));
    _psi = Matrix.row(List.filled(order, 0));
    _startup = order;
  }

  /// predict the next glucose values up to the prediction horizon step
  List<double?> predictList(double? glu) {
    _step++;

    if (glu == null) {
      _afterNan = true;
      _init();
      _lastpred = null;
      return List.filled(predH, null);
    }

    if (_startup != 0) {
      var oldpsi = _psi.asFlattenedList;
      oldpsi[_startup - 1] = glu;
      _psi = Matrix.row(oldpsi);
      if (_afterNan) {
        _afterNan = false;
        _startup = _startup - 1;
        _lastpred = null;
        return List.filled(predH, null);
      }
    }

    Matrix den = (_psi.transpose() * _P * _psi + mu);
    Matrix K = (_P * _psi) / den;
    _P = (_P - (_P * _psi * _psi.transpose() * _P) / den) * (1 / mu);

    _ahat = (K * ((_psi.transpose() * _ahat) * -1 + glu) + _ahat);
    _psi = Matrix.row([glu, ..._psi.asFlattenedList.getRange(0, order - 1)]);

    var psiTmp = _psi;

    double? xp;
    List<double> allpred = [];
    for (int j = 1; j <= predH; j++) {
      xp = (_ahat.transpose() * psiTmp).toVector().first;
      allpred.add(xp.roundToDouble());
      psiTmp = Matrix.row(
          [xp, ...psiTmp.asFlattenedList.getRange(0, psiTmp.length - 1)]);
    }
    if (_startup != 0) {
      _startup = _startup - 1;
      _lastpred = null;
      return List.filled(predH, null);
    }
    _lastpred = allpred;
    return allpred;
  }

  /// predict the next glucose value at the prediction horizon step
  double? predict(double? glu) {
    return predictList(glu)?.last;
  }

  /// did the last prediction generate an alarm?
  bool hasAlarm() {
    bool alarm = false;
    if (_step - lastAlarm > shutoffAlarm || _step <= shutoffAlarm)
      alarm = _lastpred?.any((element) => element < alarmTh) ?? false;
    if (alarm) lastAlarm = _step;
    return alarm;
  }
}
