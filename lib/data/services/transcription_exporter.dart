import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

/// Export formats supported by the TranscriptionExporter
enum ExportFormat {
  /// Plain text (.txt)
  plainText,
  
  /// Rich text with timestamps (.rtf) 
  richText,
  
  /// JSON format (.json)
  json,
  
  /// SubRip subtitle format (.srt)
  srt,
  
  /// WebVTT subtitle format (.vtt)
  vtt,
  
  /// Word document (.docx) - Note: Requires additional libraries
  docx,
}

/// A utility class for exporting transcriptions in various formats
class TranscriptionExporter {
  /// Export a transcription to a file
  /// 
  /// Parameters:
  /// - [transcriptionData]: The transcription data containing text and segments
  /// - [format]: The export format to use
  /// - [outputPath]: Optional path to save the file (if null, a path will be generated)
  /// - [includeTimestamps]: Whether to include timestamps in formats that support it
  /// - [includeConfidence]: Whether to include confidence scores in formats that support it
  /// 
  /// Returns the path to the exported file
  static Future<String> exportTranscription({
    required Map<String, dynamic> transcriptionData,
    required ExportFormat format,
    String? outputPath,
    bool includeTimestamps = true,
    bool includeConfidence = false,
  }) async {
    // Generate a default path if none provided
    final path = outputPath ?? await _generateDefaultPath(format);
    
    // Export based on the selected format
    switch (format) {
      case ExportFormat.plainText:
        return _exportPlainText(transcriptionData, path, includeTimestamps);
      case ExportFormat.richText:
        return _exportRichText(transcriptionData, path, includeTimestamps, includeConfidence);
      case ExportFormat.json:
        return _exportJson(transcriptionData, path);
      case ExportFormat.srt:
        return _exportSrt(transcriptionData, path);
      case ExportFormat.vtt:
        return _exportVtt(transcriptionData, path);
      case ExportFormat.docx:
        return _exportDocx(transcriptionData, path, includeTimestamps, includeConfidence);
    }
  }
  
  /// Generate a default export path based on format
  static Future<String> _generateDefaultPath(ExportFormat format) async {
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final extension = _getExtension(format);
    
    return '${directory.path}/transcription_$timestamp.$extension';
  }
  
  /// Get the file extension for a format
  static String _getExtension(ExportFormat format) {
    switch (format) {
      case ExportFormat.plainText:
        return 'txt';
      case ExportFormat.richText:
        return 'rtf';
      case ExportFormat.json:
        return 'json';
      case ExportFormat.srt:
        return 'srt';
      case ExportFormat.vtt:
        return 'vtt';
      case ExportFormat.docx:
        return 'docx';
    }
  }
  
  /// Format a timestamp as HH:MM:SS
  static String _formatTimestamp(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    
    final remainingMinutes = minutes % 60;
    final remainingSeconds = seconds % 60;
    
    return '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  /// Format a timestamp as HH:MM:SS,MMM for SRT format
  static String _formatSrtTimestamp(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    
    final remainingMinutes = minutes % 60;
    final remainingSeconds = seconds % 60;
    final remainingMilliseconds = milliseconds % 1000;
    
    return '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')},${remainingMilliseconds.toString().padLeft(3, '0')}';
  }
  
  /// Format a timestamp as HH:MM:SS.MMM for VTT format
  static String _formatVttTimestamp(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final hours = minutes ~/ 60;
    
    final remainingMinutes = minutes % 60;
    final remainingSeconds = seconds % 60;
    final remainingMilliseconds = milliseconds % 1000;
    
    return '${hours.toString().padLeft(2, '0')}:${remainingMinutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}.${remainingMilliseconds.toString().padLeft(3, '0')}';
  }
  
  /// Export as plain text
  static Future<String> _exportPlainText(
    Map<String, dynamic> transcriptionData,
    String path,
    bool includeTimestamps,
  ) async {
    final buffer = StringBuffer();
    
    if (includeTimestamps && transcriptionData.containsKey('segments')) {
      // With timestamps
      final segments = transcriptionData['segments'] as List<dynamic>;
      for (final segment in segments) {
        final timestamp = _formatTimestamp(segment['start'] as int);
        buffer.writeln('[$timestamp] ${segment['text']}');
        buffer.writeln();
      }
    } else {
      // Without timestamps
      buffer.write(transcriptionData['transcription'] as String);
    }
    
    final file = File(path);
    await file.writeAsString(buffer.toString());
    return path;
  }
  
  /// Export as rich text
  static Future<String> _exportRichText(
    Map<String, dynamic> transcriptionData,
    String path,
    bool includeTimestamps,
    bool includeConfidence,
  ) async {
    final buffer = StringBuffer();
    
    // RTF header
    buffer.write('{\\rtf1\\ansi\\ansicpg1252\\cocoartf2580\\cocoasubrtf220\n');
    buffer.write('{\\fonttbl\\f0\\fswiss\\fcharset0 Helvetica;\\f1\\fswiss\\fcharset0 Helvetica-Bold;}\n');
    buffer.write('{\\colortbl;\\red0\\green0\\blue0;\\red0\\green0\\blue255;\\red128\\green128\\blue128;}\n');
    buffer.write('\\margl1440\\margr1440\\vieww11520\\viewh8400\\viewkind0\n');
    buffer.write('\\pard\\tx720\\tx1440\\tx2160\\tx2880\\tx3600\\tx4320\\tx5040\\tx5760\\tx6480\\tx7200\\tx7920\\tx8640\\pardirnatural\\partightenfactor0\n\n');
    
    // Add title
    buffer.write('{\\f1\\b\\fs28 Transcription}\\par\\pard\\par\n');
    
    if (includeTimestamps && transcriptionData.containsKey('segments')) {
      // With timestamps
      final segments = transcriptionData['segments'] as List<dynamic>;
      for (final segment in segments) {
        final timestamp = _formatTimestamp(segment['start'] as int);
        
        // Add timestamp in blue
        buffer.write('{\\f1\\b\\cf2 [$timestamp]}');
        
        // Add confidence if requested
        if (includeConfidence && segment.containsKey('confidence')) {
          final confidence = segment['confidence'] as double;
          final confidencePercent = (confidence * 100).toInt();
          buffer.write('{\\f1\\i\\cf3  ($confidencePercent%)}');
        }
        
        // Add text
        buffer.write(' ${segment['text']}\\par\\pard\\par\n');
      }
    } else {
      // Without timestamps
      buffer.write('${transcriptionData['transcription']}\\par\n');
    }
    
    // Close RTF document
    buffer.write('}');
    
    final file = File(path);
    await file.writeAsString(buffer.toString());
    return path;
  }
  
  /// Export as JSON
  static Future<String> _exportJson(
    Map<String, dynamic> transcriptionData,
    String path,
  ) async {
    final file = File(path);
    final jsonData = jsonEncode(transcriptionData);
    await file.writeAsString(jsonData);
    return path;
  }
  
  /// Export as SRT subtitle format
  static Future<String> _exportSrt(
    Map<String, dynamic> transcriptionData,
    String path,
  ) async {
    final buffer = StringBuffer();
    
    if (transcriptionData.containsKey('segments')) {
      final segments = transcriptionData['segments'] as List<dynamic>;
      
      for (int i = 0; i < segments.length; i++) {
        final segment = segments[i];
        final startTime = _formatSrtTimestamp(segment['start'] as int);
        final endTime = _formatSrtTimestamp(segment['end'] as int);
        
        // Subtitle number
        buffer.writeln('${i + 1}');
        
        // Time range
        buffer.writeln('$startTime --> $endTime');
        
        // Text content
        buffer.writeln('${segment['text']}');
        
        // Empty line between subtitles
        buffer.writeln();
      }
    } else {
      // Fallback if no segments
      buffer.write('1\n00:00:00,000 --> 00:01:00,000\n${transcriptionData['transcription']}\n');
    }
    
    final file = File(path);
    await file.writeAsString(buffer.toString());
    return path;
  }
  
  /// Export as WebVTT subtitle format
  static Future<String> _exportVtt(
    Map<String, dynamic> transcriptionData,
    String path,
  ) async {
    final buffer = StringBuffer();
    
    // VTT header
    buffer.writeln('WEBVTT');
    buffer.writeln();
    
    if (transcriptionData.containsKey('segments')) {
      final segments = transcriptionData['segments'] as List<dynamic>;
      
      for (int i = 0; i < segments.length; i++) {
        final segment = segments[i];
        final startTime = _formatVttTimestamp(segment['start'] as int);
        final endTime = _formatVttTimestamp(segment['end'] as int);
        
        // Optional cue identifier
        buffer.writeln('cue-${i + 1}');
        
        // Time range
        buffer.writeln('$startTime --> $endTime');
        
        // Text content
        buffer.writeln('${segment['text']}');
        
        // Empty line between cues
        buffer.writeln();
      }
    } else {
      // Fallback if no segments
      buffer.write('cue-1\n00:00:00.000 --> 00:01:00.000\n${transcriptionData['transcription']}\n');
    }
    
    final file = File(path);
    await file.writeAsString(buffer.toString());
    return path;
  }
  
  /// Export as DOCX (Word document)
  /// Note: This is a simplified version - in a real app, you'd use a proper DOCX library
  static Future<String> _exportDocx(
    Map<String, dynamic> transcriptionData,
    String path,
    bool includeTimestamps,
    bool includeConfidence,
  ) async {
    // In a real implementation, you would use a library like docx or office
    // For this demo, we'll create a simple XML-based .docx structure
    
    final mainDocument = XmlBuilder();
    mainDocument.processing('xml', 'version="1.0" encoding="UTF-8" standalone="yes"');
    mainDocument.element('w:document', nest: () {
      mainDocument.attribute('xmlns:w', 'http://schemas.openxmlformats.org/wordprocessingml/2006/main');
      
      mainDocument.element('w:body', nest: () {
        // Title
        mainDocument.element('w:p', nest: () {
          mainDocument.element('w:pPr', nest: () {
            mainDocument.element('w:pStyle', nest: () {
              mainDocument.attribute('w:val', 'Title');
            });
          });
          mainDocument.element('w:r', nest: () {
            mainDocument.element('w:t', nest: 'Transcription');
          });
        });
        
        if (includeTimestamps && transcriptionData.containsKey('segments')) {
          final segments = transcriptionData['segments'] as List<dynamic>;
          
          for (final segment in segments) {
            final timestamp = _formatTimestamp(segment['start'] as int);
            final confidence = segment['confidence'] as double;
            
            mainDocument.element('w:p', nest: () {
              // Timestamp
              if (includeTimestamps) {
                mainDocument.element('w:r', nest: () {
                  mainDocument.element('w:rPr', nest: () {
                    mainDocument.element('w:b');
                    mainDocument.element('w:color', nest: () {
                      mainDocument.attribute('w:val', '0000FF');
                    });
                  });
                  mainDocument.element('w:t', nest: '[$timestamp]');
                });
              }
              
              // Confidence
              if (includeConfidence) {
                mainDocument.element('w:r', nest: () {
                  mainDocument.element('w:rPr', nest: () {
                    mainDocument.element('w:i');
                    mainDocument.element('w:color', nest: () {
                      mainDocument.attribute('w:val', '808080');
                    });
                  });
                  mainDocument.element('w:t', nest: ' (${(confidence * 100).toInt()}%)');
                });
              }
              
              // Text content
              mainDocument.element('w:r', nest: () {
                mainDocument.element('w:t', nest: ' ${segment['text']}');
              });
            });
          }
        } else {
          // Without timestamps, just add the full text
          mainDocument.element('w:p', nest: () {
            mainDocument.element('w:r', nest: () {
              mainDocument.element('w:t', nest: transcriptionData['transcription']);
            });
          });
        }
      });
    });
    
    // For a real implementation, you would now create a proper DOCX archive
    // with the XML document and the necessary supporting files
    
    // For this demo, we'll just save the XML content
    final file = File(path);
    await file.writeAsString(mainDocument.buildDocument().toString());
    
    return path;
  }
} 