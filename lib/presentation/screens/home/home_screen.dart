import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../../../data/services/openai_service.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../../data/services/firebase_service.dart';
import '../../widgets/recent_recordings_sheet.dart';
import '../ai/transcription_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [];  // Changed to dynamic
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  
  // User state
  String _username = 'User';
  String? _userAvatarUrl;
  
  // UI state
  bool _isTyping = false;
  bool _isUserTyping = false;
  bool _isSearchMode = false;
  String _searchQuery = '';
  File? _selectedImage;
  final bool _isRecording = false;
  bool _showScrollToBottom = false;
  bool _isAttachingImage = false;
  
  // Animation controllers
  late AnimationController _typingAnimationController;
  late AnimationController _newMessageAnimationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
  // Screen animations
  late AnimationController _screenAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerAnimation;
  late Animation<double> _chatContainerAnimation;
  late Animation<double> _inputFieldAnimation;
  late Animation<double> _bottomNavAnimation;
  
  // Hover states
  final Map<String, bool> _hoverStates = {};
  
  // List of features to showcase in the empty state
  final List<Map<String, dynamic>> _features = [
    {
      'icon': Icons.mic,
      'title': 'Voice Recording',
      'description': 'Record your voice and get instant transcriptions',
    },
    {
      'icon': Icons.chat_bubble,
      'title': 'AI Assistant',
      'description': 'Ask questions and get intelligent responses',
    },
    {
      'icon': Icons.image,
      'title': 'Image Analysis',
      'description': 'Share images for AI-powered analysis and insights',
    },
  ];

  // Add greeting based on time of day
  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    
    // Remove the short delay and make the welcome message permanent
    _addBotMessage(
      "Hello, $_username! I'm CAIPO, your AI assistant. How can I help you today?",
      suggestions: [
        "Tell me about yourself",
        "What can you help me with?",
        "How do I record audio?"
      ]
    );
  }
  
  void _initAnimations() {
    // Typing indicator animation
    _typingAnimationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    
    // New message animation
    _newMessageAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // FAB animation for scroll to bottom
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    
    // Screen animations
    _screenAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _screenAnimationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Create staggered animations
    _headerAnimation = createStaggeredAnimation(
      begin: 0, 
      end: 1, 
      startInterval: 0.0, 
      endInterval: 0.6, 
      curve: Curves.easeOutCubic
    );
    
    _chatContainerAnimation = createStaggeredAnimation(
      begin: 0, 
      end: 1, 
      startInterval: 0.2, 
      endInterval: 0.7, 
      curve: Curves.easeOutCubic
    );
    
    _inputFieldAnimation = createStaggeredAnimation(
      begin: 0, 
      end: 1, 
      startInterval: 0.4, 
      endInterval: 0.8, 
      curve: Curves.easeOutCubic
    );
    
    _bottomNavAnimation = createStaggeredAnimation(
      begin: 0, 
      end: 1, 
      startInterval: 0.6, 
      endInterval: 0.9, 
      curve: Curves.easeOutCubic
    );
    
    _screenAnimationController.forward();
  }
  
  Future<void> _loadUserData() async {
    try {
      // Get current user data
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        setState(() {
          _username = currentUser.displayName ?? 'User';
          _userAvatarUrl = currentUser.photoURL;
        });
      }
    } catch (e) {
      // Fallback to default values on error
      debugPrint('Error loading user data: $e');
    }
  }
  
  void _onTextChanged() {
    setState(() {
      _isUserTyping = _messageController.text.isNotEmpty;
    });
  }
  
  void _onScroll() {
    final showButton = _scrollController.position.pixels < 
        _scrollController.position.maxScrollExtent - 300;
    
    if (showButton != _showScrollToBottom) {
      setState(() {
        _showScrollToBottom = showButton;
      });
      
      if (showButton) {
        _fabAnimationController.forward();
      } else {
        _fabAnimationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    _newMessageAnimationController.dispose();
    _fabAnimationController.dispose();
    _screenAnimationController.dispose();
    super.dispose();
  }

  // Add bot message with timestamp and suggestions
  void _addBotMessage(String message, {List<String>? suggestions, String? imageUrl}) {
    final timestamp = DateTime.now();
    setState(() {
      _messages.add({
        'sender': 'AI',
        'message': message,
        'timestamp': timestamp,
        'suggestions': suggestions,
        'imageUrl': imageUrl,
        'isNew': true,
      });
    });
    
    // Animate new message
    _newMessageAnimationController.reset();
    _newMessageAnimationController.forward();
    
    // Mark message as not new after animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          for (var msg in _messages) {
            msg['isNew'] = false;
          }
        });
      }
    });
    
    _scrollToBottom();
  }
  
  // Add user message
  void _addUserMessage(String message, {File? image}) {
    final timestamp = DateTime.now();
    setState(() {
      _messages.add({
        'sender': 'You',
        'message': message,
        'timestamp': timestamp,
        'image': image,
        'isNew': true,
      });
      
      if (image != null) {
        _isAttachingImage = false;
      }
    });
    
    // Animate new message
    _newMessageAnimationController.reset();
    _newMessageAnimationController.forward();
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage({String? text}) async {
    final userMessage = text ?? _messageController.text;
    
    // Don't send if empty message and no image
    if (userMessage.isEmpty && _selectedImage == null) return;
    
    // Add user message to chat
    _addUserMessage(userMessage, image: _selectedImage);
    
    // Clear input
    _messageController.clear();
    setState(() {
      _isTyping = true;
    });
    
    // Store image temporarily before clearing
    final imageFile = _selectedImage;
    setState(() {
      _selectedImage = null;
    });

    try {
      final openAIService = OpenAIService();
      
      String aiPrompt = userMessage;
      
      // If image was attached, include description
      if (imageFile != null) {
        aiPrompt = "The user has sent an image. $aiPrompt";
        // In a real app, you'd use image analysis API here
      }
      
      // Add delay for a more natural feel
      await Future.delayed(const Duration(milliseconds: 800));
      
      final aiResponse = await openAIService.queryOpenAI(aiPrompt);
      
      // Generate suggestions based on the context
      List<String> suggestions = [];
      
      if (aiResponse.contains("recording") || aiResponse.contains("audio")) {
        suggestions = ["How to start recording?", "Can you transcribe my audio?", "What formats do you support?"];
      } else if (aiResponse.contains("help")) {
        suggestions = ["Show me all features", "How to use AI?", "Can you explain CAIPO?"];
      } else {
        suggestions = ["Tell me more", "How does this work?", "What else can you do?"];
      }
      
      if (mounted) {
        _addBotMessage(aiResponse, suggestions: suggestions);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        _addBotMessage(
          "I'm sorry, I'm having trouble connecting. Please try again later.",
          suggestions: ["Try again", "Help", "Settings"]
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTyping = false);
      }
    }
  }
  
  // Toggle search mode
  void _toggleSearchMode() {
    setState(() {
      _isSearchMode = !_isSearchMode;
      _searchQuery = '';
    });
  }
  
  // Filter messages based on search query
  List<Map<String, dynamic>> get _filteredMessages {
    if (_searchQuery.isEmpty) return _messages;
    
    return _messages.where((message) {
      final msg = message['message'].toString().toLowerCase();
      return msg.contains(_searchQuery.toLowerCase());
    }).toList();
  }
  
  // Clear chat history
  Future<void> _clearChat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear all messages? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      setState(() {
        _messages.clear();
      });
      
      // Show welcome message again
      Future.delayed(const Duration(milliseconds: 500), () {
        _addBotMessage(
          "Chat cleared. How can I help you today?",
          suggestions: ["New conversation", "Help me with something", "What can you do?"]
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return GradientScaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: _screenAnimationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _chatContainerAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - _chatContainerAnimation.value)),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1E1E2E) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: isDarkMode ? Colors.black38 : Colors.grey.shade300,
                                  spreadRadius: 1,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                _buildChatHeader(isDarkMode),
                                Expanded(
                                  child: _messages.isEmpty && !_isTyping
                                      ? _buildEmptyState(isDarkMode)
                                      : _buildMessageList(isDarkMode),
                                ),
                                if (_selectedImage != null) _buildImagePreview(),
                                AnimatedBuilder(
                                  animation: _screenAnimationController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _inputFieldAnimation.value,
                                      child: Transform.translate(
                                        offset: Offset(0, 20 * (1 - _inputFieldAnimation.value)),
                                        child: _buildInputField(isDarkMode),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Scroll to bottom button
                  if (_showScrollToBottom)
                    Positioned(
                      right: 16,
                      bottom: 80,
                      child: ScaleTransition(
                        scale: _fabAnimation,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.blueAccent.withOpacity(0.8),
                          onPressed: _scrollToBottom,
                          child: const Icon(Icons.arrow_downward, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: _screenAnimationController,
        builder: (context, child) {
          return Opacity(
            opacity: _bottomNavAnimation.value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - _bottomNavAnimation.value)),
              child: _buildBottomNavBar(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    return AnimatedBuilder(
      animation: _screenAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _headerAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _headerAnimation.value)),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 16.0),
              decoration: BoxDecoration(
                gradient: themeProvider.headerGradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_greeting, $_username',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.95),
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: const Offset(0, 1),
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('EEEE, MMMM d').format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 0.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.25),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white.withOpacity(0.3),
                        backgroundImage: _userAvatarUrl != null
                            ? NetworkImage(_userAvatarUrl!)
                            : null,
                        child: _userAvatarUrl == null
                            ? Icon(
                                Icons.person,
                                color: Colors.white.withOpacity(0.9),
                                size: 24,
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildChatHeader(bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.2),
                ]
              : [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.85),
                ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? Colors.grey.shade800
                : Colors.grey.shade300,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isSearchMode
          ? _buildSearchField(isDarkMode)
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: themeProvider.getSettingsIconDecoration(isActive: true),
                  child: Icon(
                    Icons.smart_toy_outlined,
                    color: themeProvider.accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAIPO Assistant',
                      style: themeProvider.settingsTitleStyle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeProvider.primaryTextColor,
                      ),
                    ),
                    Text(
                      'AI-powered companion',
                      style: themeProvider.settingsDescriptionStyle.copyWith(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                MouseRegion(
                  onEnter: (_) => setState(() => _hoverStates['search'] = true),
                  onExit: (_) => setState(() => _hoverStates['search'] = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _hoverStates['search'] == true
                          ? themeProvider.accentColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isSearchMode ? Icons.close : Icons.search,
                        size: 22,
                        color: _hoverStates['search'] == true
                            ? themeProvider.accentColor
                            : themeProvider.secondaryIconColor,
                      ),
                      onPressed: _toggleSearchMode,
                      tooltip: _isSearchMode ? 'Exit Search' : 'Search Messages',
                    ),
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _hoverStates['more'] = true),
                  onExit: (_) => setState(() => _hoverStates['more'] = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _hoverStates['more'] == true
                          ? themeProvider.accentColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.more_vert,
                        size: 22,
                        color: _hoverStates['more'] == true
                            ? themeProvider.accentColor
                            : themeProvider.secondaryIconColor,
                      ),
                      onPressed: () {
                        _showChatOptions();
                      },
                      tooltip: 'More Options',
                    ),
                  ),
                ),
              ],
            ),
    );
  }
  
  Widget _buildSearchField(bool isDarkMode) {
    return TextField(
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search messages...',
        border: InputBorder.none,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          icon: const Icon(Icons.close),
          onPressed: _toggleSearchMode,
        ),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }
  
  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Export Chat'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export functionality coming soon'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear Chat'),
              onTap: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help'),
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog();
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CAIPO Assistant Help'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'CAIPO is your AI assistant that can help with:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildHelpItem('Voice Recording & Transcription', Icons.mic),
              _buildHelpItem('Answering Questions', Icons.question_answer),
              _buildHelpItem('Image Analysis', Icons.image),
              _buildHelpItem('Text Generation', Icons.text_fields),
              const SizedBox(height: 12),
              const Text(
                'Try asking me anything or use the microphone icon to record audio.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHelpItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _typingIndicator() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2E2E3E) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.blueAccent,
              radius: 12,
              child: const Text(
                'AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SpinKitThreeBounce(
              color: isDarkMode 
                  ? Colors.blueAccent.withAlpha(179)
                  : Colors.blueAccent,
              size: 14.0,
              controller: _typingAnimationController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    return BottomNavigationBar(
      backgroundColor: isDarkMode 
          ? Colors.black.withAlpha(204)
          : Colors.white,
      selectedItemColor: Colors.blueAccent.withAlpha(isDarkMode ? 230 : 255),
      unselectedItemColor: isDarkMode 
          ? Colors.grey.shade500 
          : Colors.grey.shade600,
      currentIndex: 0,
      onTap: (index) async {
        switch (index) {
          case 1:
            Navigator.pushNamed(context, '/record');
            break;
          case 2:
            Navigator.pushNamed(context, '/settings');
            break;
          case 3:
            // Show confirmation dialog before logout
            final shouldLogout = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );
            
            if (shouldLogout == true) {
              await FirebaseService.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context, 
                  '/auth', 
                  (route) => false
                );
              }
            }
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble),
          label: "Chat",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.mic),
          label: "Record",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: "Settings",
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout),
          label: "Logout",
        ),
      ],
    );
  }

  Widget _buildInputField(bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.black.withOpacity(0.3) 
            : Colors.white.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: isDarkMode 
                ? Colors.grey.shade800.withOpacity(0.7) 
                : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: isDarkMode 
                ? themeProvider.accentColor.withOpacity(0.8) 
                : themeProvider.accentColor,
            onPressed: _handleAttachmentPressed,
            tooltip: 'Add attachment',
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: "Message CAIPO...",
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                  fontSize: 15,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode 
                    ? Colors.grey.shade900.withOpacity(0.6) 
                    : Colors.grey.shade100.withOpacity(0.8),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: _isUserTyping
                    ? IconButton(
                        icon: Icon(
                          Icons.close, 
                          size: 18,
                          color: isDarkMode 
                              ? Colors.grey.shade400 
                              : Colors.grey.shade600,
                        ),
                        onPressed: () {
                          _messageController.clear();
                          setState(() {
                            _isUserTyping = false;
                          });
                        },
                      )
                    : null,
              ),
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _isUserTyping || _isAttachingImage
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          themeProvider.accentColor,
                          themeProvider.accentColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: themeProvider.accentColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 22),
                      onPressed: _sendMessage,
                      tooltip: 'Send message',
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(),
                      splashRadius: 24,
                    ),
                  )
                : _buildTranscriptionButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionButton() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverStates['mic'] = true),
      onExit: (_) => setState(() => _hoverStates['mic'] = false),
      child: GestureDetector(
        onTap: () {
          Navigator.pushNamed(context, '/record');
        },
        onLongPress: () {
          _showTranscriptionOptions();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isRecording
                  ? [Colors.red, Colors.red.shade700]
                  : _hoverStates['mic'] == true
                      ? [Colors.blue.shade400, Colors.blue.shade700]
                      : [Colors.blueAccent, Colors.blue.shade700],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (_isRecording ? Colors.red : Colors.blueAccent).withOpacity(
                  _hoverStates['mic'] == true ? 0.4 : 0.3
                ),
                spreadRadius: _hoverStates['mic'] == true ? 3 : 2,
                blurRadius: _hoverStates['mic'] == true ? 10 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _isRecording ? Icons.mic : Icons.mic_none,
            color: Colors.white,
            size: _hoverStates['mic'] == true ? 26 : 24,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList(bool isDarkMode) {
    final messages = _isSearchMode ? _filteredMessages : _messages;
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && _isTyping) {
          return _typingIndicator();
        }
        
        final message = messages[index];
        final isUser = message['sender'] == 'You';
        final isNew = message['isNew'] as bool? ?? false;
        
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isNew ? 0.0 : 1.0,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(isUser ? 20 * (1 - value) : -20 * (1 - value), 0),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isUser) ...[
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blueAccent,
                          child: const Text(
                            'AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        DateFormat('h:mm a').format(message['timestamp'] as DateTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                MouseRegion(
                  onEnter: (_) => setState(() => _hoverStates['msg_$index'] = true),
                  onExit: (_) => setState(() => _hoverStates['msg_$index'] = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(
                      left: isUser ? 64.0 : 48.0,
                      right: isUser ? 12.0 : 64.0,
                      bottom: 8.0,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isUser
                            ? _hoverStates['msg_$index'] == true
                                ? [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                  ]
                                : [
                                    Theme.of(context).colorScheme.primary.withOpacity(0.9),
                                    Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                  ]
                            : isDarkMode
                                ? _hoverStates['msg_$index'] == true
                                    ? [
                                        const Color(0xFF252045).withOpacity(0.9),
                                        const Color(0xFF1E1A33).withOpacity(0.7),
                                      ]
                                    : [
                                        const Color(0xFF1E1A33).withOpacity(0.7),
                                        const Color(0xFF1E1A33).withOpacity(0.5),
                                      ]
                                : _hoverStates['msg_$index'] == true
                                    ? [
                                        Colors.white,
                                        Colors.white.withOpacity(0.9),
                                      ]
                                    : [
                                        Colors.white.withOpacity(0.9),
                                        Colors.white.withOpacity(0.8),
                                      ],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(isUser ? 18.0 : 4.0),
                        topRight: Radius.circular(isUser ? 4.0 : 18.0),
                        bottomLeft: const Radius.circular(18.0),
                        bottomRight: const Radius.circular(18.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isUser
                              ? Theme.of(context).colorScheme.primary.withOpacity(_hoverStates['msg_$index'] == true ? 0.3 : 0.2)
                              : Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                          blurRadius: _hoverStates['msg_$index'] == true ? 8 : 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                      border: Border.all(
                        color: isUser
                            ? Colors.transparent
                            : isDarkMode
                                ? Colors.grey.shade800.withOpacity(_hoverStates['msg_$index'] == true ? 0.7 : 0.5)
                                : Colors.grey.shade300,
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message['image'] != null)
                          Container(
                            height: 200,
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 8.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(message['image'] as File),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        Text(
                          message['message'] as String,
                          style: TextStyle(
                            color: isUser
                                ? Colors.white
                                : isDarkMode
                                    ? Colors.white.withOpacity(0.95)
                                    : Colors.black87,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        if (!isUser && (message['suggestions'] as List<String>?)?.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (message['suggestions'] as List<String>).map((suggestion) => MouseRegion(
                              onEnter: (_) => setState(() => _hoverStates['suggestion_$suggestion'] = true),
                              onExit: (_) => setState(() => _hoverStates['suggestion_$suggestion'] = false),
                              child: GestureDetector(
                                onTap: () => _sendMessage(text: suggestion),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _hoverStates['suggestion_$suggestion'] == true
                                          ? isDarkMode
                                              ? [
                                                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                ]
                                              : [
                                                  Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                                  Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                                ]
                                          : isDarkMode
                                              ? [
                                                  Colors.grey.shade800.withOpacity(0.6),
                                                  Colors.grey.shade900.withOpacity(0.4),
                                                ]
                                              : [
                                                  Colors.grey.shade100,
                                                  Colors.grey.shade50,
                                                ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: _hoverStates['suggestion_$suggestion'] == true
                                        ? [
                                            BoxShadow(
                                              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                              blurRadius: 4,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 1),
                                            ),
                                          ]
                                        : [],
                                    border: Border.all(
                                      color: isDarkMode
                                          ? _hoverStates['suggestion_$suggestion'] == true
                                              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                                              : Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                          : _hoverStates['suggestion_$suggestion'] == true
                                              ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                              : Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    suggestion,
                                    style: TextStyle(
                                      color: _hoverStates['suggestion_$suggestion'] == true
                                          ? Theme.of(context).colorScheme.primary
                                          : isDarkMode
                                              ? Colors.grey.shade300
                                              : Colors.grey.shade700,
                                      fontSize: 14,
                                      fontWeight: _hoverStates['suggestion_$suggestion'] == true
                                          ? FontWeight.w500
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Add method to handle attachments
  void _handleAttachmentPressed() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
              ListTile(
                leading: const Icon(Icons.mic),
                title: const Text('Voice Message'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/record');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Add image picking methods
  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }
  
  Future<void> _takePicture() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome to CAIPO Assistant',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'I can help you with various tasks. Here are some features:',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            ..._features.asMap().entries.map((entry) {
              final index = entry.key;
              final feature = entry.value;
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: Duration(milliseconds: 600 + (index * 200)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(50 * (1 - value), 0),
                      child: child,
                    ),
                  );
                },
                child: MouseRegion(
                  onEnter: (_) => setState(() => _hoverStates['feature_$index'] = true),
                  onExit: (_) => setState(() => _hoverStates['feature_$index'] = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 24.0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _hoverStates['feature_$index'] == true
                            ? isDarkMode
                                ? [
                                    Colors.grey.shade800.withOpacity(0.7),
                                    Colors.grey.shade900.withOpacity(0.5),
                                  ]
                                : [
                                    Colors.white,
                                    Colors.grey.shade100,
                                  ]
                            : isDarkMode
                                ? [
                                    Colors.grey.shade900.withOpacity(0.3),
                                    Colors.grey.shade900.withOpacity(0.1),
                                  ]
                                : [
                                    Colors.white.withOpacity(0.7),
                                    Colors.white.withOpacity(0.5),
                                  ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(_hoverStates['feature_$index'] == true ? 0.1 : 0.05),
                          blurRadius: _hoverStates['feature_$index'] == true ? 8 : 4,
                          spreadRadius: _hoverStates['feature_$index'] == true ? 1 : 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      border: Border.all(
                        color: _hoverStates['feature_$index'] == true
                            ? Colors.blueAccent.withOpacity(0.3)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.blueAccent.withOpacity(_hoverStates['feature_$index'] == true ? 0.2 : 0.1),
                                Colors.blueAccent.withOpacity(_hoverStates['feature_$index'] == true ? 0.1 : 0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _hoverStates['feature_$index'] == true
                                ? [
                                    BoxShadow(
                                      color: Colors.blueAccent.withOpacity(0.2),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(
                            feature['icon'] as IconData,
                            color: Colors.blueAccent,
                            size: _hoverStates['feature_$index'] == true ? 30 : 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                feature['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: _hoverStates['feature_$index'] == true
                                      ? isDarkMode ? Colors.white : Colors.black
                                      : isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                feature['description'] as String,
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                  fontSize: 14,
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
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox.shrink();
    
    return Container(
      height: 100,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: FileImage(_selectedImage!),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 4,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              radius: 15,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 18, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _isAttachingImage = false;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showTranscriptionOptions() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        controller: DraggableScrollableController(),
        builder: (context, scrollController) => RecentRecordingsSheet(
          scrollController: scrollController,
          onRecordingSelected: (path) => _handleRecordingSelected(path),
        ),
      ),
    );
  }

  void _handleRecordingSelected(String path) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TranscriptionScreen(audioFilePath: path),
      ),
    );
  }

  // Helper method to create staggered animations
  Animation<double> createStaggeredAnimation({
    required double begin,
    required double end,
    required double startInterval,
    required double endInterval,
    Curve curve = Curves.easeOut,
  }) {
    return Tween<double>(begin: begin, end: end).animate(
      CurvedAnimation(
        parent: _screenAnimationController,
        curve: Interval(startInterval, endInterval, curve: curve),
      ),
    );
  }
}