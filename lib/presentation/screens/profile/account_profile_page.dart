import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/gradient_scaffold.dart';
import '../../../data/services/firebase_service.dart';
import 'dart:io';

class AccountProfilePage extends StatefulWidget {
  const AccountProfilePage({super.key});

  @override
  _AccountProfilePageState createState() => _AccountProfilePageState();
}

class _AccountProfilePageState extends State<AccountProfilePage> with TickerProviderStateMixin {
  // User profile data - now initialized as null or empty
  String _username = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userLocation = '';
  String _joinDate = '';
  String? _photoURL;
  bool _isVerified = false;
  
  // Profile image
  File? _selectedImage;
  bool _isImageLoading = false;
  bool _isLoadingProfile = true;
  
  // For edit mode
  bool _isEditMode = false;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  bool _isProcessing = false;
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // For hover effects
  int? _hoveredOptionIndex;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    // Load user data
    _loadUserData();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }
  
  // Handle profile image selection
  Future<void> _pickImage() async {
    setState(() => _isImageLoading = true);
    
    try {
      final ImagePicker picker = ImagePicker();
      
      // Show option to choose camera or gallery
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: Text('Take a photo', style: themeProvider.bodyLarge),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.green),
                  title: Text('Choose from gallery', style: themeProvider.bodyLarge),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );
      
      if (source == null) {
        setState(() => _isImageLoading = false);
        return;
      }
      
      final XFile? image = await picker.pickImage(
        source: source,
        maxHeight: 512,
        maxWidth: 512,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImageLoading = false);
      }
    }
  }
  
  // Toggle edit mode
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        // Reset text fields when canceling edit mode
        _nameController.text = _username;
        _phoneController.text = _userPhone;
        _locationController.text = _userLocation;
      }
    });
  }
  
  // Save profile changes
  Future<void> _saveChanges() async {
    setState(() {
      _isProcessing = true;
    });
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('User not authenticated');
        return;
      }
      
      // Update display name in Firebase Auth
      await currentUser.updateDisplayName(_nameController.text.trim());
      
      // Update profile picture if selected
      if (_selectedImage != null) {
        // In a real app, you would upload to Firebase Storage and get a URL
        // For this example, we'll skip this step
        // final String photoUrl = await uploadProfileImage(_selectedImage!, currentUser.uid);
        // await currentUser.updatePhotoURL(photoUrl);
      }
      
      // Update additional data in Firestore
      final success = await FirebaseService.updateUserProfile(
        currentUser.uid,
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _locationController.text.trim(),
      );
      
      if (!success) {
        // Show a warning that Firestore data wasn't saved, but Auth data was
        _showWarningSnackBar('Profile updated in Auth but Firestore data could not be saved');
      } else {
        // Update local state
        setState(() {
          _username = _nameController.text.trim();
          _userPhone = _phoneController.text.trim();
          _userLocation = _locationController.text.trim();
          _isEditMode = false;
        });
        
        _showSuccessSnackBar('Profile updated successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Error updating profile: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  // Show confirmation dialog for signing out
  Future<void> _showSignOutDialog() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.red, size: 24),
            const SizedBox(width: 16),
            const Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out? You will need to log in again to access your account.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: themeProvider.textButtonStyle,
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('SIGN OUT'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
      ),
    );
    
    if (confirmed == true) {
      try {
        await FirebaseService.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have been signed out'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error signing out: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
  
  // Handle navigation to change password screen
  void _navigateToChangePassword() {
    // In a real app, navigate to change password screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Change password screen would open here'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Load user data from Firebase
  Future<void> _loadUserData() async {
    setState(() => _isLoadingProfile = true);
    
    try {
      // Get current Firebase user
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Basic data from Firebase Auth
        setState(() {
          _username = currentUser.displayName ?? 'User';
          _userEmail = currentUser.email ?? '';
          _photoURL = currentUser.photoURL;
          _isVerified = currentUser.emailVerified;
          
          // Initialize controllers with current values
          _nameController.text = _username;
        });
        
        // Try to get additional data from Firestore
        try {
          final userData = await FirebaseService.getUserData(currentUser.uid);
          
          if (userData != null) {
            setState(() {
              _userPhone = userData['phone'] ?? '';
              _locationController.text = userData['location'] ?? '';
              _phoneController.text = _userPhone;
              _userLocation = userData['location'] ?? '';
              
              // Format the creation timestamp or use the provided timestamp
              if (userData['createdAt'] != null) {
                final Timestamp createdAt = userData['createdAt'];
                final DateTime joinDateTime = createdAt.toDate();
                _joinDate = '${_getMonthName(joinDateTime.month)} ${joinDateTime.year}';
              } else {
                // Use Firebase Auth's creation time as fallback
                final DateTime? joinDateTime = currentUser.metadata.creationTime;
                if (joinDateTime != null) {
                  _joinDate = '${_getMonthName(joinDateTime.month)} ${joinDateTime.year}';
                } else {
                  _joinDate = 'Unknown';
                }
              }
            });
          } else {
            // If user document doesn't exist yet, initialize with defaults
            // and use the Auth creation time
            final DateTime? joinDateTime = currentUser.metadata.creationTime;
            if (joinDateTime != null) {
              setState(() {
                _joinDate = '${_getMonthName(joinDateTime.month)} ${joinDateTime.year}';
              });
            }
          }
        } catch (e) {
          print('Error loading additional user data: $e');
          
          // Still use what we have from Auth
          final DateTime? joinDateTime = currentUser.metadata.creationTime;
          if (joinDateTime != null) {
            setState(() {
              _joinDate = '${_getMonthName(joinDateTime.month)} ${joinDateTime.year}';
            });
          }
        }
      } else {
        // Not logged in - should not happen but handle gracefully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are not logged in. Please log in to view your profile.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate back to login screen
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
          }
        });
      }
    } catch (e) {
      // Handle auth errors
      print('Error loading user profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading your profile: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _animationController.forward();
        });
      }
    }
  }
  
  // Helper to get month name
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;
    
    return GradientScaffold(
      appBar: AppBar(
        title: Text(
          'Account & Profile',
          style: themeProvider.settingsHeaderStyle,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.primaryIconColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditMode ? Icons.close : Icons.edit,
              color: themeProvider.primaryIconColor,
            ),
            onPressed: _toggleEditMode,
            tooltip: _isEditMode ? 'Cancel' : 'Edit Profile',
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning banner with improved design
                Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.blue.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.withOpacity(0.2),
                              Colors.blue.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                        ),
                        child: Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Keep your profile information up to date to ensure the best experience.',
                          style: themeProvider.bodyMedium.copyWith(
                            color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Profile Picture Section with enhanced animations
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.scale(
                          scale: 0.8 + (0.2 * value),
                          child: Stack(
                            children: [
                              // Decorative background circle with gradient
                              Container(
                                height: 150,
                                width: 150,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: isDarkMode
                                        ? [
                                            themeProvider.accentColor.withOpacity(0.3),
                                            themeProvider.accentColor.withOpacity(0.1),
                                          ]
                                        : [
                                            themeProvider.accentColor.withOpacity(0.4),
                                            themeProvider.accentColor.withOpacity(0.2),
                                          ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: themeProvider.accentColor.withOpacity(0.2),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Profile picture with loading indicator
                              Container(
                                height: 140,
                                width: 140,
                                margin: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.white.withOpacity(0.3)
                                        : Colors.white.withOpacity(0.9),
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: _isImageLoading
                                    ? Center(
                                        child: SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(themeProvider.accentColor),
                                            strokeWidth: 3,
                                          ),
                                        ),
                                      )
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(70),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: isDarkMode
                                                ? Colors.grey.shade800
                                                : Colors.grey.shade200,
                                          ),
                                          child: _selectedImage != null
                                              ? Image.file(
                                                  _selectedImage!,
                                                  fit: BoxFit.cover,
                                                  width: 140,
                                                  height: 140,
                                                )
                                              : _photoURL != null
                                                  ? Image.network(
                                                      _photoURL!,
                                                      fit: BoxFit.cover,
                                                      width: 140,
                                                      height: 140,
                                                      loadingBuilder: (context, child, loadingProgress) {
                                                        if (loadingProgress == null) return child;
                                                        return Center(
                                                          child: CircularProgressIndicator(
                                                            value: loadingProgress.expectedTotalBytes != null
                                                                ? loadingProgress.cumulativeBytesLoaded /
                                                                    loadingProgress.expectedTotalBytes!
                                                                : null,
                                                            valueColor: AlwaysStoppedAnimation<Color>(
                                                                themeProvider.accentColor),
                                                            strokeWidth: 3,
                                                          ),
                                                        );
                                                      },
                                                    )
                                                  : Image.asset(
                                                      'assets/profile_placeholder.png',
                                                      fit: BoxFit.cover,
                                                      width: 140,
                                                      height: 140,
                                                    ),
                                        ),
                                      ),
                              ),
                              
                              // Edit button on the image with improved styling
                              if (_isEditMode)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: Container(
                                          height: 40,
                                          width: 40,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                themeProvider.accentColor,
                                                themeProvider.accentColor.withOpacity(0.8),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: themeProvider.accentColor.withOpacity(0.3),
                                                blurRadius: 8,
                                                spreadRadius: 1,
                                              ),
                                            ],
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.camera_alt, size: 20),
                                            color: Colors.white,
                                            padding: EdgeInsets.zero,
                                            onPressed: _pickImage,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Username display with verification badge
                if (!_isEditMode && _username.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _username,
                            style: themeProvider.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: themeProvider.primaryTextColor,
                            ),
                          ),
                          if (_isVerified)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Icon(
                                Icons.verified,
                                color: themeProvider.accentColor,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                
                // Email display when not in edit mode
                if (!_isEditMode && _userEmail.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _userEmail,
                        style: themeProvider.bodyMedium.copyWith(
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                // Personal Information Section
                _buildSectionHeader('Personal Information', isDarkMode),
                
                // Show different UI based on edit mode
                _isEditMode
                    ? _buildEditableProfileSection(isDarkMode)
                    : _buildProfileInfoSection(isDarkMode),
                
                const SizedBox(height: 24),
                
                // Account Management Section
                _buildSectionHeader('Account Management', isDarkMode),
                _buildProfileOption(
                  title: 'Change Password',
                  value: '••••••••',
                  icon: Icons.lock,
                  isDarkMode: isDarkMode,
                  onTap: _navigateToChangePassword,
                ),
                _buildProfileOption(
                  title: 'Privacy Settings',
                  value: 'Manage your data and privacy',
                  icon: Icons.security,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    Navigator.pushNamed(context, '/privacy');
                  },
                ),
                _buildProfileOption(
                  title: 'Connected Accounts',
                  value: 'Google, Facebook',
                  icon: Icons.link,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    // Navigate to connected accounts
                  },
                ),
                _buildProfileOption(
                  title: 'Subscription',
                  value: 'Premium Plan',
                  icon: Icons.card_membership,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    // Navigate to subscription page
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Support Section
                _buildSectionHeader('Support', isDarkMode),
                _buildProfileOption(
                  title: 'Help & Support',
                  value: 'Get help with the app',
                  icon: Icons.help_outline,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    // Navigate to help page
                  },
                ),
                _buildProfileOption(
                  title: 'About',
                  value: 'App version 1.0.0',
                  icon: Icons.info_outline,
                  isDarkMode: isDarkMode,
                  onTap: () {
                    // Navigate to about page
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Bottom action bar
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: themeProvider.settingsBottomBarDecoration,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: _showSignOutDialog,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('Sign Out'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                      if (_isEditMode)
                        ElevatedButton(
                          onPressed: _isProcessing ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.accentColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: themeProvider.accentColor.withOpacity(0.5),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                            'Save Changes',
                            style: themeProvider.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Account Age Info
                if (!_isEditMode)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Member since $_joinDate',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode 
                              ? themeProvider.secondaryTextColor
                              : themeProvider.primaryTextColor.withOpacity(0.6),
                        ),
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
  
  Widget _buildSectionHeader(String title, bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          themeProvider.accentColor.withOpacity(0.15),
                          themeProvider.accentColor.withOpacity(0.05),
                        ]
                      : [
                          themeProvider.accentColor.withOpacity(0.15),
                          themeProvider.accentColor.withOpacity(0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.accentColor.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          themeProvider.accentColor.withOpacity(0.2),
                          themeProvider.accentColor.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                    ),
                    child: Icon(
                      _getSectionIcon(title),
                      color: themeProvider.accentColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: themeProvider.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryTextColor,
                      letterSpacing: 0.5,
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
  
  IconData _getSectionIcon(String section) {
    switch (section.toLowerCase()) {
      case 'personal information':
        return Icons.person_outline;
      case 'account management':
        return Icons.admin_panel_settings_outlined;
      case 'support':
        return Icons.help_outline;
      default:
        return Icons.settings;
    }
  }
  
  Widget _buildProfileOption({
    required String title, 
    required String value, 
    required IconData icon, 
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final int optionIndex = _getOptionIndex(title);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredOptionIndex = optionIndex),
      onExit: (_) => setState(() => _hoveredOptionIndex = null),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, animValue, child) {
          return Opacity(
            opacity: animValue,
            child: Transform.translate(
              offset: Offset(0, 5 * (1 - animValue)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _hoveredOptionIndex == optionIndex
                        ? isDarkMode
                            ? [
                                themeProvider.accentColor.withOpacity(0.15),
                                themeProvider.accentColor.withOpacity(0.05),
                              ]
                            : [
                                themeProvider.accentColor.withOpacity(0.15),
                                themeProvider.accentColor.withOpacity(0.05),
                              ]
                        : isDarkMode
                            ? [
                                themeProvider.backgroundColor,
                                themeProvider.backgroundColor,
                              ]
                            : [
                                themeProvider.backgroundColor,
                                themeProvider.backgroundColor,
                              ],
                  ),
                  borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: _hoveredOptionIndex == optionIndex
                          ? themeProvider.accentColor.withOpacity(0.1)
                          : Colors.black.withOpacity(0.05),
                      blurRadius: _hoveredOptionIndex == optionIndex ? 8 : 5,
                      spreadRadius: _hoveredOptionIndex == optionIndex ? 1 : 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: _hoveredOptionIndex == optionIndex
                        ? themeProvider.accentColor.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                    splashColor: themeProvider.accentColor.withOpacity(0.1),
                    highlightColor: themeProvider.accentColor.withOpacity(0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  themeProvider.accentColor.withOpacity(0.2),
                                  themeProvider.accentColor.withOpacity(0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                              boxShadow: [
                                BoxShadow(
                                  color: themeProvider.accentColor.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              icon,
                              color: themeProvider.accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: themeProvider.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.primaryTextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  value,
                                  style: themeProvider.bodySmall.copyWith(
                                    color: themeProvider.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: _hoveredOptionIndex == optionIndex
                                ? themeProvider.accentColor
                                : themeProvider.secondaryTextColor.withOpacity(0.7),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  int _getOptionIndex(String title) {
    switch (title.toLowerCase()) {
      case 'username':
        return 0;
      case 'email':
        return 1;
      case 'phone':
        return 2;
      case 'location':
        return 3;
      case 'change password':
        return 4;
      case 'delete account':
        return 5;
      case 'help center':
        return 6;
      case 'privacy policy':
        return 7;
      default:
        return -1;
    }
  }
  
  Widget _buildProfileInfoSection(bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Column(
              children: [
                // User name with verified badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDarkMode
                          ? [
                              themeProvider.accentColor.withOpacity(0.15),
                              themeProvider.accentColor.withOpacity(0.05),
                            ]
                          : [
                              themeProvider.accentColor.withOpacity(0.1),
                              themeProvider.accentColor.withOpacity(0.02),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: themeProvider.accentColor.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                themeProvider.accentColor.withOpacity(0.2),
                                themeProvider.accentColor.withOpacity(0.1),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                            boxShadow: [
                              BoxShadow(
                                color: themeProvider.accentColor.withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.person,
                            color: themeProvider.accentColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _username,
                                    style: themeProvider.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: themeProvider.primaryTextColor,
                                    ),
                                  ),
                                  if (_isVerified) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            themeProvider.accentColor.withOpacity(0.7),
                                            themeProvider.accentColor.withOpacity(0.5),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.verified,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Verified',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _userEmail,
                                style: TextStyle(
                                  fontSize: 14,
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
                
                // Phone number
                _buildInfoItem(
                  icon: Icons.phone,
                  title: 'Phone',
                  value: _userPhone.isNotEmpty ? _userPhone : 'Not provided',
                  isDarkMode: isDarkMode,
                ),
                
                // Location
                _buildInfoItem(
                  icon: Icons.location_on,
                  title: 'Location',
                  value: _userLocation.isNotEmpty ? _userLocation : 'Not provided',
                  isDarkMode: isDarkMode,
                ),
                
                // Join date
                _buildInfoItem(
                  icon: Icons.calendar_today,
                  title: 'Member Since',
                  value: _joinDate,
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required bool isDarkMode,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, animValue, child) {
        return Opacity(
          opacity: animValue,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - animValue)),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          themeProvider.backgroundColor.withOpacity(0.8),
                          themeProvider.backgroundColor.withOpacity(0.6),
                        ]
                      : [
                          themeProvider.backgroundColor.withOpacity(0.8),
                          themeProvider.backgroundColor.withOpacity(0.6),
                        ],
                ),
                borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
                border: Border.all(
                  color: themeProvider.accentColor.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            themeProvider.accentColor.withOpacity(0.15),
                            themeProvider.accentColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(themeProvider.borderRadius / 2),
                      ),
                      child: Icon(
                        icon,
                        color: themeProvider.accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              color: themeProvider.secondaryTextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            value,
                            style: themeProvider.titleMedium.copyWith(
                              fontSize: 16,
                              color: themeProvider.primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildEditableProfileSection(bool isDarkMode) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isDarkMode ? 0 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDarkMode 
          ? Colors.black.withOpacity(0.3) 
          : Colors.white.withOpacity(0.9),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.primaryTextColor,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDarkMode 
                    ? Colors.black.withOpacity(0.2) 
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Enter your name',
                hintStyle: TextStyle(
                  color: themeProvider.secondaryTextColor,
                ),
                prefixIcon: Icon(Icons.person, color: themeProvider.secondaryIconColor),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Phone',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.primaryTextColor,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDarkMode 
                    ? Colors.black.withOpacity(0.2) 
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Enter your phone number',
                hintStyle: TextStyle(
                  color: themeProvider.secondaryTextColor,
                ),
                prefixIcon: Icon(Icons.phone, color: themeProvider.secondaryIconColor),
              ),
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 16),
            
            Text(
              'Location',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.primaryTextColor,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isDarkMode 
                    ? Colors.black.withOpacity(0.2) 
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Enter your location',
                hintStyle: TextStyle(
                  color: themeProvider.secondaryTextColor,
                ),
                prefixIcon: Icon(Icons.location_on, color: themeProvider.secondaryIconColor),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blueAccent,
                  disabledBackgroundColor: Colors.blueAccent.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for showing SnackBars
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
      ),
    );
  }
  
  void _showWarningSnackBar(String message) {
    if (!mounted) return;
    
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(themeProvider.borderRadius),
        ),
      ),
    );
  }
}
