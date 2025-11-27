import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../home/widgets/home_header.dart';
import '../home/widgets/stats_section.dart';
import '../home/widgets/cta_section.dart';
import '../home/widgets/recent_activity_section.dart';
import '../../providers/dashboard_providers.dart';

// Track Screen - Using the redesigned modular widgets
class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: const HomeHeader(),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate and refresh all providers
          ref.invalidate(dailyStatsProvider);
          ref.invalidate(recentActivitiesProvider);

          // Wait for providers to complete
          await Future.wait([
            ref.read(dailyStatsProvider.future),
            ref.read(recentActivitiesProvider.future),
          ]);
        },
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 24),

              // Stats Section
              StatsSection(),
              SizedBox(height: 24),

              // CTA Section
              CTASection(),
              SizedBox(height: 24),

              // Recent Activity Section
              RecentActivitySection(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
