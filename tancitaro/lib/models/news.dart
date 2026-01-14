import 'package:intl/intl.dart';

class News {
  final String id;
  final String title;
  final String content;
  final String? imageUrl;
  final List<String> attachments;
  final String author;
  final DateTime publishedAt;
  final DateTime? updatedAt;
  final String category;
  final bool isPublished;

  News({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    this.attachments = const [],
    required this.author,
    required this.publishedAt,
    this.updatedAt,
    this.category = 'General',
    this.isPublished = true,
  });

  // Constructor desde JSON (API)
  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      imageUrl: json['imageUrl'],
      attachments: List<String>.from(json['attachments'] ?? []),
      author: json['author'],
      publishedAt: DateTime.parse(json['publishedAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      category: json['category'] ?? 'General',
      isPublished: json['isPublished'] ?? true,
    );
  }

  // Convertir a JSON para API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'attachments': attachments,
      'author': author,
      'publishedAt': publishedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'category': category,
      'isPublished': isPublished,
    };
  }

  // Obtener fecha formateada
  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    // Si es hoy
    if (publishedAt.day == now.day &&
        publishedAt.month == now.month &&
        publishedAt.year == now.year) {
      return 'Hoy, ${_formatTime(publishedAt)}';
    }

    // Si fue ayer
    final yesterday = now.subtract(const Duration(days: 1));
    if (publishedAt.day == yesterday.day &&
        publishedAt.month == yesterday.month &&
        publishedAt.year == yesterday.year) {
      return 'Ayer, ${_formatTime(publishedAt)}';
    }

    // Si fue esta semana
    if (difference.inDays < 7) {
      final weekday = DateFormat.EEEE('es_ES').format(publishedAt);
      return '$weekday, ${_formatTime(publishedAt)}';
    }

    // Formato completo
    final dateFormat = DateFormat('dd/MM/yyyy', 'es_ES');
    final timeFormat = DateFormat('HH:mm', 'es_ES');
    return '${dateFormat.format(publishedAt)}, ${timeFormat.format(publishedAt)}';
  }

  // Formatear hora
  String _formatTime(DateTime dateTime) {
    final format = DateFormat('HH:mm', 'es_ES');
    return format.format(dateTime);
  }

  // Obtener fecha corta para listas
  String get shortDate {
    final format = DateFormat('dd/MM/yy', 'es_ES');
    return format.format(publishedAt);
  }

  // Verificar si tiene imagen
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  // Verificar si tiene adjuntos
  bool get hasAttachments => attachments.isNotEmpty;

  // Resumen del contenido (primeros 100 caracteres)
  String get summary {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  // Obtener tipo de archivo adjunto
  List<String> get attachmentTypes {
    final types = <String>[];

    for (var attachment in attachments) {
      if (attachment.toLowerCase().endsWith('.pdf')) {
        types.add('PDF');
      } else if (attachment.toLowerCase().endsWith('.doc') ||
          attachment.toLowerCase().endsWith('.docx')) {
        types.add('Documento');
      } else if (attachment.toLowerCase().endsWith('.xls') ||
          attachment.toLowerCase().endsWith('.xlsx')) {
        types.add('Excel');
      } else {
        types.add('Archivo');
      }
    }

    return types;
  }

  // Clonar noticia con nuevos valores
  News copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    List<String>? attachments,
    String? author,
    DateTime? publishedAt,
    DateTime? updatedAt,
    String? category,
    bool? isPublished,
  }) {
    return News(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      attachments: attachments ?? this.attachments,
      author: author ?? this.author,
      publishedAt: publishedAt ?? this.publishedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}
