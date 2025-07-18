// EnergyTipService.dart
import '../models/energy_tip_model.dart';
import 'energy_tip_dao.dart';
import 'carbon_footprint_dao.dart';

class EnergyTipService {
  /// Returns a list of personalized energy tips for the given user.
  Future<List<EnergyTip>> getPersonalizedTips(String userId) async {
    // Fetch user's carbon footprint entries
    final entries = await CarbonFootprintDAO.getUserEntries(userId);
    // Filter for energy-related entries
    final energyEntries = entries.where((e) => e.category == 'Energy').toList();
    if (energyEntries.isEmpty) {
      // If no energy entries, return general tips
      return await EnergyTipDAO.getAllEnergyTips();
    }
    // Find the most impactful energy subcategory
    final Map<String, double> subcategoryTotals = {};
    for (final entry in energyEntries) {
      subcategoryTotals[entry.subcategory] =
          (subcategoryTotals[entry.subcategory] ?? 0) + entry.carbonImpact;
    }
    String? topSubcategory;
    double maxImpact = 0.0;
    subcategoryTotals.forEach((sub, impact) {
      if (impact > maxImpact) {
        maxImpact = impact;
        topSubcategory = sub;
      }
    });
    // Recommend tips for the most impactful subcategory, or all energy tips if not found
    if (topSubcategory != null && topSubcategory!.isNotEmpty) {
      final tips = await EnergyTipDAO.getEnergyTipsByCategory(topSubcategory!);
      if (tips.isNotEmpty) return tips;
    }
    // Fallback: return all energy tips
    return await EnergyTipDAO.getAllEnergyTips();
  }
} 