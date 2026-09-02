import 'package:flutter/material.dart';
import 'package:life_rank/core/constants/financial_rank_config.dart';
import '../widgets/rank_card.dart';

class RankShowcaseScreen extends StatefulWidget {
  const RankShowcaseScreen({super.key});

  @override
  State<RankShowcaseScreen> createState() => _RankShowcaseScreenState();
}

class _RankShowcaseScreenState extends State<RankShowcaseScreen> {
  double _currentNetWorth = 62500000; // Default to Master II range

  @override
  Widget build(BuildContext context) {
    final currentRank = FinancialRankCalculator.calculate(_currentNetWorth);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Gamification Showcase',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Mobile Legends Inspired Rank Progression',
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              RankCard(progress: currentRank),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Simulate Net Worth Growth',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: currentRank.rank.primaryColor,
                        thumbColor: currentRank.rank.primaryColor,
                        inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                        valueIndicatorColor: currentRank.rank.primaryColor,
                      ),
                      child: Slider(
                        value: _currentNetWorth,
                        min: 0,
                        max: 120000000,
                        divisions: 120,
                        label: 'Rp${(_currentNetWorth / 1000000).toStringAsFixed(1)}M',
                        onChanged: (value) {
                          setState(() => _currentNetWorth = value);
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Rp0', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        Text('Rp120M+', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
