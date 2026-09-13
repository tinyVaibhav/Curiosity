class ArticleItem {
  final String title;
  final String normalizedTitle;
  final String summary;
  final String? thumbnailUrl;

  const ArticleItem({
    required this.title,
    required this.normalizedTitle,
    required this.summary,
    this.thumbnailUrl,
  });

  factory ArticleItem.fromJson(Map<String, dynamic> json) {
    return ArticleItem(
      title: json['title'] as String? ?? '',
      normalizedTitle: json['normalized_title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'normalized_title': normalizedTitle,
    'summary': summary,
    'thumbnail_url': thumbnailUrl,
  };
}

class QuizItem {
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;

  const QuizItem({
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
  });

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    return QuizItem(
      question: json['question'] as String? ?? '',
      correctAnswer: json['correct_answer'] as String? ?? '',
      incorrectAnswers: (json['incorrect_answers'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'correct_answer': correctAnswer,
    'incorrect_answers': incorrectAnswers,
  };
}

class CosmosItem {
  final String title;
  final String explanation;
  final String url;

  const CosmosItem({
    required this.title,
    required this.explanation,
    required this.url,
  });

  factory CosmosItem.fromJson(Map<String, dynamic> json) {
    return CosmosItem(
      title: json['title'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'explanation': explanation,
    'url': url,
  };
}

class FactItem {
  final String text;
  final String source;

  const FactItem({
    required this.text,
    required this.source,
  });

  factory FactItem.fromJson(Map<String, dynamic> json) {
    return FactItem(
      text: json['text'] as String? ?? '',
      source: json['source'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'source': source,
  };
}

class DailyPack {
  final String? id;
  final String packDate;
  final List<ArticleItem> articles;
  final List<QuizItem> quizzes;
  final List<CosmosItem> cosmos;
  final List<FactItem> facts;
  final String? createdAt;

  const DailyPack({
    this.id,
    required this.packDate,
    required this.articles,
    required this.quizzes,
    required this.cosmos,
    required this.facts,
    this.createdAt,
  });

  factory DailyPack.fromJson(Map<String, dynamic> json) {
    return DailyPack(
      id: json['id'] as String?,
      packDate: json['pack_date'] as String? ?? '',
      articles: (json['articles'] as List<dynamic>?)
              ?.map((e) => ArticleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      quizzes: (json['quizzes'] as List<dynamic>?)
              ?.map((e) => QuizItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      cosmos: (json['cosmos'] as List<dynamic>?)
              ?.map((e) => CosmosItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      facts: (json['facts'] as List<dynamic>?)
              ?.map((e) => FactItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'pack_date': packDate,
    'articles': articles.map((e) => e.toJson()).toList(),
    'quizzes': quizzes.map((e) => e.toJson()).toList(),
    'cosmos': cosmos.map((e) => e.toJson()).toList(),
    'facts': facts.map((e) => e.toJson()).toList(),
    'created_at': createdAt,
  };
}

class VaultHistoryItem {
  final String packDate;
  final String? heroThumbnailUrl;
  final List<String> articleTitles;
  final String? factPreview;
  final String? createdAt;

  const VaultHistoryItem({
    required this.packDate,
    this.heroThumbnailUrl,
    required this.articleTitles,
    this.factPreview,
    this.createdAt,
  });

  factory VaultHistoryItem.fromJson(Map<String, dynamic> json) {
    return VaultHistoryItem(
      packDate: json['pack_date'] as String? ?? '',
      heroThumbnailUrl: json['hero_thumbnail_url'] as String?,
      articleTitles: (json['article_titles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      factPreview: json['fact_preview'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'pack_date': packDate,
    'hero_thumbnail_url': heroThumbnailUrl,
    'article_titles': articleTitles,
    'fact_preview': factPreview,
    'created_at': createdAt,
  };
}

