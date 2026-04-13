import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';

class InsightScreen extends StatelessWidget {
  const InsightScreen({super.key});

  static const List<_InsightKpi> _kpis = [
    _InsightKpi(
      label: '등록 완료율',
      value: 92,
      icon: CupertinoIcons.check_mark_circled,
      accentColor: Color(0xFF2F6BFF),
    ),
    _InsightKpi(
      label: '사용 완료율(30일)',
      value: 38,
      icon: CupertinoIcons.ticket,
      accentColor: Color(0xFF4C8DFF),
    ),
    _InsightKpi(
      label: '만료율',
      value: 22,
      icon: CupertinoIcons.clock,
      accentColor: Color(0xFFF29B55),
    ),
    _InsightKpi(
      label: '알림 오픈율',
      value: 27,
      icon: CupertinoIcons.bell,
      accentColor: Color(0xFF5AC8A8),
    ),
  ];

  static const List<_BrandExpireRate> _brandRates = [
    _BrandExpireRate(brand: '스타벅스', rate: 31),
    _BrandExpireRate(brand: 'CU', rate: 28),
    _BrandExpireRate(brand: 'GS25', rate: 25),
    _BrandExpireRate(brand: '버거킹', rate: 23),
    _BrandExpireRate(brand: '올리브영', rate: 20),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('인사이트'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(CupertinoIcons.info_circle),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.xl,
          ),
          children: [
            Text(
              '앱 안에서 현재 쿠폰 현황을 빠르게 확인할 수 있는 요약판이에요.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _kpis.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: AppSpacing.md,
                mainAxisSpacing: AppSpacing.md,
                childAspectRatio: 1.12,
              ),
              itemBuilder: (context, index) {
                return _KpiCard(kpi: _kpis[index]);
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            _ChartCard(brandRates: _brandRates),
            const SizedBox(height: AppSpacing.lg),
            const _InsightSummaryCard(
              message: '알림 오픈 그룹은 사용 완료율이 더 높았어요.',
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.kpi,
  });

  final _InsightKpi kpi;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8ECF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08162033),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: kpi.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              kpi.icon,
              color: kpi.accentColor,
              size: 20,
            ),
          ),
          const Spacer(),
          Text(
            '${kpi.value}%',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 32,
              height: 1.0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            kpi.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6F7B8C),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.brandRates,
  });

  final List<_BrandExpireRate> brandRates;

  @override
  Widget build(BuildContext context) {
    final maxRate = brandRates
        .map((item) => item.rate)
        .reduce((current, next) => current > next ? current : next);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8ECF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08162033),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '브랜드별 만료율 Top5',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '만료율이 높은 브랜드를 간단히 요약해 보여줘요.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xl),
          ...brandRates.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _BarChartRow(
                label: item.brand,
                value: item.rate,
                maxValue: maxRate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarChartRow extends StatelessWidget {
  const _BarChartRow({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  final String label;
  final int value;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final widthFactor = value / maxValue;

    return Row(
      children: [
        SizedBox(
          width: 68,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF4B5563),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  color: const Color(0xFFF1F4F9),
                ),
                FractionallySizedBox(
                  widthFactor: widthFactor,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8FB2FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 34,
          child: Text(
            '$value%',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6F7B8C),
            ),
          ),
        ),
      ],
    );
  }
}

class _InsightSummaryCard extends StatelessWidget {
  const _InsightSummaryCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDDE7FA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF1FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              CupertinoIcons.sparkles,
              color: Color(0xFF2F6BFF),
              size: 19,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '한 줄 인사이트',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightKpi {
  const _InsightKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color accentColor;
}

class _BrandExpireRate {
  const _BrandExpireRate({
    required this.brand,
    required this.rate,
  });

  final String brand;
  final int rate;
}
