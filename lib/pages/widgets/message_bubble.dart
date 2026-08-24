import "dart:convert";
import "dart:math" as math;
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";
import "../../models/message.dart";
import "../../theme/app_theme.dart";

/// 消息气泡组件 - 科技感风格（已优化渲染性能与手势交互）
class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isUser;
  final List<Color>? memberColors;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.memberColors,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final Map<String, Uint8List?> _imageCache = {};

  static final MarkdownStyleSheet _userStyleSheet = MarkdownStyleSheet(
    p: const TextStyle(
      color: Colors.white,
      fontSize: 14,
      height: 1.6,
    ),
    code: TextStyle(
      color: Colors.white,
      backgroundColor: Colors.black.withValues(alpha: 0.2),
      fontSize: 13,
      fontFamily: "Menlo",
    ),
    codeblockDecoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.borderSubtle),
    ),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(
          color: Colors.white.withValues(alpha: 0.5),
          width: 3,
        ),
      ),
    ),
    a: const TextStyle(
      color: Colors.white,
      decoration: TextDecoration.underline,
    ),
    strong: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w700,
    ),
    em: TextStyle(
      color: Colors.white.withValues(alpha: 0.8),
      fontStyle: FontStyle.italic,
    ),
    h1: const TextStyle(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    h2: const TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    h3: const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    listBullet: const TextStyle(
      color: Colors.white,
    ),
    tableBorder: TableBorder.all(
      color: AppTheme.borderSubtle,
    ),
    tableHead: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.w600,
    ),
    tableBody: const TextStyle(
      color: Colors.white,
    ),
  );

  static final MarkdownStyleSheet _aiStyleSheet = MarkdownStyleSheet(
    p: const TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 14,
      height: 1.6,
    ),
    code: const TextStyle(
      color: AppTheme.primaryCyan,
      backgroundColor: AppTheme.surfaceDark,
      fontSize: 13,
      fontFamily: "Menlo",
    ),
    codeblockDecoration: BoxDecoration(
      color: AppTheme.surfaceDark,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppTheme.borderSubtle),
    ),
    blockquoteDecoration: BoxDecoration(
      border: Border(
        left: BorderSide(
          color: AppTheme.primaryCyan.withValues(alpha: 0.5),
          width: 3,
        ),
      ),
    ),
    a: const TextStyle(
      color: AppTheme.primaryCyan,
      decoration: TextDecoration.underline,
    ),
    strong: const TextStyle(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w700,
    ),
    em: const TextStyle(
      color: AppTheme.textSecondary,
      fontStyle: FontStyle.italic,
    ),
    h1: const TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    ),
    h2: const TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
    h3: const TextStyle(
      color: AppTheme.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    listBullet: const TextStyle(
      color: AppTheme.textSecondary,
    ),
    tableBorder: TableBorder.all(
      color: AppTheme.borderSubtle,
    ),
    tableHead: const TextStyle(
      color: AppTheme.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    tableBody: const TextStyle(
      color: AppTheme.textSecondary,
    ),
  );

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.message.imageDatas, widget.message.imageDatas)) {
      _imageCache.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          mainAxisAlignment: widget.isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isUser) _buildAvatar(context),
            if (!widget.isUser) const SizedBox(width: 12),
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.62,
                ),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(widget.isUser ? 16 : 4),
                    bottomRight: Radius.circular(widget.isUser ? 4 : 16),
                  ),
                  gradient: widget.isUser
                      ? AppTheme.userBubbleGradient
                      : AppTheme.aiBubbleGradient,
                  border: widget.isUser
                      ? null
                      : Border.all(color: _getBorderColor()),
                  boxShadow: widget.isUser
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.isUser)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    widget.memberColors?.first ??
                                    AppTheme.primaryCyan,
                                boxShadow: AppTheme.glowShadow(
                                  widget.memberColors?.first ??
                                      AppTheme.primaryCyan,
                                  blur: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.message.senderName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    widget.memberColors?.first ??
                                    AppTheme.primaryCyan,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.message.imageDatas.isNotEmpty) ...[
                      _buildAttachedImages(),
                      if (widget.message.content.isNotEmpty)
                        const SizedBox(height: 10),
                    ],
                    if (widget.message.content.isNotEmpty ||
                        widget.message.isStreaming)
                      SelectionArea(
                        child: MarkdownBody(
                          data:
                              widget.message.content.isEmpty &&
                                  widget.message.isStreaming
                              ? "_正在思考..._"
                              : widget.message.content,
                          selectable: false,
                          styleSheet: widget.isUser
                              ? _userStyleSheet
                              : _aiStyleSheet,
                        ),
                      ),
                    if (widget.message.isStreaming)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Row(children: [_buildTypingIndicator()]),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 10,
                          color: widget.isUser
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppTheme.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(widget.message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isUser
                                ? Colors.white.withValues(alpha: 0.5)
                                : AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (widget.isUser) const SizedBox(width: 12),
            if (widget.isUser) _buildAvatar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachedImages() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.message.imageDatas.map(_buildAttachedImage).toList(),
    );
  }

  Widget _buildAttachedImage(String imageData) {
    final imageBytes = _imageCache.putIfAbsent(
      imageData,
      () => _decodeImageData(imageData),
    );
    if (imageBytes == null) {
      return Container(
        width: 160,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppTheme.surfaceElevated,
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: const Icon(
          Icons.broken_image_outlined,
          color: AppTheme.textMuted,
          size: 32,
        ),
      );
    }

    final displaySize = _imageDisplaySize(imageBytes);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: displaySize.width,
        height: displaySize.height,
        child: RepaintBoundary(
          child: Image.memory(
            imageBytes,
            width: displaySize.width,
            height: displaySize.height,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }

  Size _imageDisplaySize(Uint8List bytes) {
    final dimensions = _readImageDimensions(bytes);
    if (dimensions == null || dimensions.width <= 0 || dimensions.height <= 0) {
      return const Size(320, 240);
    }

    const maxWidth = 320.0;
    const maxHeight = 240.0;
    final scale = math.min(
      1.0,
      math.min(maxWidth / dimensions.width, maxHeight / dimensions.height),
    );
    return Size(
      math.max(1.0, dimensions.width * scale),
      math.max(1.0, dimensions.height * scale),
    );
  }

  Size? _readImageDimensions(Uint8List bytes) {
    if (bytes.length >= 24 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return Size(
        _readUint32Be(bytes, 16).toDouble(),
        _readUint32Be(bytes, 20).toDouble(),
      );
    }

    if (bytes.length >= 10 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return Size(
        _readUint16Le(bytes, 6).toDouble(),
        _readUint16Le(bytes, 8).toDouble(),
      );
    }

    if (bytes.length >= 26 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
      return Size(
        _readUint32Le(bytes, 18).toDouble(),
        _readUint32Le(bytes, 22).abs().toDouble(),
      );
    }

    if (bytes.length >= 4 && bytes[0] == 0xFF && bytes[1] == 0xD8) {
      return _readJpegDimensions(bytes);
    }

    return null;
  }

  Size? _readJpegDimensions(Uint8List bytes) {
    var offset = 2;
    while (offset + 9 < bytes.length) {
      if (bytes[offset] != 0xFF) {
        offset++;
        continue;
      }
      while (offset < bytes.length && bytes[offset] == 0xFF) {
        offset++;
      }
      if (offset >= bytes.length) return null;
      final marker = bytes[offset++];
      if (marker == 0xD9 || marker == 0xDA) return null;
      if (offset + 1 >= bytes.length) return null;
      final segmentLength = _readUint16Be(bytes, offset);
      if (segmentLength < 2 || offset + segmentLength > bytes.length) {
        return null;
      }

      final isStartOfFrame =
          (marker >= 0xC0 && marker <= 0xC3) ||
          (marker >= 0xC5 && marker <= 0xC7) ||
          (marker >= 0xC9 && marker <= 0xCB) ||
          (marker >= 0xCD && marker <= 0xCF);
      if (isStartOfFrame && offset + 7 < bytes.length) {
        return Size(
          _readUint16Be(bytes, offset + 5).toDouble(),
          _readUint16Be(bytes, offset + 3).toDouble(),
        );
      }
      offset += segmentLength;
    }
    return null;
  }

  int _readUint16Le(Uint8List bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8);

  int _readUint32Le(Uint8List bytes, int offset) =>
      bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);

  int _readUint16Be(Uint8List bytes, int offset) =>
      (bytes[offset] << 8) | bytes[offset + 1];

  int _readUint32Be(Uint8List bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];

  Uint8List? _decodeImageData(String data) {
    final commaIndex = data.indexOf(",");
    if (commaIndex == -1) return null;
    try {
      return base64Decode(data.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }

  Color _getBorderColor() {
    if (widget.memberColors != null) {
      return widget.memberColors!.first.withValues(alpha: 0.2);
    }
    return AppTheme.borderSubtle;
  }

  Widget _buildTypingIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.3, end: 1.0),
          duration: Duration(milliseconds: 600 + index * 200),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (widget.memberColors?.first ?? AppTheme.primaryCyan)
                    .withValues(alpha: value),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildAvatar(BuildContext context) {
    if (widget.isUser) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
          ),
          boxShadow: AppTheme.glowShadow(AppTheme.primaryBlue, blur: 10),
        ),
        child: const Icon(Icons.person_outline, color: Colors.white, size: 18),
      );
    }

    final colors =
        widget.memberColors ?? [AppTheme.primaryCyan, AppTheme.primaryBlue];
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colors[0].withValues(alpha: 0.8),
            colors[1].withValues(alpha: 0.6),
          ],
        ),
        boxShadow: AppTheme.glowShadow(colors[0], blur: 10),
      ),
      child: Center(
        child: Text(
          widget.message.senderName.isNotEmpty
              ? widget.message.senderName[0].toUpperCase()
              : "AI",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, "0");
    final m = time.minute.toString().padLeft(2, "0");
    return "$h:$m";
  }
}
