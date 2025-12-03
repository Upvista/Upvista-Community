import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gradient_background.dart';

class ChatScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final String userUsername;
  final bool isOnline;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.userUsername,
    required this.isOnline,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Mock messages
  final List<Map<String, dynamic>> _messages = [
    {
      'id': '1',
      'text': 'Hey! How are you doing?',
      'isMe': false,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 5)),
      'reactions': <String, String>{}, // userId -> emoji
      'isStarred': false,
      'isPinned': false,
    },
    {
      'id': '2',
      'text': 'I\'m doing great! Thanks for asking. How about you?',
      'isMe': true,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 4)),
      'reactions': <String, String>{},
      'isStarred': false,
      'isPinned': false,
    },
    {
      'id': '3',
      'text': 'I\'m good too! Just working on some projects.',
      'isMe': false,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 3)),
      'reactions': <String, String>{},
      'isStarred': false,
      'isPinned': false,
    },
    {
      'id': '4',
      'text': 'That sounds interesting! What kind of projects?',
      'isMe': true,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 2)),
      'reactions': <String, String>{},
      'isStarred': false,
      'isPinned': false,
    },
    {
      'id': '5',
      'text':
          'Mostly mobile app development. Working on a new social platform.',
      'isMe': false,
      'timestamp': DateTime.now().subtract(const Duration(minutes: 1)),
      'reactions': <String, String>{},
      'isStarred': false,
      'isPinned': false,
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'text': _messageController.text.trim(),
        'isMe': true,
        'timestamp': DateTime.now(),
      });
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showNotification(String message, bool isError) {
    // Create overlay entry for top-right notification
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopRightNotification(
        message: message,
        isError: isError,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  void _showUserPreview() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      barrierColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _UserPreviewDialog(
        userName: widget.userName,
        userUsername: widget.userUsername,
        isOnline: widget.isOnline,
      ),
      routeSettings: const RouteSettings(),
    ).then((_) {
      // Optional: Handle when dialog is dismissed
    });
  }

  void _showChatMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      barrierColor: Colors.black.withOpacity(0.5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ChatMenuDialog(
        userName: widget.userName,
        onShowNotification: _showNotification,
      ),
    );
  }

  void _showMessageOptions(String messageId) {
    final message = _messages.firstWhere((m) => m['id'] == messageId);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageOptionsMenu(
        messageId: messageId,
        isMe: message['isMe'] as bool,
        messageText: message['text'] as String,
        onReaction: () => _handleReaction(messageId),
        onReply: () => _handleReply(messageId),
        onCopy: () => _handleCopy(messageId),
        onForward: () => _handleForward(messageId),
        onEdit: () => _handleEdit(messageId),
        onStar: () => _handleStar(messageId),
        onPin: () => _handlePin(messageId),
        onDelete: () => _handleDelete(messageId),
        onShare: () => _handleShare(messageId),
        onInfo: () => _handleInfo(messageId),
      ),
    );
  }

  void _handleReaction(String messageId) {
    // Menu is already closed by _handleSelection, just show emoji picker
    _showEmojiPicker(messageId);
  }

  void _showEmojiPicker(String messageId) {
    // Comprehensive emoji list organized by categories
    final emojiCategories = {
      'Smileys & People': [
        '😀',
        '😃',
        '😄',
        '😁',
        '😆',
        '😅',
        '😂',
        '🤣',
        '😊',
        '😇',
        '🙂',
        '🙃',
        '😉',
        '😌',
        '😍',
        '🥰',
        '😘',
        '😗',
        '😙',
        '😚',
        '😋',
        '😛',
        '😝',
        '😜',
        '🤪',
        '🤨',
        '🧐',
        '🤓',
        '😎',
        '🤩',
        '🥳',
        '😏',
        '😒',
        '😞',
        '😔',
        '😟',
        '😕',
        '🙁',
        '☹️',
        '😣',
        '😖',
        '😫',
        '😩',
        '🥺',
        '😢',
        '😭',
        '😤',
        '😠',
        '😡',
        '🤬',
        '🤯',
        '😳',
        '🥵',
        '🥶',
        '😱',
        '😨',
        '😰',
        '😥',
        '😓',
        '🤗',
        '🤔',
        '🤭',
        '🤫',
        '🤥',
        '😶',
        '😐',
        '😑',
        '😬',
        '🙄',
        '😯',
        '😦',
        '😧',
        '😮',
        '😲',
        '🥱',
        '😴',
        '🤤',
        '😪',
        '😵',
        '🤐',
        '🥴',
        '🤢',
        '🤮',
        '🤧',
        '😷',
        '🤒',
        '🤕',
        '🤑',
        '🤠',
        '😈',
        '👿',
        '👹',
        '👺',
        '🤡',
        '💩',
        '👻',
        '💀',
        '☠️',
        '👽',
        '👾',
        '🤖',
        '🎃',
      ],
      'Gestures': [
        '👋',
        '🤚',
        '🖐',
        '✋',
        '🖖',
        '👌',
        '🤏',
        '✌️',
        '🤞',
        '🤟',
        '🤘',
        '🤙',
        '👈',
        '👉',
        '👆',
        '🖕',
        '👇',
        '☝️',
        '👍',
        '👎',
        '✊',
        '👊',
        '🤛',
        '🤜',
        '👏',
        '🙌',
        '👐',
        '🤲',
        '🤝',
        '🙏',
        '✍️',
        '💪',
        '🦾',
        '🦿',
        '🦵',
        '🦶',
        '👂',
        '🦻',
        '👃',
        '🧠',
        '🦷',
        '🦴',
        '👀',
        '👁',
        '👅',
        '👄',
      ],
      'Hearts & Love': [
        '💋',
        '💌',
        '💘',
        '💝',
        '💖',
        '💗',
        '💓',
        '💞',
        '💕',
        '💟',
        '❣️',
        '💔',
        '❤️',
        '🧡',
        '💛',
        '💚',
        '💙',
        '💜',
        '🖤',
        '🤍',
        '🤎',
        '💯',
        '💢',
        '💥',
        '💫',
        '💦',
        '💨',
        '🕳️',
        '💣',
        '💬',
        '👁️‍🗨️',
        '🗨️',
        '🗯️',
        '💭',
        '💤',
      ],
      'Objects': [
        '👓',
        '🕶️',
        '🥽',
        '🥼',
        '🦺',
        '👔',
        '👕',
        '👖',
        '🧣',
        '🧤',
        '🧥',
        '🧦',
        '👗',
        '👘',
        '🥻',
        '🩱',
        '🩲',
        '🩳',
        '👙',
        '👚',
        '👛',
        '👜',
        '👝',
        '🛍️',
        '🎒',
        '👞',
        '👟',
        '🥾',
        '🥿',
        '👠',
        '👡',
        '🩰',
        '👢',
        '👑',
        '👒',
        '🎩',
        '🎓',
        '🧢',
        '⛑️',
        '📿',
        '💄',
        '💍',
        '💎',
      ],
      'Nature': [
        '🌱',
        '🌲',
        '🌳',
        '🌴',
        '🌵',
        '🌶️',
        '🌷',
        '🌸',
        '🌹',
        '🌺',
        '🌻',
        '🌼',
        '🌽',
        '🌾',
        '🌿',
        '🍀',
        '🍁',
        '🍂',
        '🍃',
        '🍄',
        '🍇',
        '🍈',
        '🍉',
        '🍊',
        '🍋',
        '🍌',
        '🍍',
        '🥭',
        '🍎',
        '🍏',
        '🍐',
        '🍑',
        '🍒',
        '🍓',
        '🥝',
        '🍅',
        '🥥',
        '🥑',
        '🍆',
        '🥔',
        '🥕',
        '🌽',
        '🌶️',
        '🥒',
        '🥬',
        '🥦',
        '🧄',
        '🧅',
        '🍄',
        '🥜',
        '🌰',
      ],
      'Food': [
        '🍞',
        '🥐',
        '🥖',
        '🫓',
        '🥨',
        '🥯',
        '🥞',
        '🧇',
        '🧀',
        '🍖',
        '🍗',
        '🥩',
        '🥓',
        '🍔',
        '🍟',
        '🍕',
        '🌭',
        '🥪',
        '🌮',
        '🌯',
        '🫔',
        '🥙',
        '🧆',
        '🥚',
        '🍳',
        '🥘',
        '🍲',
        '🫕',
        '🥣',
        '🥗',
        '🍿',
        '🧈',
        '🧂',
        '🥫',
        '🍱',
        '🍘',
        '🍙',
        '🍚',
        '🍛',
        '🍜',
        '🍝',
        '🍠',
        '🍢',
        '🍣',
        '🍤',
        '🍥',
        '🥮',
        '🍡',
        '🥟',
        '🥠',
        '🥡',
        '🦀',
        '🦞',
        '🦐',
        '🦑',
        '🦪',
      ],
      'Activities': [
        '⚽',
        '🏀',
        '🏈',
        '⚾',
        '🥎',
        '🎾',
        '🏐',
        '🏉',
        '🥏',
        '🎱',
        '🏓',
        '🏸',
        '🏒',
        '🏑',
        '🏏',
        '🥅',
        '⛳',
        '🏹',
        '🎣',
        '🤿',
        '🥊',
        '🥋',
        '🎽',
        '🛹',
        '🛷',
        '⛸️',
        '🥌',
        '🎿',
        '⛷️',
        '🏂',
        '🪂',
        '🏋️',
        '🤼',
        '🤸',
        '🤺',
        '🤾',
        '🏌️',
        '🏇',
        '🧘',
        '🏄',
        '🏊',
        '🤽',
        '🚣',
        '🧗',
        '🚵',
        '🚴',
        '🏆',
        '🥇',
        '🥈',
        '🥉',
        '🏅',
        '🎖️',
        '🏵️',
        '🎗️',
        '🎫',
        '🎟️',
        '🎪',
        '🤹',
        '🎭',
        '🩰',
        '🎨',
        '🎬',
        '🎤',
        '🎧',
        '🎼',
        '🎹',
        '🥁',
        '🎷',
        '🎺',
        '🎸',
        '🪕',
        '🎻',
        '🎲',
        '♟️',
        '🎯',
        '🎳',
        '🎮',
        '🎰',
        '🧩',
      ],
    };

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Emoji categories with tabs
              Expanded(
                child: DefaultTabController(
                  length: emojiCategories.length,
                  child: Column(
                    children: [
                      TabBar(
                        isScrollable: true,
                        labelColor: AppColors.accentPrimary,
                        unselectedLabelColor: AppColors.textSecondary,
                        indicatorColor: AppColors.accentPrimary,
                        tabs: emojiCategories.keys
                            .map((category) => Tab(text: category))
                            .toList(),
                      ),
                      Expanded(
                        child: TabBarView(
                          children: emojiCategories.values.map((emojis) {
                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 8,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                              itemCount: emojis.length,
                              itemBuilder: (context, index) {
                                final emoji = emojis[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      final message = _messages.firstWhere(
                                        (m) => m['id'] == messageId,
                                      );
                                      final reactions =
                                          (message['reactions']
                                              as Map<String, String>?) ??
                                          <String, String>{};
                                      reactions['me'] = emoji;
                                      message['reactions'] = reactions;
                                    });
                                    _showNotification('Reaction added', false);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundPrimary
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        emoji,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleReply(String messageId) {
    // Menu is already closed by _handleSelection
    _showNotification('Reply feature coming soon', false);
  }

  void _handleCopy(String messageId) {
    // Menu is already closed by _handleSelection
    // In a real app, you'd use Clipboard.setData
    _showNotification('Message copied', false);
  }

  void _handleForward(String messageId) {
    // Menu is already closed by _handleSelection
    _showNotification('Forward feature coming soon', false);
  }

  void _handleEdit(String messageId) {
    // Menu is already closed by _handleSelection
    _showNotification('Edit feature coming soon', false);
  }

  void _handleStar(String messageId) {
    // Menu is already closed by _handleSelection
    setState(() {
      final message = _messages.firstWhere((m) => m['id'] == messageId);
      message['isStarred'] = !((message['isStarred'] as bool?) ?? false);
    });
    final message = _messages.firstWhere((m) => m['id'] == messageId);
    _showNotification(
      (message['isStarred'] as bool?) ?? false
          ? 'Message starred'
          : 'Message unstarred',
      false,
    );
  }

  void _handlePin(String messageId) {
    // Menu is already closed by _handleSelection
    setState(() {
      final message = _messages.firstWhere((m) => m['id'] == messageId);
      message['isPinned'] = !((message['isPinned'] as bool?) ?? false);
    });
    final message = _messages.firstWhere((m) => m['id'] == messageId);
    _showNotification(
      (message['isPinned'] as bool?) ?? false
          ? 'Message pinned'
          : 'Message unpinned',
      false,
    );
  }

  void _handleDelete(String messageId) {
    // Menu is already closed by _handleSelection
    setState(() {
      _messages.removeWhere((m) => m['id'] == messageId);
    });
    _showNotification('Message deleted', false);
  }

  void _handleShare(String messageId) {
    // Menu is already closed by _handleSelection
    _showNotification('Share feature coming soon', false);
  }

  void _handleInfo(String messageId) {
    // Menu is already closed by _handleSelection
    final message = _messages.firstWhere((m) => m['id'] == messageId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text('Message Info', style: AppTextStyles.headlineSmall()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sent: ${_formatTimestamp(message['timestamp'] as DateTime)}',
              style: AppTextStyles.bodyMedium(),
            ),
            const SizedBox(height: 8),
            Text('Status: Delivered', style: AppTextStyles.bodyMedium()),
            if (message['isStarred'] as bool) ...[
              const SizedBox(height: 8),
              Text('⭐ Starred', style: AppTextStyles.bodyMedium()),
            ],
            if (message['isPinned'] as bool) ...[
              const SizedBox(height: 8),
              Text('📌 Pinned', style: AppTextStyles.bodyMedium()),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: AppTextStyles.bodyMedium(color: AppColors.accentPrimary),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      colors: AppColors.gradientWarm,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Chat Header - WhatsApp style
              _ChatHeader(
                userName: widget.userName,
                userUsername: widget.userUsername,
                isOnline: widget.isOnline,
                onBack: () => context.pop(),
                onVoiceCall: () {
                  _showNotification('Voice call feature coming soon', false);
                },
                onVideoCall: () {
                  _showNotification('Video call feature coming soon', false);
                },
                onMenuTap: () => _showChatMenu(),
                onProfileTap: () => _showUserPreview(),
              ),
              // Messages list
              Expanded(
                child: _MessagesList(
                  messages: _messages,
                  scrollController: _scrollController,
                  onMessageLongPress: _showMessageOptions,
                ),
              ),
              // Chat Footer - WhatsApp style
              _ChatFooter(
                messageController: _messageController,
                focusNode: _focusNode,
                onSend: _sendMessage,
                onVoiceMessage: () {
                  // This will be handled by the gesture detector in _ChatFooter
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String userName;
  final String userUsername;
  final bool isOnline;
  final VoidCallback onBack;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;
  final VoidCallback onMenuTap;
  final VoidCallback onProfileTap;

  const _ChatHeader({
    required this.userName,
    required this.userUsername,
    required this.isOnline,
    required this.onBack,
    required this.onVoiceCall,
    required this.onVideoCall,
    required this.onMenuTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Row(
            children: [
              // Back arrow
              GestureDetector(
                onTap: onBack,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Profile picture - tappable
              GestureDetector(
                onTap: onProfileTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentPrimary.withOpacity(0.2),
                        border: Border.all(
                          color: AppColors.glassBorder.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.person,
                        color: AppColors.accentPrimary,
                        size: 24,
                      ),
                    ),
                    // Online indicator
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.backgroundPrimary,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Name and status - tappable
              Expanded(
                child: GestureDetector(
                  onTap: onProfileTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        userName,
                        style: AppTextStyles.bodyLarge(weight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        isOnline ? 'online' : 'offline',
                        style: AppTextStyles.bodySmall(
                          color: isOnline
                              ? AppColors.success
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Voice call icon
              GestureDetector(
                onTap: onVoiceCall,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.call,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
              // Video call icon
              GestureDetector(
                onTap: onVideoCall,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.videocam,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
              // Menu dots
              GestureDetector(
                onTap: onMenuTap,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.more_vert,
                    color: AppColors.textPrimary,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesList extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final ScrollController scrollController;
  final Function(String) onMessageLongPress;

  const _MessagesList({
    required this.messages,
    required this.scrollController,
    required this.onMessageLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No messages yet',
              style: AppTextStyles.headlineSmall(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation',
              style: AppTextStyles.bodyMedium(color: AppColors.textTertiary),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _MessageBubble(
          messageId: message['id'] as String,
          text: message['text'] as String,
          isMe: message['isMe'] as bool,
          timestamp: message['timestamp'] as DateTime,
          reactions:
              (message['reactions'] as Map<String, String>?) ??
              <String, String>{},
          isStarred: (message['isStarred'] as bool?) ?? false,
          isPinned: (message['isPinned'] as bool?) ?? false,
          onLongPress: () => onMessageLongPress(message['id'] as String),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String messageId;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final Map<String, String> reactions;
  final bool isStarred;
  final bool isPinned;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.messageId,
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.reactions,
    required this.isStarred,
    required this.isPinned,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe
                    ? AppColors.accentPrimary.withOpacity(0.8)
                    : AppColors.backgroundSecondary.withOpacity(0.6),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isMe ? 12 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 12),
                ),
              ),
              child: Text(
                text,
                style: AppTextStyles.bodyMedium(
                  color: isMe ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            // Reactions
            if (reactions.isNotEmpty)
              Align(
                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: reactions.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MessageOptionsMenu extends StatefulWidget {
  final String messageId;
  final bool isMe;
  final String messageText;
  final VoidCallback onReaction;
  final VoidCallback onReply;
  final VoidCallback onCopy;
  final VoidCallback onForward;
  final VoidCallback onEdit;
  final VoidCallback onStar;
  final VoidCallback onPin;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onInfo;

  const _MessageOptionsMenu({
    required this.messageId,
    required this.isMe,
    required this.messageText,
    required this.onReaction,
    required this.onReply,
    required this.onCopy,
    required this.onForward,
    required this.onEdit,
    required this.onStar,
    required this.onPin,
    required this.onDelete,
    required this.onShare,
    required this.onInfo,
  });

  @override
  State<_MessageOptionsMenu> createState() => _MessageOptionsMenuState();
}

class _MessageOptionsMenuState extends State<_MessageOptionsMenu> {
  late final FixedExtentScrollController _scrollController;
  int _selectedIndex = 0;

  List<Map<String, dynamic>> get _options {
    final options = [
      {
        'icon': Icons.add_reaction,
        'label': 'Reaction',
        'callback': widget.onReaction,
        'isDestructive': false,
      },
      {
        'icon': Icons.reply,
        'label': 'Reply',
        'callback': widget.onReply,
        'isDestructive': false,
      },
      {
        'icon': Icons.copy,
        'label': 'Copy',
        'callback': widget.onCopy,
        'isDestructive': false,
      },
      {
        'icon': Icons.forward,
        'label': 'Forward',
        'callback': widget.onForward,
        'isDestructive': false,
      },
      if (widget.isMe)
        {
          'icon': Icons.edit,
          'label': 'Edit',
          'callback': widget.onEdit,
          'isDestructive': false,
        },
      {
        'icon': Icons.star_border,
        'label': 'Star',
        'callback': widget.onStar,
        'isDestructive': false,
      },
      {
        'icon': Icons.push_pin,
        'label': 'Pin',
        'callback': widget.onPin,
        'isDestructive': false,
      },
      {
        'icon': Icons.delete_outline,
        'label': 'Delete',
        'callback': widget.onDelete,
        'isDestructive': true,
      },
      {
        'icon': Icons.share,
        'label': 'Share',
        'callback': widget.onShare,
        'isDestructive': false,
      },
      {
        'icon': Icons.info_outline,
        'label': 'Info',
        'callback': widget.onInfo,
        'isDestructive': false,
      },
    ];
    return options;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(initialItem: 0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSelection() {
    final option = _options[_selectedIndex];
    Navigator.pop(context);
    // Small delay to ensure menu is closed before triggering action
    Future.delayed(const Duration(milliseconds: 100), () {
      (option['callback'] as VoidCallback)();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Wheel picker for message options
            Container(
              height: 280,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                children: [
                  // Selection indicator overlay
                  Center(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: AppColors.accentPrimary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Wheel picker
                  ListWheelScrollView.useDelegate(
                    controller: _scrollController,
                    itemExtent: 50,
                    physics: const FixedExtentScrollPhysics(),
                    perspective: 0.003,
                    diameterRatio: 1.5,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        if (index < 0 || index >= _options.length) {
                          return const SizedBox.shrink();
                        }
                        final option = _options[index];
                        final isSelected = index == _selectedIndex;

                        return _MessageOptionWheelItem(
                          icon: option['icon'] as IconData,
                          label: option['label'] as String,
                          isSelected: isSelected,
                          isDestructive: option['isDestructive'] as bool,
                        );
                      },
                      childCount: _options.length,
                    ),
                  ),
                ],
              ),
            ),
            // Select button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSelection,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Select',
                    style: AppTextStyles.bodyLarge(
                      color: Colors.white,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageOptionWheelItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDestructive;

  const _MessageOptionWheelItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected
                ? (isDestructive
                      ? AppColors.accentQuaternary
                      : AppColors.accentPrimary)
                : (isDestructive
                      ? AppColors.accentQuaternary.withOpacity(0.5)
                      : AppColors.textSecondary.withOpacity(0.5)),
            size: isSelected ? 24 : 20,
          ),
          const SizedBox(width: 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            style: isSelected
                ? AppTextStyles.bodyLarge(
                    color: isDestructive
                        ? AppColors.accentQuaternary
                        : AppColors.accentPrimary,
                    weight: FontWeight.w600,
                  )
                : AppTextStyles.bodyMedium(
                    color: isDestructive
                        ? AppColors.accentQuaternary.withOpacity(0.5)
                        : AppColors.textSecondary.withOpacity(0.5),
                  ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _ChatFooter extends StatefulWidget {
  final TextEditingController messageController;
  final FocusNode focusNode;
  final VoidCallback onSend;
  final VoidCallback onVoiceMessage;

  const _ChatFooter({
    required this.messageController,
    required this.focusNode,
    required this.onSend,
    required this.onVoiceMessage,
  });

  @override
  State<_ChatFooter> createState() => _ChatFooterState();
}

class _ChatFooterState extends State<_ChatFooter>
    with TickerProviderStateMixin {
  bool _isTyping = false;
  bool _isRecording = false;
  bool _isLocked = false;
  bool _isCanceling = false;
  bool _isPaused = false;
  Duration _recordingDuration = Duration.zero;
  Offset _dragOffset = Offset.zero;
  Timer? _recordingTimer;
  late AnimationController _waveformController;
  int _timerTickCount = 0;

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    _recordingTimer?.cancel();
    _waveformController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isTyping = widget.messageController.text.trim().isNotEmpty;
    });
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isLocked = false;
      _isCanceling = false;
      _isPaused = false;
      _recordingDuration = Duration.zero;
      _dragOffset = Offset.zero;
      _timerTickCount = 0;
    });

    _waveformController.repeat();

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isRecording && !_isPaused && mounted) {
        setState(() {
          _timerTickCount = timer.tick;
          _recordingDuration = Duration(seconds: _timerTickCount);
        });
      }
    });

    // TODO: Start actual audio recording
  }

  void _pauseRecording() {
    if (_isRecording && !_isPaused) {
      setState(() {
        _isPaused = true;
      });
      _waveformController.stop();
      // TODO: Pause actual audio recording
    }
  }

  void _resumeRecording() {
    if (_isRecording && _isPaused) {
      setState(() {
        _isPaused = false;
      });
      _waveformController.repeat();
      // TODO: Resume actual audio recording
    }
  }

  void _togglePauseResume() {
    if (_isPaused) {
      _resumeRecording();
    } else {
      _pauseRecording();
    }
  }

  void _stopRecording({bool cancel = false}) {
    _recordingTimer?.cancel();
    _waveformController.stop();
    setState(() {
      _isRecording = false;
      _isLocked = false;
      _isCanceling = false;
      _isPaused = false;
      _dragOffset = Offset.zero;
      _timerTickCount = 0;
    });

    if (!cancel) {
      // TODO: Send audio message
      widget.onVoiceMessage();
    }
    // TODO: Cancel and delete recording if cancel is true
  }

  void _showAttachmentMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _AttachmentMenu(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: const BoxDecoration(color: Colors.transparent),
              child: SafeArea(
                top: false,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Text input field with attachment icon
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxHeight: 100),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSecondary.withOpacity(
                              0.5,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: AppColors.glassBorder.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                          child: TextField(
                            controller: widget.messageController,
                            focusNode: widget.focusNode,
                            textAlign: TextAlign.left,
                            textAlignVertical: TextAlignVertical.center,
                            style: AppTextStyles.bodyMedium(),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => widget.onSend(),
                            decoration: InputDecoration(
                              hintText: 'Type a message',
                              hintStyle: AppTextStyles.bodyMedium(
                                color: AppColors.textTertiary,
                              ),
                              border: InputBorder.none,
                              suffixIcon: GestureDetector(
                                onTap: () => _showAttachmentMenu(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.attach_file,
                                    color: AppColors.textSecondary,
                                    size: 24,
                                  ),
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              filled: false,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Send button or voice button - matches typing box height
                      if (_isTyping)
                        GestureDetector(
                          onTap: widget.onSend,
                          child: Container(
                            width: 48,
                            decoration: BoxDecoration(
                              color: AppColors.accentPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.send,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onLongPress: _startRecording,
                          onLongPressEnd: (details) {
                            if (!_isLocked) {
                              _stopRecording(cancel: _isCanceling);
                            }
                          },
                          onPanUpdate: (details) {
                            if (_isRecording) {
                              setState(() {
                                // Use global position for accurate drag detection
                                final RenderBox? renderBox =
                                    context.findRenderObject() as RenderBox?;
                                if (renderBox != null) {
                                  final localPosition = renderBox.globalToLocal(
                                    details.globalPosition,
                                  );
                                  _dragOffset = localPosition;

                                  // Check if dragged up (lock) or left (cancel)
                                  final dragUp = -details.delta.dy;
                                  final dragLeft = -details.delta.dx;
                                  final initialY = renderBox
                                      .localToGlobal(Offset.zero)
                                      .dy;
                                  final currentY = details.globalPosition.dy;

                                  // Lock when dragged up significantly
                                  if (dragUp > 20 &&
                                      (initialY - currentY) > 50) {
                                    _isLocked = true;
                                    _isCanceling = false;
                                  }
                                  // Cancel when dragged left significantly
                                  else if (dragLeft > 30) {
                                    _isCanceling = true;
                                    _isLocked = false;
                                  }
                                  // Reset when dragged back down or right
                                  else if (details.delta.dy > 10 ||
                                      details.delta.dx < -10) {
                                    _isLocked = false;
                                    _isCanceling = false;
                                  }
                                }
                              });
                            }
                          },
                          onPanEnd: (details) {
                            if (_isRecording && !_isLocked) {
                              _stopRecording(cancel: _isCanceling);
                            }
                          },
                          child: Container(
                            width: 48,
                            decoration: BoxDecoration(
                              color: _isRecording
                                  ? AppColors.accentQuaternary
                                  : AppColors.accentPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isRecording ? Icons.mic : Icons.mic,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Recording overlay
        if (_isRecording)
          _RecordingOverlay(
            duration: _recordingDuration,
            isLocked: _isLocked,
            isCanceling: _isCanceling,
            isPaused: _isPaused,
            dragOffset: _dragOffset,
            waveformController: _waveformController,
            onCancel: () => _stopRecording(cancel: true),
            onSend: () => _stopRecording(cancel: false),
            onPauseResume: _togglePauseResume,
          ),
      ],
    );
  }
}

class _AttachmentMenu extends StatelessWidget {
  final List<Map<String, dynamic>> _attachments = [
    {'icon': Icons.photo_library, 'label': 'Gallery', 'color': Colors.blue},
    {'icon': Icons.camera_alt, 'label': 'Camera', 'color': Colors.pink},
    {'icon': Icons.location_on, 'label': 'Location', 'color': Colors.teal},
    {'icon': Icons.person, 'label': 'Contact', 'color': Colors.blue},
    {'icon': Icons.description, 'label': 'Document', 'color': Colors.purple},
    {'icon': Icons.headphones, 'label': 'Audio', 'color': Colors.orange},
    {'icon': Icons.poll, 'label': 'Poll', 'color': Colors.yellow},
    {'icon': Icons.event, 'label': 'Event', 'color': Colors.pink},
    {'icon': Icons.auto_awesome, 'label': 'AI images', 'color': Colors.blue},
  ];

  _AttachmentMenu();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 16, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Attachment options grid (3 columns like WhatsApp)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.95,
              ),
              itemCount: _attachments.length,
              itemBuilder: (context, index) {
                final attachment = _attachments[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Handle attachment selection
                    // You can add specific handlers for each attachment type
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: (attachment['color'] as Color).withOpacity(
                            0.2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          attachment['icon'] as IconData,
                          color: attachment['color'] as Color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        attachment['label'] as String,
                        style: AppTextStyles.bodySmall(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Professional top-right notification widget
class _TopRightNotification extends StatefulWidget {
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _TopRightNotification({
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_TopRightNotification> createState() => _TopRightNotificationState();
}

class _TopRightNotificationState extends State<_TopRightNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0), // Start from right
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final accentColor = widget.isError
        ? AppColors.accentQuaternary
        : AppColors.success;

    return Positioned(
      top: safeAreaTop + 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: screenWidth * 0.75,
                      minWidth: 200,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      // Transparent background with subtle tint
                      color: AppColors.backgroundSecondary.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: accentColor.withOpacity(0.1),
                          blurRadius: 15,
                          spreadRadius: -5,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon with accent background
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: accentColor.withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Icon(
                            widget.isError
                                ? Icons.error_rounded
                                : Icons.check_circle_rounded,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Message
                        Flexible(
                          child: Text(
                            widget.message,
                            style:
                                AppTextStyles.bodyMedium(
                                  color: AppColors.textPrimary,
                                  weight: FontWeight.w600,
                                ).copyWith(
                                  fontSize: 14,
                                  letterSpacing: 0.1,
                                  height: 1.4,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Close button with glass effect
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _dismiss,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: AppColors.textSecondary,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// User Preview Dialog - WhatsApp style
class _UserPreviewDialog extends StatelessWidget {
  final String userName;
  final String userUsername;
  final bool isOnline;

  const _UserPreviewDialog({
    required this.userName,
    required this.userUsername,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _UserPreviewHeader(
                userName: userName,
                userUsername: userUsername,
                isOnline: isOnline,
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.only(
                    top: 8,
                    bottom: bottomPadding + 16,
                    left: 0,
                    right: 0,
                  ),
                  children: [
                    _SettingsSection(),
                    const SizedBox(height: 8),
                    _PrivacySection(),
                    const SizedBox(height: 8),
                    _CommunitiesSection(),
                    const SizedBox(height: 8),
                    _MediaGallerySection(),
                    const SizedBox(height: 8),
                    _ActionsSection(userName: userName),
                    SizedBox(height: bottomPadding + 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserPreviewHeader extends StatelessWidget {
  final String userName;
  final String userUsername;
  final bool isOnline;

  const _UserPreviewHeader({
    required this.userName,
    required this.userUsername,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentPrimary.withOpacity(0.2),
                  border: Border.all(
                    color: AppColors.accentPrimary.withOpacity(0.3),
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.accentPrimary,
                  size: 60,
                ),
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.backgroundSecondary,
                        width: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            userName,
            style: AppTextStyles.headlineMedium(weight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            userUsername,
            style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOnline
                  ? AppColors.success.withOpacity(0.15)
                  : AppColors.textTertiary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOnline
                        ? AppColors.success
                        : AppColors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOnline ? 'Online' : 'Offline',
                  style: AppTextStyles.bodySmall(
                    color: isOnline
                        ? AppColors.success
                        : AppColors.textTertiary,
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

class _SettingsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      children: [
        _SectionTitle(title: 'Settings'),
        _SettingTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          subtitle: 'Customize notification settings',
          onTap: () {},
        ),
        _Divider(),
        _SettingTile(
          icon: Icons.visibility_outlined,
          title: 'Media Visibility',
          subtitle: 'Show media in gallery',
          trailing: Switch(
            value: true,
            onChanged: (value) {},
            activeColor: AppColors.accentPrimary,
          ),
        ),
        _Divider(),
        _SettingTile(
          icon: Icons.star_outline,
          title: 'Starred Messages',
          subtitle: 'View starred messages',
          onTap: () {},
        ),
        _Divider(),
        _SettingTile(
          icon: Icons.lock_outline,
          title: 'Encryption',
          subtitle: 'Messages are end-to-end encrypted',
          trailing: Icon(Icons.verified, color: AppColors.success, size: 20),
        ),
      ],
    );
  }
}

class _PrivacySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      children: [
        _SectionTitle(title: 'Privacy'),
        _SettingTile(
          icon: Icons.timer_outlined,
          title: 'Disappearing Messages',
          subtitle: 'Off',
          onTap: () {},
        ),
        _Divider(),
        _SettingTile(
          icon: Icons.lock_outline,
          title: 'Chat Lock',
          subtitle: 'Lock this chat with fingerprint',
          trailing: Switch(
            value: false,
            onChanged: (value) {},
            activeColor: AppColors.accentPrimary,
          ),
        ),
        _Divider(),
        _SettingTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Advanced Chat Privacy',
          subtitle: 'Manage advanced privacy settings',
          onTap: () {},
        ),
      ],
    );
  }
}

class _CommunitiesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      children: [
        _SectionTitle(title: 'Communities & Groups'),
        _SettingTile(
          icon: Icons.people_outline,
          title: 'Communities and Groups in Common',
          subtitle: '2 groups in common',
          onTap: () {},
        ),
      ],
    );
  }
}

class _MediaGallerySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      children: [
        _SectionTitle(title: 'Media, Links, and Docs'),
        _MediaGalleryTile(
          icon: Icons.photo_library_outlined,
          title: 'Media',
          count: 24,
          onTap: () {},
        ),
        _Divider(),
        _MediaGalleryTile(
          icon: Icons.link_outlined,
          title: 'Links',
          count: 8,
          onTap: () {},
        ),
        _Divider(),
        _MediaGalleryTile(
          icon: Icons.description_outlined,
          title: 'Docs',
          count: 5,
          onTap: () {},
        ),
        _Divider(),
        _MediaGalleryTile(
          icon: Icons.audiotrack_outlined,
          title: 'Audio',
          count: 12,
          onTap: () {},
        ),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  final String userName;

  const _ActionsSection({required this.userName});

  @override
  Widget build(BuildContext context) {
    return _SectionContainer(
      children: [
        _SectionTitle(title: 'Actions'),
        _ActionTile(
          icon: Icons.person_remove_outlined,
          title: 'Unfollow',
          isDestructive: false,
          onTap: () => Navigator.pop(context),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.link_off_outlined,
          title: 'Unconnect',
          isDestructive: false,
          onTap: () => Navigator.pop(context),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.cancel_outlined,
          title: 'Uncollaborate',
          isDestructive: false,
          onTap: () => Navigator.pop(context),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.block_outlined,
          title: 'Block $userName',
          isDestructive: true,
          onTap: () => Navigator.pop(context),
        ),
        _Divider(),
        _ActionTile(
          icon: Icons.flag_outlined,
          title: 'Report $userName',
          isDestructive: true,
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _SectionContainer extends StatelessWidget {
  final List<Widget> children;

  const _SectionContainer({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.glassBorder.withOpacity(0.1),
          width: 0.5,
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTextStyles.labelLarge(
          color: AppColors.textSecondary,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accentPrimary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.accentPrimary, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium(weight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall(color: AppColors.textTertiary),
      ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _MediaGalleryTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  const _MediaGalleryTile({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accentPrimary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.accentPrimary, size: 22),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium(weight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count.toString(),
            style: AppTextStyles.bodySmall(color: AppColors.textTertiary),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.isDestructive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color:
              (isDestructive
                      ? AppColors.accentQuaternary
                      : AppColors.accentPrimary)
                  .withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: isDestructive
              ? AppColors.accentQuaternary
              : AppColors.accentPrimary,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium(
          weight: FontWeight.w500,
          color: isDestructive
              ? AppColors.accentQuaternary
              : AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 72,
      color: AppColors.glassBorder.withOpacity(0.1),
    );
  }
}

/// Chat Menu Dialog - WhatsApp style
class _ChatMenuDialog extends StatefulWidget {
  final String userName;
  final Function(String, bool) onShowNotification;

  const _ChatMenuDialog({
    required this.userName,
    required this.onShowNotification,
  });

  @override
  State<_ChatMenuDialog> createState() => _ChatMenuDialogState();
}

class _ChatMenuDialogState extends State<_ChatMenuDialog> {
  late final FixedExtentScrollController _scrollController;
  int _selectedIndex = 0;

  List<Map<String, dynamic>> get _menuOptions {
    return [
      {
        'icon': Icons.search,
        'title': 'Search',
        'message': 'Search feature coming soon',
        'isDestructive': false,
      },
      {
        'icon': Icons.group_add,
        'title': 'New Group',
        'message': 'New group feature coming soon',
        'isDestructive': false,
      },
      {
        'icon': Icons.photo_library,
        'title': 'Media',
        'message': 'Media gallery feature coming soon',
        'isDestructive': false,
      },
      {
        'icon': Icons.notifications_off,
        'title': 'Mute',
        'message': 'Mute notifications feature coming soon',
        'isDestructive': false,
      },
      {
        'icon': Icons.timer_outlined,
        'title': 'Disappearing Messages',
        'message': 'Disappearing messages feature coming soon',
        'isDestructive': false,
      },
      {
        'icon': Icons.palette_outlined,
        'title': 'Theme',
        'message': 'Chat theme feature coming soon',
        'isDestructive': false,
      },
      {
        'icon': Icons.flag_outlined,
        'title': 'Report',
        'message': 'Report feature coming soon',
        'isDestructive': false,
      },
      {
        'icon': Icons.block_outlined,
        'title': 'Block ${widget.userName}',
        'message': 'Block user feature coming soon',
        'isDestructive': true,
      },
      {
        'icon': Icons.delete_outline,
        'title': 'Clear Chat',
        'message': 'Clear chat feature coming soon',
        'isDestructive': true,
      },
      {
        'icon': Icons.file_download_outlined,
        'title': 'Export Chat',
        'message': 'Export chat feature coming soon',
        'isDestructive': false,
      },
      {
        'icon': Icons.add_to_home_screen,
        'title': 'Add Shortcut',
        'message': 'Add shortcut feature coming soon',
        'isDestructive': false,
      },
      {
        'icon': Icons.list,
        'title': 'Add to List',
        'message': 'Add to list feature coming soon',
        'isDestructive': false,
      },
    ];
  }

  @override
  void initState() {
    super.initState();
    _scrollController = FixedExtentScrollController(initialItem: 0);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSelection() {
    final option = _menuOptions[_selectedIndex];
    Navigator.pop(context); // Close the menu dialog
    // Show notification - stays on chat screen
    widget.onShowNotification(
      option['message'] as String,
      false, // Not an error
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding + 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Wheel picker for menu options
          Container(
            height: 280,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Stack(
              children: [
                // Selection indicator overlay
                Center(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.symmetric(
                        horizontal: BorderSide(
                          color: AppColors.accentPrimary.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
                // Wheel picker
                ListWheelScrollView.useDelegate(
                  controller: _scrollController,
                  itemExtent: 50,
                  physics: const FixedExtentScrollPhysics(),
                  perspective: 0.003,
                  diameterRatio: 1.5,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index < 0 || index >= _menuOptions.length) {
                        return const SizedBox.shrink();
                      }
                      final option = _menuOptions[index];
                      final isSelected = index == _selectedIndex;

                      return _ChatMenuWheelItem(
                        icon: option['icon'] as IconData,
                        title: option['title'] as String,
                        isSelected: isSelected,
                        isDestructive: option['isDestructive'] as bool,
                      );
                    },
                    childCount: _menuOptions.length,
                  ),
                ),
              ],
            ),
          ),
          // Select button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: ElevatedButton(
              onPressed: _handleSelection,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                elevation: 0,
              ),
              child: Text(
                'Select',
                style: AppTextStyles.labelLarge(
                  color: AppColors.textPrimary,
                  weight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMenuWheelItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final bool isDestructive;

  const _ChatMenuWheelItem({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? (isDestructive
                      ? AppColors.accentQuaternary
                      : AppColors.accentPrimary)
                : AppColors.textSecondary.withOpacity(0.5),
            size: isSelected ? 28 : 22,
          ),
          const SizedBox(width: 12),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            style: isSelected
                ? AppTextStyles.headlineSmall(
                    color: isDestructive
                        ? AppColors.accentQuaternary
                        : AppColors.textPrimary,
                    weight: FontWeight.bold,
                  )
                : AppTextStyles.bodyLarge(
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
            child: Text(title, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

/// Audio Recording Dialog with waveform animation
class _AudioRecordingDialog extends StatefulWidget {
  final Function(String?) onSend;
  final VoidCallback onCancel;

  const _AudioRecordingDialog({required this.onSend, required this.onCancel});

  @override
  State<_AudioRecordingDialog> createState() => _AudioRecordingDialogState();
}

class _AudioRecordingDialogState extends State<_AudioRecordingDialog>
    with TickerProviderStateMixin {
  bool _isPaused = false;
  Duration _recordingDuration = Duration.zero;
  late AnimationController _waveformController;
  late AnimationController _pulseController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _startRecording();
  }

  @override
  void dispose() {
    _waveformController.dispose();
    _pulseController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isPaused = false;
      _recordingDuration = Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          _recordingDuration = Duration(seconds: timer.tick);
        });
      }
    });

    // TODO: Start actual audio recording
    // final recorder = Record();
    // await recorder.start(
    //   path: 'audio_recording_${DateTime.now().millisecondsSinceEpoch}.m4a',
    //   encoder: AudioEncoder.aacLc,
    // );
  }

  void _pauseRecording() {
    setState(() {
      _isPaused = !_isPaused;
    });
    // TODO: Pause actual audio recording
  }

  void _stopRecording() {
    _timer?.cancel();
    // TODO: Stop actual audio recording and get file path
    // final path = await recorder.stop();
    // widget.onSend(path);
    Navigator.pop(context);
    widget.onSend(null); // For now, just close
  }

  void _cancelRecording() {
    _timer?.cancel();
    // TODO: Cancel and delete recording
    Navigator.pop(context);
    widget.onCancel();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Timer
                Text(
                  _formatDuration(_recordingDuration),
                  style: AppTextStyles.headlineMedium(weight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                // Waveform animation
                _WaveformAnimation(
                  controller: _waveformController,
                  isPaused: _isPaused,
                ),
                const SizedBox(height: 32),
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Cancel button
                    _ControlButton(
                      icon: Icons.close,
                      label: 'Cancel',
                      color: AppColors.accentQuaternary,
                      onTap: _cancelRecording,
                    ),
                    // Pause/Resume button
                    _ControlButton(
                      icon: _isPaused ? Icons.play_arrow : Icons.pause,
                      label: _isPaused ? 'Resume' : 'Pause',
                      color: AppColors.accentTertiary,
                      onTap: _pauseRecording,
                    ),
                    // Stop/Send button
                    _ControlButton(
                      icon: Icons.stop,
                      label: 'Send',
                      color: AppColors.success,
                      onTap: _stopRecording,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveformAnimation extends StatelessWidget {
  final AnimationController controller;
  final bool isPaused;

  const _WaveformAnimation({required this.controller, required this.isPaused});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        if (isPaused) {
          return Container(
            height: 80,
            alignment: Alignment.center,
            child: Icon(
              Icons.pause_circle_outline,
              size: 48,
              color: AppColors.textSecondary,
            ),
          );
        }

        return Container(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(20, (index) {
              // Create animated waveform bars
              final delay = index * 0.1;
              final animationValue = (controller.value + delay) % 1.0;
              final height =
                  20 + (math.sin(animationValue * 2 * math.pi) * 30).abs();

              return Container(
                width: 4,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.accentPrimary,
                      AppColors.accentSecondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmall(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Recording overlay - WhatsApp style
class _RecordingOverlay extends StatelessWidget {
  final Duration duration;
  final bool isLocked;
  final bool isCanceling;
  final bool isPaused;
  final Offset dragOffset;
  final AnimationController waveformController;
  final VoidCallback onCancel;
  final VoidCallback onSend;
  final VoidCallback onPauseResume;

  const _RecordingOverlay({
    required this.duration,
    required this.isLocked,
    required this.isCanceling,
    required this.isPaused,
    required this.dragOffset,
    required this.waveformController,
    required this.onCancel,
    required this.onSend,
    required this.onPauseResume,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final dragY = dragOffset.dy;
    final dragX = dragOffset.dx;
    final isLockedPosition = isLocked && dragY < -100;
    final isCancelPosition = isCanceling && dragX > 50;

    // Calculate position relative to screen
    final footerHeight = 80.0; // Approximate footer height
    final overlayBottom = isLockedPosition
        ? screenSize.height * 0.35
        : footerHeight + 40; // Position above footer

    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: false,
        child: GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.translucent,
          child: Container(
            color: Colors.black.withOpacity(0.2),
            child: Stack(
              children: [
                // Main recording indicator - Always show above footer
                Positioned(
                  bottom: overlayBottom,
                  left: isCancelPosition
                      ? screenSize.width * 0.3
                      : (screenSize.width / 2) - 140,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 280,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isCanceling
                          ? AppColors.accentQuaternary.withOpacity(0.95)
                          : AppColors.backgroundSecondary.withOpacity(0.98),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 30,
                          spreadRadius: 0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Always show waveform (or pause icon when paused)
                        if (isCanceling)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 36,
                            ),
                          )
                        else
                          _RecordingWaveform(
                            controller: waveformController,
                            isPaused: isPaused,
                          ),
                        const SizedBox(height: 16),
                        // Timer with pause indicator - Always visible
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isPaused) ...[
                              Icon(
                                Icons.pause,
                                color: AppColors.textSecondary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              _formatDuration(duration),
                              style: AppTextStyles.headlineMedium(
                                weight: FontWeight.bold,
                                color: isCanceling
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Status text or control buttons
                        if (isLocked) ...[
                          Text(
                            'Recording locked',
                            style: AppTextStyles.bodySmall(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Control buttons row - Only show when locked
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Pause/Resume button
                              GestureDetector(
                                onTap: onPauseResume,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundPrimary
                                        .withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isPaused ? Icons.play_arrow : Icons.pause,
                                    color: AppColors.textPrimary,
                                    size: 24,
                                  ),
                                ),
                              ),
                              // Delete button
                              GestureDetector(
                                onTap: onCancel,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentQuaternary
                                        .withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.delete_outline,
                                    color: AppColors.accentQuaternary,
                                    size: 24,
                                  ),
                                ),
                              ),
                              // Send button
                              GestureDetector(
                                onTap: onSend,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.send,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else if (!isCanceling) ...[
                          Text(
                            'Slide up to lock',
                            style: AppTextStyles.bodySmall(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Cancel indicator (when dragging left)
                if (isCanceling && !isLocked)
                  Positioned(
                    bottom: 100,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentQuaternary.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 32),
                    ),
                  ),
                // Lock indicator (when dragging up)
                if (isLocked && !isCanceling)
                  Positioned(
                    top: 100,
                    left: (screenSize.width / 2) - 40,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withOpacity(0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.lock, color: Colors.white, size: 32),
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

class _RecordingWaveform extends StatelessWidget {
  final AnimationController controller;
  final bool isPaused;

  const _RecordingWaveform({required this.controller, this.isPaused = false});

  @override
  Widget build(BuildContext context) {
    if (isPaused) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: Icon(
          Icons.pause_circle_outline,
          size: 48,
          color: AppColors.textSecondary,
        ),
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return Container(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(25, (index) {
              final delay = index * 0.08;
              final animationValue = (controller.value + delay) % 1.0;
              // Create more dynamic waveform with varying amplitudes
              final baseHeight = 8.0;
              final amplitude = 25.0 + (math.sin(index * 0.5) * 10);
              final height =
                  baseHeight +
                  (math.sin(animationValue * 2 * math.pi) * amplitude).abs();

              return Container(
                width: 3.5,
                height: height.clamp(8.0, 50.0),
                margin: const EdgeInsets.symmetric(horizontal: 1.2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.accentPrimary,
                      AppColors.accentSecondary,
                      AppColors.accentPrimary,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentPrimary.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
