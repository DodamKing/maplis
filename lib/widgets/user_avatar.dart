import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AvatarColors {
  static final List<Color> _colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  static Color getColorFromName(String name) {
    if (name.isEmpty) return _colors[0];

    int hash =
        name.split('').fold(0, (prev, element) => prev + element.codeUnitAt(0));
    return _colors[hash % _colors.length];
  }

  static Color getTextColor(Color backgroundColor) {
    // YIQ 공식을 사용하여 배경색의 밝기를 계산
    double yiq = (backgroundColor.red * 299 +
            backgroundColor.green * 587 +
            backgroundColor.blue * 114) /
        1000;

    // 밝기에 따라 검은색 또는 흰색 텍스트 색상 반환
    return yiq >= 128 ? Colors.black : Colors.white;
  }
}

class UserAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String name;
  final double radius;

  static final Color defaultBackgroundColor = Colors.purple.shade300;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 16,
  });

  @override
  _UserAvatarState createState() => _UserAvatarState();
}

class _UserAvatarState extends State<UserAvatar> {
  bool _isLoading = true;
  String? _loadedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    if (widget.avatarUrl != null) {
      // 실제 네트워크 이미지 로딩을 시뮬레이션
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _loadedAvatarUrl = widget.avatarUrl;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = widget.avatarUrl == null
        ? AvatarColors.getColorFromName(widget.name)
        : UserAvatar.defaultBackgroundColor;

    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: backgroundColor,
      child: widget.avatarUrl != null
          ? CachedNetworkImage(
              imageUrl: widget.avatarUrl!,
              imageBuilder: (context, imageProvider) => Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) {
                print('Error loading image: $error');
                return const Icon(Icons.error);
              },
            )
          : _buildDefaultAvatar(backgroundColor),
    );
  }

  Widget _buildDefaultAvatar(Color backgroundColor) {
    Color textColor = AvatarColors.getTextColor(backgroundColor);
    return Text(
      widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?',
      style: TextStyle(
        fontSize: widget.radius,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }
}
