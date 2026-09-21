// 实例性能视图（详情页"监控"子 tab）。
//
// 对齐 Dashboard 概览页的性能卡：每 3 秒采样 `/api/system`，
// 用 fl_chart 绘制进程 CPU 与内存占用折线；窗口内保留最近
// 约 4 分钟样本（3s × 80），切换子 tab 采样继续（keep-alive）。

import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/instance.dart';
import '../services/dashboard_api.dart';
import '../widgets/states.dart';

/// 单次采样：CPU / 内存（进程与整机，均为百分比）
class _Sample {
  const _Sample(this.cpu, this.memProcess, this.memSystem);
  final double cpu;
  final double memProcess;
  final double memSystem;
}

/// 性能折线视图
class InstancePerformanceView extends StatefulWidget {
  final Instance instance;
  const InstancePerformanceView({super.key, required this.instance});

  @override
  State<InstancePerformanceView> createState() =>
      _InstancePerformanceViewState();
}

class _InstancePerformanceViewState extends State<InstancePerformanceView>
    with AutomaticKeepAliveClientMixin {
  /// 采样窗口：3s × 80 ≈ 最近 4 分钟
  static const int _maxSamples = 80;

  final List<_Sample> _samples = [];
  Timer? _timer;
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _sample();
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _sample(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sample() async {
    try {
      final info = await DashboardApi(widget.instance).getSystemInfo();
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = null;
        _samples.add(
          _Sample(
            info.cpuPercent,
            info.memoryPercent,
            info.systemMemoryPercent,
          ),
        );
        if (_samples.length > _maxSamples) _samples.removeAt(0);
      });
    } catch (e) {
      if (!mounted) return;
      // 采样失败保留已有曲线，仅记录错误（连续失败时首屏会走到错误视图）
      setState(
        () => _error = '$e',
      );
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _sample();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);

    if (_samples.isEmpty) {
      if (_loading) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(l10n.commonLoading),
            ],
          ),
        );
      }
      return ErrorView(message: _error ?? '', onRetry: _retry);
    }

    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _ChartCard(
          title: l10n.perfCpu,
          color: scheme.primary,
          spots: _samples
              .asMap()
              .entries
              .map((e) => FlSpot(e.key.toDouble(), e.value.cpu.clamp(0, 100)))
              .toList(),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: l10n.perfMemory,
          color: scheme.primary,
          legendProcess: l10n.perfLegendProcess,
          legendSystem: l10n.perfLegendSystem,
          colorSystem: scheme.tertiary,
          spots: _samples
              .asMap()
              .entries
              .map(
                (e) => FlSpot(
                  e.key.toDouble(),
                  e.value.memProcess.clamp(0, 100),
                ),
              )
              .toList(),
          spots2: _samples
              .asMap()
              .entries
              .map(
                (e) => FlSpot(
                  e.key.toDouble(),
                  e.value.memSystem.clamp(0, 100),
                ),
              )
              .toList(),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// 单张折线卡（可选第二条对比线）
class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.color,
    required this.spots,
    this.spots2,
    this.colorSystem,
    this.legendProcess,
    this.legendSystem,
  });

  final String title;
  final Color color;
  final List<FlSpot> spots;

  /// 第二条线（整机内存）与图例文案；为空则只画一条线
  final List<FlSpot>? spots2;
  final Color? colorSystem;
  final String? legendProcess;
  final String? legendSystem;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final smallText = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        );

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (spots2 != null) ...[
                  _LegendDot(
                    color: color,
                    label: legendProcess ?? '',
                  ),
                  const SizedBox(width: 12),
                  _LegendDot(
                    color: colorSystem ?? scheme.tertiary,
                    label: legendSystem ?? '',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        interval: 25,
                        getTitlesWidget: (v, _) => Text(
                          '${v.toInt()}%',
                          style: smallText,
                        ),
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 2,
                      color: color,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withValues(alpha: 0.08),
                      ),
                    ),
                    if (spots2 != null)
                      LineChartBarData(
                        spots: spots2!,
                        isCurved: true,
                        barWidth: 2,
                        color: colorSystem ?? scheme.tertiary,
                        dotData: const FlDotData(show: false),
                      ),
                  ],
                  lineTouchData: const LineTouchData(enabled: true),
                ),
                // 采样窗口恒定 80 点，宽度变化只影响视觉密度，无需重建
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 图例圆点
class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final smallText = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: smallText),
      ],
    );
  }
}
