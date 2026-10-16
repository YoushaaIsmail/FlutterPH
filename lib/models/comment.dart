// lib/models/comment.dart
import 'package:flutter/material.dart';

class Comment {
  final int id;
  final String text;
  final String type;
  final int commentCustomer;
  final Map<String, dynamic>
  customerDetails; // New field for nested customer data
  final String customerName;
  final String? customerPhoto;
  final DateTime createdAt;
  final DateTime updatedAt;

  Comment({
    required this.id,
    required this.text,
    required this.type,
    required this.commentCustomer,
    required this.customerDetails,
    required this.customerName,
    this.customerPhoto,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      text: json['text'],
      type: json['type'],
      commentCustomer: json['comment_customer'],
      customerDetails: json['customer_details'] ?? {},
      customerName: json['customer_name'] ?? 'Unknown User',
      customerPhoto: json['customer_photo'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'comment_customer': commentCustomer,
      'customer_details': customerDetails,
      'customer_name': customerName,
      'customer_photo': customerPhoto,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String getFormattedDate() {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() != 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() != 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes != 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  Color getSentimentColor() {
    switch (type.toUpperCase()) {
      case 'POSITIVE':
        return Colors.green;
      case 'NEGATIVE':
        return Colors.red;
      case 'NEUTRAL':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  IconData getSentimentIcon() {
    switch (type.toUpperCase()) {
      case 'POSITIVE':
        return Icons.thumb_up;
      case 'NEGATIVE':
        return Icons.thumb_down;
      case 'NEUTRAL':
        return Icons.sentiment_neutral;
      default:
        return Icons.chat_bubble;
    }
  }
}
