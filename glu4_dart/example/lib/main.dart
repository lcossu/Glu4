import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glu4_dart/glu4_dart.dart';

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
  final int pH = 4;

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
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.restart_alt),
          onPressed: () => setState(() {
            glucose = [];
            pred = [];
            prediction.reset();
          }),
        ),
        appBar: AppBar(
          title: const Text('Glu4: predict your glucose'),
        ),
        body: DefaultTextStyle(
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
                    child: Chart(
                      glucose: glucose,
                      prediction: pred,
                      pH: pH,
                      th: prediction.alarmTh,
                    ),
                  ),
                ),
                spacerSmall,
                const Text('current glucose level:'),
                Text(glucose.isEmpty
                    ? ''
                    : glucose.last != null
                        ? glucose.last!.toStringAsFixed(2)
                        : 'Null'),
                spacerSmall,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('predicted glucose: '),
                    prediction.hasAlarm()
                        ? const Icon(
                            Icons.warning_amber_rounded,
                            size: 40,
                            color: Colors.red,
                          )
                        : Container(),
                  ],
                ),
                Text(pred.isEmpty
                    ? ''
                    : pred.last != null
                        ? pred.last!.toStringAsFixed(2)
                        : 'Null'),
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
      ),
    );
  }

  void doprediction() {
    setState(() {
      glucose.add(double.tryParse(_controller.text));
      i++;
      _controller.clear();
      pred.add(prediction.predict(glucose.last));
    });
    _focusNode.requestFocus();
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

  LineChartData get sampleData1 => LineChartData(
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
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
        minX: 0,
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
  LineTouchData get lineTouchData1 => LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
        ),
      );

  FlTitlesData get titlesData1 => FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: bottomTitles,
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: leftTitles(),
        ),
      );

  List<LineChartBarData> get lineBarsData1 =>
      [lineChartBarData1_1, lineChartBarData2_1];

  List<LineChartBarData> get lineBarsData2 => [
        lineChartBarData2_1,
      ];

  LineChartBarData get lineChartBarData2_1 => LineChartBarData(
        isCurved: true,
        curveSmoothness: 0,
        color: Colors.green.withOpacity(0.5),
        barWidth: 4,
        isStrokeCapRound: true,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
        spots: prediction
            .asMap()
            .map<int, FlSpot>(
              (key, value) {
                if (value == null) {
                  return MapEntry(key, FlSpot.nullSpot);
                }
                return MapEntry(key, FlSpot(key.toDouble() + pH, value));
              },
            )
            .values
            .toList(),
      );

  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
        isCurved: true,
        barWidth: 8,
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
        reservedSize: 40,
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
    return LineChart(
      sampleData1,
      duration: const Duration(milliseconds: 250),
    );
  }
}
