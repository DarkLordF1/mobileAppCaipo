import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/gradient_scaffold.dart';
import 'package:flutter/services.dart';

class OpenAIService {
  final String apiUrl = "https://api.openai.com/v1/chat/completions";
  final String transcriptionUrl = "https://api.openai.com/v1/audio/transcriptions";
  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  Future<String> queryOpenAI(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "gpt-4", // Use "gpt-3.5-turbo" if you want a cheaper option
          "messages": [
            {"role": "system", "content": "You are a helpful AI assistant."},
            {"role": "user", "content": userMessage},
          ],
          "max_tokens": 200,
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData["choices"][0]["message"]["content"].toString();
      } else {
        return "Error: ${response.statusCode}, ${response.body}";
      }
    } catch (e) {
      return "Failed to connect to OpenAI: $e";
    }
  }

  Future<String> transcribeAudio(String audioFilePath) async {
    try {
      final file = File(audioFilePath);
      final bytes = await file.readAsBytes();
      
      final request = http.MultipartRequest('POST', Uri.parse(transcriptionUrl))
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: 'audio.m4a',
          ),
        )
        ..fields['model'] = 'whisper-1';

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        return data['text'];
      } else {
        throw Exception('Failed to transcribe audio: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error transcribing audio: $e');
    }
  }
}

/// A UI wrapper for the OpenAI service
class OpenAIScreen extends StatefulWidget {
  const OpenAIScreen({super.key});

  @override
  State<OpenAIScreen> createState() => _OpenAIScreenState();
}

class _OpenAIScreenState extends State<OpenAIScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OpenAIService _openAIService = OpenAIService();
  
  String _response = '';
  bool _isLoading = false;
  bool _hasCopied = false;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Hover states
  final Map<String, bool> _hoverStates = {};
  bool _isSendHovered = false;
  bool _isClearHovered = false;
  bool _isCopyHovered = false;
  
  @override
  void initState() {
    super.initState();
    _initAnimations();
  }
  
  void _initAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _sendPrompt() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _openAIService.queryOpenAI(prompt);
      setState(() {
        _response = response;
        _isLoading = false;
      });
      
      // Scroll to bottom to show response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _response = "Error: $e";
        _isLoading = false;
      });
    }
  }
  
  void _clearPrompt() {
    setState(() {
      _promptController.clear();
      _response = '';
    });
  }
  
  void _copyResponseToClipboard() {
    if (_response.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _response));
      setState(() {
        _hasCopied = true;
      });
      
      // Reset the copied state after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _hasCopied = false;
          });
        }
      });
      
      // Show a snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Response copied to clipboard'),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          "AI Assistant",
          style: themeProvider.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: themeProvider.primaryTextColor,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_response.isNotEmpty)
            MouseRegion(
              onEnter: (_) => setState(() => _isCopyHovered = true),
              onExit: (_) => setState(() => _isCopyHovered = false),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 1.0,
                  end: _isCopyHovered ? 1.1 : 1.0,
                ),
                duration: const Duration(milliseconds: 200),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: _hasCopied
                        ? Icon(
                            Icons.check_circle,
                            key: const ValueKey('check'),
                            color: Colors.green,
                          )
                        : Icon(
                            Icons.copy,
                            key: const ValueKey('copy'),
                            color: themeProvider.primaryTextColor,
                          ),
                  ),
                  onPressed: _copyResponseToClipboard,
                  tooltip: 'Copy response',
                ),
              ),
            ),
          MouseRegion(
            onEnter: (_) => setState(() => _isClearHovered = true),
            onExit: (_) => setState(() => _isClearHovered = false),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 1.0,
                end: _isClearHovered ? 1.1 : 1.0,
              ),
              duration: const Duration(milliseconds: 200),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: themeProvider.primaryTextColor,
                ),
                onPressed: _clearPrompt,
                tooltip: 'Clear',
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDarkMode, themeProvider),
                  Expanded(
                    child: _buildResponseArea(isDarkMode, themeProvider),
                  ),
                  const SizedBox(height: 16),
                  _buildPromptInput(isDarkMode, themeProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildHeader(bool isDarkMode, ThemeProvider themeProvider) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: themeProvider.accentColor.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: themeProvider.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CAIPO AI Assistant",
                      style: themeProvider.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Ask me anything and I'll do my best to help",
                      style: themeProvider.bodyMedium.copyWith(
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildResponseArea(bool isDarkMode, ThemeProvider themeProvider) {
    if (_response.isEmpty && !_isLoading) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_fadeAnimation),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.9, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: themeProvider.accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: themeProvider.accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Type a prompt to get started',
                  style: themeProvider.headlineSmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ask questions, get information, or request creative content',
                  style: themeProvider.bodyMedium.copyWith(
                    color: themeProvider.secondaryTextColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_fadeAnimation),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoverStates['response'] = true),
          onExit: (_) => setState(() => _hoverStates['response'] = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[900]!.withOpacity(_hoverStates['response'] == true ? 0.9 : 0.7)
                  : Colors.white.withOpacity(_hoverStates['response'] == true ? 1.0 : 0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_hoverStates['response'] == true ? 0.2 : 0.1),
                  blurRadius: _hoverStates['response'] == true ? 12 : 8,
                  spreadRadius: _hoverStates['response'] == true ? 2 : 1,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: themeProvider.accentColor.withOpacity(_hoverStates['response'] == true ? 0.3 : 0.1),
                width: _hoverStates['response'] == true ? 2 : 1,
              ),
            ),
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: 2 * 3.14159),
                          duration: const Duration(seconds: 2),
                          builder: (context, value, child) {
                            return Transform.rotate(
                              angle: value,
                              child: child,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: themeProvider.accentColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.settings,
                              color: themeProvider.accentColor,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Thinking...',
                          style: themeProvider.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'CAIPO is processing your request',
                          style: themeProvider.bodyMedium.copyWith(
                            color: themeProvider.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: themeProvider.accentColor.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.smart_toy,
                                color: themeProvider.accentColor,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'CAIPO AI',
                              style: themeProvider.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          _response,
                          style: themeProvider.bodyLarge.copyWith(
                            height: 1.5,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPromptInput(bool isDarkMode, ThemeProvider themeProvider) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      )),
      child: FadeTransition(
        opacity: CurvedAnimation(
          parent: _animationController,
          curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
        ),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoverStates['input'] = true),
          onExit: (_) => setState(() => _hoverStates['input'] = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.grey[900]!.withOpacity(_hoverStates['input'] == true ? 0.9 : 0.7)
                  : Colors.white.withOpacity(_hoverStates['input'] == true ? 1.0 : 0.9),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(_hoverStates['input'] == true ? 0.2 : 0.1),
                  blurRadius: _hoverStates['input'] == true ? 12 : 8,
                  spreadRadius: _hoverStates['input'] == true ? 2 : 1,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: themeProvider.accentColor.withOpacity(_hoverStates['input'] == true ? 0.3 : 0.1),
                width: _hoverStates['input'] == true ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    decoration: InputDecoration(
                      hintText: 'Type your prompt here...',
                      hintStyle: TextStyle(
                        color: themeProvider.secondaryTextColor.withOpacity(0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: themeProvider.bodyLarge,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    onSubmitted: (_) => _sendPrompt(),
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _isSendHovered = true),
                  onExit: (_) => setState(() => _isSendHovered = false),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 1.0,
                      end: _isSendHovered ? 1.1 : 1.0,
                    ),
                    duration: const Duration(milliseconds: 200),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: themeProvider.accentColor,
                      ),
                      onPressed: _isLoading ? null : _sendPrompt,
                      tooltip: 'Send prompt',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
