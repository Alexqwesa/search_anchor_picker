import 'package:flutter_test/flutter_test.dart';
import 'package:search_anchor_picker_example/card_gallery/example_source.dart';

void main() {
  test('shared source tags extract and bold a region', () {
    const file = '''
void other() {}

/*source:hidden*/
void load() {
  /*bold=on*/
  return kept;
  /*bold=off*/
}
/*source-end:hidden*/

/*source:hidden*/
Icon(Icons.bookmark_outline)
/*source-end:hidden*/
''';

    final source = extractExampleSource(file, 'hidden');
    expect(source, contains('return kept'));
    expect(source, contains('Icons.bookmark_outline'));
    expect(source, isNot(contains('void other')));

    final runs = exampleSourceRuns(source);
    expect(
      runs.where((run) => run.bold).map((run) => run.text).join(),
      '  return kept;\n',
    );
    expect(runs.any((run) => run.text.contains('/*bold=')), isFalse);
  });
}
