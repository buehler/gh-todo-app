import 'package:mix/mix.dart';

class TextTokens {
  static const display = _DisplayTextTokens._();
  static const headline = _HeadlineTextTokens._();
  static const title = _TitleTextTokens._();
  static const body = _BodyTextTokens._();
  static const label = _LabelTextTokens._();

  const TextTokens._();
}

class _DisplayTextTokens {
  final $large = const TextStyleToken('text.display.large');

  const _DisplayTextTokens._();
}

class _HeadlineTextTokens {
  final $medium = const TextStyleToken('text.headline.medium');

  const _HeadlineTextTokens._();
}

class _TitleTextTokens {
  final $large = const TextStyleToken('text.title.large');
  final $medium = const TextStyleToken('text.title.medium');
  final $small = const TextStyleToken('text.title.small');

  const _TitleTextTokens._();
}

class _BodyTextTokens {
  final $large = const TextStyleToken('text.body.large');
  final $medium = const TextStyleToken('text.body.medium');
  final $small = const TextStyleToken('text.body.small');

  const _BodyTextTokens._();
}

class _LabelTextTokens {
  final $large = const TextStyleToken('text.label.large');
  final $medium = const TextStyleToken('text.label.medium');
  final $small = const TextStyleToken('text.label.small');

  const _LabelTextTokens._();
}
