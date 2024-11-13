import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:glu4_dart/glu4_dart.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<double?> glucose = [];
  List<double?> pred = [];
  int pH = 5;
  final Uri _url = Uri.parse('https://github.com/lcossu/Glu4');

  @override
  void initState() {
    prediction = Prediction(
        order: 1, predH: pH, alarmTh: 54, shutoffAlarm: 9, mu: 0.675);
    super.initState();
  }

  late Prediction prediction;
  int i = 0;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25, color: Colors.black);
    const spacerSmall = SizedBox(height: 10);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.restart_alt),
          tooltip: 'Reset',
          onPressed: () => setState(() {
            glucose = [];
            pred = [];
            prediction.reset();
          }),
        ),
        appBar: AppBar(
          title: Text(
            'Glu4: predict your glucose',
            style: Theme.of(context).textTheme.displayMedium,
          ),
        ),
        body: Stack(
          children: [
            Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'Discover the code at: github.com/lcossu/Glu4',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                )),
            DefaultTextStyle(
              style: textStyle,
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height / 2),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(children: [
                          Positioned(
                            right: 1,
                            child: MenuAnchor(
                              builder: (BuildContext context,
                                  MenuController controller, Widget? child) {
                                return IconButton(
                                  onPressed: () {
                                    if (controller.isOpen) {
                                      controller.close();
                                    } else {
                                      controller.open();
                                    }
                                  },
                                  icon: const Icon(Icons.settings),
                                  tooltip: 'Show settings',
                                );
                              },
                              menuChildren: [
                                MenuItemButton(
                                  onPressed: () => null,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('PH: $pH'),
                                      SizedBox(
                                        width: 200,
                                        child: Slider.adaptive(
                                            label: pH.toString(),
                                            value: pH.toDouble(),
                                            min: 1,
                                            max: 10,
                                            divisions: 11,
                                            onChanged: (newp) => setState(() {
                                                  pH = newp.round();
                                                  pred = List.filled(
                                                      growable: true,
                                                      glucose.length,
                                                      null);
                                                  prediction.predH =
                                                      newp.round();
                                                })),
                                      )
                                    ],
                                  ),
                                ),
                                MenuItemButton(
                                  onPressed: () => null,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('TH: ${prediction.alarmTh}'),
                                      SizedBox(
                                        width: 200,
                                        child: Slider.adaptive(
                                            label:
                                                prediction.alarmTh.toString(),
                                            value:
                                                prediction.alarmTh.toDouble(),
                                            min: 50,
                                            max: 100,
                                            divisions: 51,
                                            onChanged: (newp) => setState(() {
                                                  prediction.alarmTh =
                                                      newp.round();
                                                })),
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chart(
                            glucose: glucose,
                            prediction: pred,
                            pH: pH,
                            th: prediction.alarmTh,
                          ),
                        ]),
                      ),
                    ),
                    spacerSmall,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            const Text('Current glucose level:'),
                            Text(glucose.isEmpty
                                ? ''
                                : glucose.last != null
                                    ? glucose.last!.toStringAsFixed(2)
                                    : 'Null'),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Predicted glucose at T+$pH: '),
                            Text(pred.isEmpty
                                ? ''
                                : pred.last != null
                                    ? pred.last!.toStringAsFixed(2)
                                    : 'Null'),
                            prediction.hasAlarm()
                                ? const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 40,
                                    color: Colors.red,
                                  )
                                : Container(),
                          ],
                        ),
                      ],
                    ),
                    spacerSmall,
                    const Text('Insert next glucose value:'),
                    Focus(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                              width: 100,
                              child: TextField(
                                onSubmitted: (_) => doprediction(),
                                controller: _controller,
                                focusNode: _focusNode,
                                autofocus: true,
                              )),
                          const Text('mg/dL'),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                                onPressed: () {
                                  doprediction();
                                },
                                child: const Text('Predict!')),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void doprediction() {
    setState(() {
      if (!_checkInput(_controller.text)) return;
      glucose.add(double.tryParse(_controller.text));
      i++;
      _controller.clear();
      pred.clear();
      pred.addAll(prediction.predictList(glucose.last).toList());
    });
    _focusNode.requestFocus();
  }
}

bool _checkInput(String text) {
  if (text == '') return true;
  double? val = double.tryParse(text);
  if (val == null) return false;
  if (val < 40) return false;
  if (val > 400) {
    return false;
  } else {
    return true;
  }
}

class Chart extends StatelessWidget {
  const Chart(
      {super.key,
      required this.glucose,
      required this.prediction,
      required this.pH,
      required this.th});

  final List<double?> glucose;
  final List<double?> prediction;
  final int pH;
  final int th;
  final int maxNStep = 15;

  LineChartData get sampleData1 => LineChartData(
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topLeft,
                labelResolver: (p0) => p0.y.toStringAsFixed(1),
              ),
              y: th.toDouble(),
              strokeWidth: 3,
              dashArray: [20, 10],
            ),
          ],
        ),
        lineTouchData: lineTouchData1,
        gridData: gridData,
        titlesData: titlesData1,
        borderData: borderData,
        lineBarsData: lineBarsData1,
        clipData: const FlClipData.all(),
        minX: max(0, glucose.length + pH + 1 - maxNStep).toDouble(),
        maxX: glucose.length + pH + 1,
        maxY: 400,
        minY: 0,
      );

  FlBorderData get borderData => FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.2), width: 4),
          left: const BorderSide(color: Colors.transparent),
          right: const BorderSide(color: Colors.transparent),
          top: const BorderSide(color: Colors.transparent),
        ),
      );
  LineTouchData get lineTouchData1 => const LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.white,
        ),
      );

  FlTitlesData get titlesData1 => FlTitlesData(
        bottomTitles: AxisTitles(
            sideTitles: bottomTitles,
            axisNameSize: 30,
            axisNameWidget: Text('Step')),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
            sideTitles: leftTitles(),
            axisNameWidget: Text('mg/dL'),
            axisNameSize: 40),
      );

  List<LineChartBarData> get lineBarsData1 =>
      [lineChartBarData1_1, lineChartBarData2_1];

  List<LineChartBarData> get lineBarsData2 => [
        lineChartBarData2_1,
      ];

  LineChartBarData get lineChartBarData2_1 => LineChartBarData(
        isCurved: true,
        curveSmoothness: 0,
        color: Colors.blue.withOpacity(0.5),
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: FlDotData(
          checkToShowDot: (spot, barData) => spot.x != glucose.length - 1,
          show: true,
          getDotPainter: (p0, p1, p2, p3) => FlDotCirclePainter(
              color: p0.y < th ? Colors.red : Colors.blue, strokeWidth: 0),
        ),
        belowBarData: BarAreaData(show: false),
        spots: prediction.isEmpty
            ? []
            : (prediction..insert(0, glucose.last))
                .asMap()
                .map<int, FlSpot>(
                  (key, value) {
                    if (value == null) {
                      return MapEntry(key, FlSpot.nullSpot);
                    }
                    return MapEntry(key,
                        FlSpot(key.toDouble() + glucose.length - 1, value));
                  },
                )
                .values
                .toList(),
      );

  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
        barWidth: 8,
        color: Colors.green.withOpacity(0.5),
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
        spots: glucose
            .asMap()
            .map<int, FlSpot>(
              (key, value) {
                if (value == null) {
                  return MapEntry(key, FlSpot.nullSpot);
                }
                return MapEntry(key, FlSpot(key.toDouble(), value));
              },
            )
            .values
            .toList(),
      );

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    /* switch (value.toInt()) {
      case 1:
        text = '1m';
        break;
      case 2:
        text = '2m';
        break;
      case 3:
        text = '3m';
        break;
      case 4:
        text = '5m';
        break;
      case 5:
        text = '6m';
        break;
      default:
        return Container();
    } */

    text = value.toString();
    return Text(text, style: style, textAlign: TextAlign.center);
  }

  SideTitles leftTitles() => SideTitles(
        getTitlesWidget: leftTitleWidgets,
        showTitles: true,
        interval: 50,
        reservedSize: 60,
      );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    /* switch (value.toInt()) {
      case 2:
        text = const Text('SEPT', style: style);
        break;
      case 7:
        text = const Text('OCT', style: style);
        break;
      case 12:
        text = const Text('DEC', style: style);
        break;
      default:
        text = const Text('');
        break;
    } */
    text = Text(
      value.toInt().toString(),
      style: style,
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: text,
    );
  }

  SideTitles get bottomTitles => SideTitles(
        showTitles: true,
        reservedSize: 32,
        interval: 1,
        getTitlesWidget: bottomTitleWidgets,
      );

  FlGridData get gridData => const FlGridData(show: false);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Indicator(text: 'Glucose', color: Colors.green),
            Indicator(text: 'Prediction', color: Colors.blue),
          ],
        ),
        Expanded(
          child: LineChart(
            sampleData1,
            duration: const Duration(milliseconds: 250),
          ),
        ),
      ],
    );
  }
}

class Indicator extends StatelessWidget {
  const Indicator({super.key, required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            color: color,
          ),
          Text(text)
        ],
      ),
    );
  }
}
