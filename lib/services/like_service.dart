import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math' as math;

class SupabaseLikeService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> toggleLike(int postId, String userId) async {
    try {
      // 현재 게시물의 정보를 가져옵니다.
      final response = await _supabase
          .from('posts')
          .select('likes, likes_details')
          .eq('id', postId)
          .single();

      Map<String, dynamic> likesDetails = response['likes_details'] ?? {};
      int likesCount = response['likes'] ?? 0;

      if (likesDetails.containsKey(userId)) {
        // 이미 좋아요를 눌렀다면 제거
        likesDetails.remove(userId);
        likesCount = math.max(0, likesCount - 1);  // 음수가 되지 않도록 합니다.
      } else {
        // 좋아요를 누르지 않았다면 추가
        likesDetails[userId] = DateTime.now().toIso8601String();
        likesCount++;
      }

      // 업데이트된 정보를 데이터베이스에 저장합니다.
      await _supabase
        .from('posts')
        .update({
          'likes_details': likesDetails,
          'likes': likesCount
        })
        .eq('id', postId);
    
    } catch (e) {
      print('Error toggling like: $e');
      rethrow;
    }
  }

  Stream<bool> isLikedByUser(int postId, String userId) {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('id', postId)
        .map((event) {
          if (event.isEmpty) return false;
          Map<String, dynamic> likesDetails = event.first['likes_details'] ?? {};
          return likesDetails.containsKey(userId);
        })
        .handleError((error) {
          print('Error in isLikedByUser stream: $error');
          return false;
        });
  }

  Stream<int> getLikeCount(int postId) {
    return _supabase
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('id', postId)
        .map((event) {
          if (event.isEmpty) {
            print('No data received for post $postId');
            return 0;
          }
          var likes = event.first['likes'];
          if (likes == null) {
            print('Likes field is null for post $postId');
            return 0;
          }
          if (likes is int) {
            return likes;
          }
          if (likes is String) {
            return int.tryParse(likes) ?? 0;
          }
          print('Unexpected likes type for post $postId: ${likes.runtimeType}');
          return 0;
        })
        .handleError((error) {
          print('Error in getLikeCount stream for post $postId: $error');
          return 0;
        })
        .asBroadcastStream();  // 여러 리스너가 구독할 수 있도록 함
  }
}