import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/machinedata_model.dart';
import '../providers/machine_provider.dart';
import '../providers/settings_provider.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String _selectedPeriod = '7D'; // Options: '7D', '14D', '30D', '90D'
  String _selectedCity = 'All';  // Options: 'All' or city name

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = Provider.of<MachineProvider>(context, listen: false);
      p.fetchAnalytics(city: _selectedCity, period: _selectedPeriod);
    });
  }

  // Plus besoin de _parseMachines car le serveur fait le travail

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<MachineProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final data = provider.analyticsData;
          if (data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[300]),
                   const SizedBox(height: 16),
                   const Text("Données analytics non disponibles"),
                   const SizedBox(height: 16),
                   ElevatedButton(
                     onPressed: () => provider.fetchAnalytics(),
                     style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                     child: const Text("Réessayer"),
                   )
                ],
              ),
            );
          }

          final cards = data['cards'] ?? {};
          final inventaire = (data['inventaire'] as List? ?? []);
          
          return CustomScrollView(
            slivers: [
              _buildAppBar(context, provider),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(settings),
                      const SizedBox(height: 24),
                      _buildFilterBar(context, settings),
                      const SizedBox(height: 32),
                      
                      _buildKpiGrid(context, settings, cards),
                      
                      const SizedBox(height: 32),
                      
                      _buildPremiumCard(
                        context,
                        title: "Tendance de Recyclage ($_selectedPeriod)",
                        child: _buildTrendChart(context, data['tendance_7_jours'] ?? []),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildPremiumCard(
                              context,
                              title: settings.translate('recyc_distribution'),
                              child: _buildPieChart(settings, data['recyc_distribution'] ?? {}),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      _buildPremiumCard(
                        context,
                        title: "Volume par Wilaya (kg)",
                        child: _buildBarChart(context, data['volume_par_wilaya'] ?? []),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle(settings.translate('critical_alerts')),
                      _buildAlerts(context, data['alertes_critiques'] ?? []),
                      
                      const SizedBox(height: 32),
                      
                      _buildSectionTitle(settings.translate('detailed_inventory')),
                      _buildDetailedTable(context, inventaire.where((m) => _selectedCity == 'All' || (m['city'] == _selectedCity)).toList()),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MachineProvider provider) {
    final allWilayas = [
      'All', 'Adrar', 'Chlef', 'Laghouat', 'Oum El Bouaghi', 'Batna', 'Béjaïa', 'Biskra', 
      'Béchar', 'Blida', 'Bouira', 'Tamanrasset', 'Tébessa', 'Tlemcen', 'Tiaret', 'Tizi Ouzou', 
      'Alger', 'Djelfa', 'Jijel', 'Sétif', 'Saïda', 'Skikda', 'Sidi Bel Abbès', 'Annaba', 
      'Guelma', 'Constantine', 'Médéa', 'Mostaganem', 'M\'Sila', 'Mascara', 'Ouargla', 'Oran', 
      'El Bayadh', 'Illizi', 'Bordj Bou Arreridj', 'Boumerdès', 'El Tarf', 'Tindouf', 
      'Tissemsilt', 'El Oued', 'Khenchela', 'Souk Ahras', 'Tipaza', 'Mila', 'Aïn Defla', 
      'Naâma', 'Aïn Témouchent', 'Ghardaïa', 'Relizane', 'Timimoun', 'Bordj Badji Mokhtar', 
      'Ouled Djellal', 'Béni Abbès', 'In Salah', 'In Guezzam', 'Touggourt', 'Djanet', 
      'El M\'Ghair', 'El Meniaâ', 'Aflou', 'El Abiodh Sidi Cheikh', 'El Aricha', 'El Kantara', 
      'Barika', 'Bou Saâda', 'Bir El Ater', 'Ksar El Boukhari', 'Ksar Chellala', 'Aïn Oussera', 'Messaad'
    ];

    return SliverAppBar(
      expandedHeight: 80.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text("EcoVision Analytics", 
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.green),
          onPressed: () => provider.fetchAnalytics(),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCity,
              icon: const Icon(Icons.location_on, size: 18, color: Colors.green),
              style: GoogleFonts.outfit(color: Colors.green, fontWeight: FontWeight.bold),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedCity = newValue);
                  provider.fetchAnalytics(city: newValue, period: _selectedPeriod);
                }
              },
              items: allWilayas.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context, SettingsProvider settings) {
    final provider = Provider.of<MachineProvider>(context, listen: false);
    final periods = ['7D', '14D', '30D', '90D'];
    final labels = {'7D': '7 Jours', '14D': '14 Jours', '30D': '30 Jours', '90D': '3 Mois'};

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final p = periods[index];
          final isSelected = _selectedPeriod == p;
          return FilterChip(
            label: Text(labels[p]!),
            selected: isSelected,
            onSelected: (bool selected) {
              if (selected) {
                setState(() => _selectedPeriod = p);
                provider.fetchAnalytics(city: _selectedCity, period: p);
              }
            },
            selectedColor: Colors.green.withOpacity(0.2),
            checkmarkColor: Colors.green,
            labelStyle: GoogleFonts.readexPro(
              fontSize: 12, 
              color: isSelected ? Colors.green : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.green : Colors.transparent)),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(SettingsProvider settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(settings.translate('analytics'), 
          style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold)),
        Text("Données d'exploitation du parc", 
          style: GoogleFonts.readexPro(fontSize: 14, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildKpiGrid(BuildContext context, SettingsProvider settings, Map<String, dynamic> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double spacing = 20.0;
        final plastic = cards['plastique'] ?? {};
        final alu = cards['aluminium'] ?? {};
        
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            _buildStatCard(context, constraints.maxWidth, settings.translate('total_machines'), (cards['total_machines'] ?? 0).toString(), "Unités", Icons.sensors, const Color(0xFF3B82F6)),
            _buildStatCard(context, constraints.maxWidth, "À Collecter", (cards['a_collecter'] ?? 0).toString(), "Alerte", Icons.warning_rounded, const Color(0xFFEF4444)),
            _buildStatCard(context, constraints.maxWidth, settings.translate('plastic'), "${plastic['weight'] ?? 0}kg", plastic['growth'] ?? "Stable", Icons.eco, const Color(0xFF10B981)),
            _buildStatCard(context, constraints.maxWidth, settings.translate('aluminum'), "${alu['weight'] ?? 0}kg", alu['growth'] ?? "Stable", Icons.precision_manufacturing, const Color(0xFFF59E0B)),
          ],
        );
      }
    );
  }

  Widget _buildStatCard(BuildContext context, double maxWidth, String title, String value, String subtitle, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: (maxWidth - 20) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark 
            ? [color.withOpacity(0.15), color.withOpacity(0.05)]
            : [color.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            blurRadius: 15, 
            color: color.withOpacity(0.05), 
            offset: const Offset(0, 8)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, 
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 4),
          Text(title, 
            style: GoogleFonts.readexPro(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(subtitle, 
              style: GoogleFonts.readexPro(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black.withOpacity(0.05), offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPieChart(SettingsProvider settings, Map<String, dynamic> distribution) {
    final pet = (distribution['PET'] ?? 0).toDouble();
    final alu = (distribution['ALU'] ?? 0).toDouble();
    final total = pet + alu + 0.0001;

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 4,
          centerSpaceRadius: 50,
          sections: [
            PieChartSectionData(
              value: pet,
              title: "${((pet / total) * 100).toInt()}%",
              color: const Color(0xFF10B981),
              radius: 20,
              showTitle: true,
              titleStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            PieChartSectionData(
              value: alu,
              title: "${((alu / total) * 100).toInt()}%",
              color: const Color(0xFF3B82F6),
              radius: 20,
              showTitle: true,
              titleStyle: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, List<dynamic> trends) {
    if (trends.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text("Aucune tendance disponible", style: TextStyle(color: Colors.grey[400])),
      );
    }

    List<FlSpot> spots = [];
    for (int i = 0; i < trends.length; i++) {
      double weight = (trends[i]['weight'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), weight));
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1)),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF10B981),
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF10B981).withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(BuildContext context, List<dynamic> volumes) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= volumes.length) return const SizedBox();
                  String vilaya = volumes[value.toInt()]['wilaya'] ?? "N/A";
                  return Text(vilaya.length > 3 ? vilaya.substring(0, 3) : vilaya, 
                    style: GoogleFonts.readexPro(fontSize: 10, color: Colors.grey));
                },
              ),
            ),
          ),
          barGroups: [
            for (int i = 0; i < volumes.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: (volumes[i]['volume'] ?? 0).toDouble(),
                  color: const Color(0xFF10B981),
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true, 
                    toY: 50, // Max scale relative
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)
                  ),
                )
              ])
          ],
        ),
      ),
    );
  }

  Widget _buildAlerts(BuildContext context, List<dynamic> alerts) {
    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text("Aucune alerte critique", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
      );
    }
    return Column(
      children: alerts.map((a) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Color(0xFFEF4444), radius: 16, child: Icon(Icons.bolt, color: Colors.white, size: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Critique : ${a['machine_id']}", style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                  Text(a['message'] ?? "Action requise", style: GoogleFonts.readexPro(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Text("${(a['fill_percentage'] ?? 0)}%", 
              style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildDetailedTable(BuildContext context, List<dynamic> inventaire) {
    return Column(
      children: inventaire.map((m) {
        double fill = (m['fill_percentage'] ?? 0).toDouble() / 100.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 60, 
                child: Text(
                  m['machine_id'] ?? "N/A", 
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(child: Text(m['city'] ?? "N/A", style: GoogleFonts.readexPro(color: Colors.grey[500]))),
              SizedBox(
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: fill,
                    minHeight: 8,
                    color: fill > 0.8 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    backgroundColor: Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}