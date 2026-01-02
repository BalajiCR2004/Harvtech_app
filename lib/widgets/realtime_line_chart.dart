import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// A real-time line chart that displays live data with 1:1 accuracy
class RealtimeLineChart extends StatefulWidget {
  final String title;
  final String unit;
  final Color lineColor;
  final Color gradientColor;
  final double minY;
  final double maxY;
  final int maxDataPoints;
  final Stream<double> dataStream;

  const RealtimeLineChart({
    super.key,
    required this.title,
    required this.unit,
    required this.dataStream,
    this.lineColor = Colors.blue,
    this.gradientColor = Colors.blue,
    this.minY = 0,
    this.maxY = 100,
    this.maxDataPoints = 60, // 60 seconds of data by default
  });

  @override
  State<RealtimeLineChart> createState() => _RealtimeLineChartState();
}

class _RealtimeLineChartState extends State<RealtimeLineChart> {
  final Queue<FlSpot> _dataPoints = Queue<FlSpot>();
  double _currentValue = 0;
  int _dataIndex = 0;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    widget.dataStream.listen((value) {
      if (mounted) {
        setState(() {
          _currentValue = value;
          _dataPoints.add(FlSpot(_dataIndex.toDouble(), value));
          _dataIndex++;

          // Remove old data points to keep the chart scrolling
          while (_dataPoints.length > widget.maxDataPoints) {
            _dataPoints.removeFirst();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.lineColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_currentValue.toStringAsFixed(1)} ${widget.unit}',
                  style: TextStyle(
                    color: widget.lineColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _dataPoints.isEmpty
                ? Center(
                    child: Text(
                      'Waiting for data...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: (widget.maxY - widget.minY) / 4,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey[800]!,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (widget.maxY - widget.minY) / 4,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: _dataPoints.isNotEmpty ? _dataPoints.first.x : 0,
                      maxX: _dataPoints.isNotEmpty
                          ? _dataPoints.last.x
                          : widget.maxDataPoints.toDouble(),
                      minY: widget.minY,
                      maxY: widget.maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _dataPoints.toList(),
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: widget.lineColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                widget.gradientColor.withValues(alpha: 0.4),
                                widget.gradientColor.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${spot.y.toStringAsFixed(1)} ${widget.unit}',
                                TextStyle(
                                  color: widget.lineColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                    duration: const Duration(milliseconds: 0),
                  ),
          ),
        ],
      ),
    );
  }
}
