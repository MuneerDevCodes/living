import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:living/style/theme.dart';
import 'package:living/services/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:html' as html;

class DataExportService {
  static final DataExportService _instance = DataExportService._internal();
  factory DataExportService() => _instance;
  DataExportService._internal();

  // Export formats
  static const String _jsonFormat = 'json';
  static const String _csvFormat = 'csv';
  static const String _pdfFormat = 'pdf';

  // Export carbon footprint data
  Future<void> exportCarbonFootprintData(BuildContext context, {
    required String format,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!context.mounted) return;
    final data = await _getCarbonFootprintData(startDate, endDate);
    if (!context.mounted) return;
    await _exportData(context, 'carbon_footprint', data, format);
  }

  // Export waste tracker data
  Future<void> exportWasteTrackerData(BuildContext context, {
    required String format,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!context.mounted) return;
    final data = await _getWasteTrackerData(startDate, endDate);
    if (!context.mounted) return;
    await _exportData(context, 'waste_tracker', data, format);
  }

  // Export challenges data
  Future<void> exportChallengesData(BuildContext context, {
    required String format,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final data = await _getChallengesData(startDate, endDate);
    await _exportData(context, 'challenges', data, format);
  }

  // Export goals data
  Future<void> exportGoalsData(BuildContext context, {
    required String format,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final data = await _getGoalsData(startDate, endDate);
    await _exportData(context, 'goals', data, format);
  }

  // Export all data
  Future<void> exportAllData(BuildContext context, {
    required String format,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!context.mounted) return;
    final carbonData = await _getCarbonFootprintData(startDate, endDate);
    if (!context.mounted) return;
    final wasteData = await _getWasteTrackerData(startDate, endDate);
    if (!context.mounted) return;
    final challengesData = await _getChallengesData(startDate, endDate);
    if (!context.mounted) return;
    final goalsData = await _getGoalsData(startDate, endDate);
    if (!context.mounted) return;

    final allData = {
      'export_info': {
        'export_date': DateTime.now().toIso8601String(),
        'date_range': {
          'start': startDate.toIso8601String(),
          'end': endDate.toIso8601String(),
        },
        'user_id': AuthService.getCurrentUserId(),
      },
      'carbon_footprint': carbonData,
      'waste_tracker': wasteData,
      'challenges': challengesData,
      'goals': goalsData,
    };

    await _exportData(context, 'all_sustainability_data', allData, format);
  }

  // Get carbon footprint data for export
  Future<Map<String, dynamic>> _getCarbonFootprintData(DateTime startDate, DateTime endDate) async {
    // This would fetch from Firebase or local storage
    // For now, we'll return sample data
    return {
      'summary': {
        'total_entries': 30,
        'average_carbon_footprint': 4.2,
        'total_reduction': 15.5,
        'period': '${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      },
      'entries': List.generate(30, (index) => {
        'date': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
        'carbon_footprint': 4.0 + (index % 3) * 0.5,
        'category': ['Transportation', 'Energy', 'Food', 'Waste'][index % 4],
        'activity': 'Sample activity $index',
      }),
    };
  }

  // Get waste tracker data for export
  Future<Map<String, dynamic>> _getWasteTrackerData(DateTime startDate, DateTime endDate) async {
    return {
      'summary': {
        'total_entries': 25,
        'total_waste_reduced': 12.5,
        'recycling_rate': 78.5,
        'period': '${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      },
      'entries': List.generate(25, (index) => {
        'date': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
        'waste_type': ['Plastic', 'Paper', 'Glass', 'Metal', 'Organic'][index % 5],
        'amount': 0.5 + (index % 3) * 0.2,
        'disposal_method': ['Recycling', 'Composting', 'Donation'][index % 3],
      }),
    };
  }

  // Get challenges data for export
  Future<Map<String, dynamic>> _getChallengesData(DateTime startDate, DateTime endDate) async {
    return {
      'summary': {
        'total_challenges': 8,
        'completed_challenges': 6,
        'total_points_earned': 450,
        'period': '${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      },
      'challenges': List.generate(8, (index) => {
        'challenge_name': 'Challenge ${index + 1}',
        'category': ['Energy Conservation', 'Waste Reduction', 'Transportation'][index % 3],
        'difficulty': ['Easy', 'Medium', 'Hard'][index % 3],
        'points_earned': 50 + (index * 10),
        'completion_date': DateTime.now().subtract(Duration(days: index * 3)).toIso8601String(),
        'status': index < 6 ? 'completed' : 'in_progress',
      }),
    };
  }

  // Get goals data for export
  Future<Map<String, dynamic>> _getGoalsData(DateTime startDate, DateTime endDate) async {
    return {
      'summary': {
        'total_goals': 5,
        'completed_goals': 3,
        'average_progress': 75.5,
        'period': '${startDate.toIso8601String()} to ${endDate.toIso8601String()}',
      },
      'goals': List.generate(5, (index) => {
        'goal_name': 'Goal ${index + 1}',
        'goal_type': ['Carbon Reduction', 'Waste Reduction', 'Energy Savings'][index % 3],
        'target_value': 10.0 + (index * 2),
        'current_value': 8.0 + (index * 1.5),
        'progress_percentage': 60.0 + (index * 10),
        'status': index < 3 ? 'completed' : 'in_progress',
      }),
    };
  }

  // Export data in specified format
  Future<void> _exportData(
    BuildContext context,
    String dataType,
    Map<String, dynamic> data,
    String format,
  ) async {
    if (!context.mounted) return;
    
    String content;
    String fileName;
    String mimeType;

    switch (format) {
      case _jsonFormat:
        content = jsonEncode(data);
        fileName = '${dataType}_${DateTime.now().millisecondsSinceEpoch}.json';
        mimeType = 'application/json';
        break;
      case _csvFormat:
        content = _convertToCSV(data);
        fileName = '${dataType}_${DateTime.now().millisecondsSinceEpoch}.csv';
        mimeType = 'text/csv';
        break;
      case _pdfFormat:
        content = _convertToPDF(data);
        fileName = '${dataType}_${DateTime.now().millisecondsSinceEpoch}.pdf';
        mimeType = 'application/pdf';
        break;
      default:
        throw Exception('Unsupported format: $format');
    }

    await _showExportDialog(context, fileName, content, mimeType);
  }

  // Convert data to CSV format
  String _convertToCSV(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    
    // Add summary section
    buffer.writeln('SUSTAINABILITY DATA EXPORT');
    buffer.writeln('Generated on: ${DateTime.now().toIso8601String()}');
    buffer.writeln('');
    
    if (data.containsKey('summary')) {
      buffer.writeln('SUMMARY:');
      final summary = data['summary'] as Map<String, dynamic>;
      summary.forEach((key, value) {
        buffer.writeln('$key,$value');
      });
      buffer.writeln('');
    }
    
    // Add detailed data
    if (data.containsKey('entries')) {
      buffer.writeln('DETAILED DATA:');
      buffer.writeln('Date,Value,Category,Type,Status');
      
      for (final entry in data['entries']) {
        final date = entry['date'] ?? '';
        final value = entry['carbon_footprint'] ?? entry['amount'] ?? '';
        final category = entry['category'] ?? entry['waste_type'] ?? '';
        final type = entry['activity'] ?? entry['disposal_method'] ?? '';
        
        buffer.writeln('$date,$value,$category,$type,active');
      }
    }
    
    return buffer.toString();
  }

  // Convert data to PDF format (simulated)
  String _convertToPDF(Map<String, dynamic> data) {
    // In a real app, this would generate a proper PDF
    // For now, we'll return a formatted text representation
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('=' * 50);
    buffer.writeln('SUSTAINABILITY DATA EXPORT');
    buffer.writeln('Generated on: ${DateTime.now().toIso8601String()}');
    buffer.writeln('=' * 50);
    buffer.writeln('');
    
    // Summary section
    if (data.containsKey('summary')) {
      buffer.writeln('SUMMARY:');
      buffer.writeln('-' * 20);
      final summary = data['summary'] as Map<String, dynamic>;
      summary.forEach((key, value) {
        buffer.writeln('${key.replaceAll('_', ' ').toUpperCase()}: $value');
      });
      buffer.writeln('');
    }
    
    // Detailed data section
    if (data.containsKey('entries')) {
      buffer.writeln('DETAILED DATA:');
      buffer.writeln('-' * 20);
      
      for (int i = 0; i < data['entries'].length; i++) {
        final entry = data['entries'][i];
        buffer.writeln('Entry ${i + 1}:');
        buffer.writeln('  Date: ${entry['date'] ?? 'N/A'}');
        buffer.writeln('  Value: ${entry['carbon_footprint'] ?? entry['amount'] ?? 'N/A'}');
        buffer.writeln('  Category: ${entry['category'] ?? entry['waste_type'] ?? 'N/A'}');
        buffer.writeln('  Type: ${entry['activity'] ?? entry['disposal_method'] ?? 'N/A'}');
        buffer.writeln('');
      }
    }
    
    // Footer
    buffer.writeln('=' * 50);
    buffer.writeln('End of Report');
    buffer.writeln('=' * 50);
    
    return buffer.toString();
  }

  // Show export dialog
  Future<void> _showExportDialog(
    BuildContext context,
    String fileName,
    String content,
    String mimeType,
  ) async {
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Export Data'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your data has been prepared for export:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text('File: $fileName'),
            Text('Size: ${(content.length / 1024).toStringAsFixed(1)} KB'),
            Text('Format: ${mimeType.split('/').last.toUpperCase()}'),
            SizedBox(height: 12),
            Text(
              'Click "Download" to save the file to your device.',
              style: TextStyle(fontSize: 12, color: AppColors.secondaryText),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _downloadFile(context, fileName, content, mimeType);
            },
            icon: Icon(Icons.download),
            label: Text('Download'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // Download file (real implementation)
  Future<void> _downloadFile(
    BuildContext context,
    String fileName,
    String content,
    String mimeType,
  ) async {
    if (!context.mounted) return;
    
    try {
      // Show preparing message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preparing download...'),
            backgroundColor: AppColors.info,
            duration: Duration(seconds: 1),
          ),
        );
      }
      
      // Convert content to bytes
      final bytes = utf8.encode(content);
      
      // Download based on platform
      bool downloadSuccess = false;
      
      try {
        // For web platform
        if (kIsWeb) {
          downloadSuccess = await _downloadFileWeb(fileName, bytes, mimeType);
        } else {
          // For mobile platforms
          downloadSuccess = await _downloadFileMobile(fileName, bytes, mimeType);
        }
      } catch (e) {
        print('Download error: $e');
        downloadSuccess = false;
      }
      
      // Show result message
      if (context.mounted) {
        if (downloadSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File downloaded successfully!'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download failed. Please try again.'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
      
      // Add to export history
      await _addToExportHistory(fileName.split('_')[0], mimeType.split('/').last, fileName);
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Download file for web platform
  Future<bool> _downloadFileWeb(String fileName, List<int> bytes, String mimeType) async {
    try {
      // Create blob
      final blob = html.Blob([bytes], mimeType);
      
      // Create download link
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      
      // Clean up
      html.Url.revokeObjectUrl(url);
      
      return true;
    } catch (e) {
      print('Web download error: $e');
      return false;
    }
  }

  // Download file for mobile platforms
  Future<bool> _downloadFileMobile(String fileName, List<int> bytes, String mimeType) async {
    try {
      // Get downloads directory
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        print('Could not access downloads directory');
        return false;
      }
      
      // Create file path
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      
      // Write file
      await file.writeAsBytes(bytes);
      
      print('File saved to: $filePath');
      return true;
    } catch (e) {
      print('Mobile download error: $e');
      return false;
    }
  }

  // Get export history
  Future<List<Map<String, dynamic>>> getExportHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = AuthService.getCurrentUserId();
    if (userId == null) return [];

    final key = '${userId}_export_history';
    final data = prefs.getString(key);
    
    if (data != null) {
      return List<Map<String, dynamic>>.from(
        jsonDecode(data) as List,
      );
    }
    return [];
  }

  // Add to export history
  Future<void> _addToExportHistory(String dataType, String format, String fileName) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = AuthService.getCurrentUserId();
    if (userId == null) return;

    final key = '${userId}_export_history';
    final existingData = prefs.getString(key);
    
    List<Map<String, dynamic>> history = [];
    if (existingData != null) {
      history = List<Map<String, dynamic>>.from(
        jsonDecode(existingData) as List,
      );
    }
    
    history.add({
      'data_type': dataType,
      'format': format,
      'file_name': fileName,
      'export_date': DateTime.now().toIso8601String(),
    });
    
    // Keep only last 10 exports
    if (history.length > 10) {
      history = history.sublist(history.length - 10);
    }
    
    await prefs.setString(key, jsonEncode(history));
  }
} 