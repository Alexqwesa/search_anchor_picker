/// One slice of example source. [bold] is set by `/*bold=on*/` … `/*bold=off*/`.
class ExampleSourceRun {
  const ExampleSourceRun(this.text, {this.bold = false});

  final String text;
  final bool bold;
}

/// Pulls every `/*source:tag*/` … `/*source-end:tag*/` region from a shared file.
///
/// Several examples can live in one file. Each region is real source. Bold
/// markers stay in the text so [exampleSourceRuns] can highlight them.
String extractExampleSource(String file, String tag) {
  final start = '/*source:$tag*/';
  final end = '/*source-end:$tag*/';
  final parts = <String>[];
  var from = 0;
  while (from < file.length) {
    final open = file.indexOf(start, from);
    if (open < 0) break;
    final body = open + start.length;
    final close = file.indexOf(end, body);
    if (close < 0) {
      throw FormatException('Missing /*source-end:$tag*/');
    }
    parts.add(file.substring(body, close));
    from = close + end.length;
  }
  if (parts.isEmpty) {
    throw FormatException('Missing /*source:$tag*/');
  }
  return _attachMarkerLines(_dedent(parts.join('\n')));
}

/// Strips bold markers and records which characters they covered.
List<ExampleSourceRun> exampleSourceRuns(String source) {
  const on = '/*bold=on*/';
  const off = '/*bold=off*/';
  final runs = <ExampleSourceRun>[];
  var index = 0;
  var bold = false;
  while (index < source.length) {
    final onAt = source.indexOf(on, index);
    final offAt = source.indexOf(off, index);
    final next = _earlier(onAt, offAt);
    if (next < 0) {
      _addRun(runs, source.substring(index), bold);
      break;
    }
    _addRun(runs, source.substring(index, next), bold);
    bold = next == onAt;
    index = next + (bold ? on.length : off.length);
  }
  return runs;
}

int _earlier(int a, int b) {
  if (a < 0) return b;
  if (b < 0) return a;
  return a < b ? a : b;
}

void _addRun(List<ExampleSourceRun> runs, String text, bool bold) {
  if (text.isEmpty) return;
  runs.add(ExampleSourceRun(text, bold: bold));
}

/// Moves a line that is only a bold marker onto the next line so it does not
/// leave a blank row in the dialog.
String _attachMarkerLines(String source) {
  const markers = ['/*bold=on*/', '/*bold=off*/'];
  final lines = source.split('\n');
  final kept = <String>[];
  var pending = '';
  for (final line in lines) {
    if (markers.contains(line.trim())) {
      pending = '$pending${line.trim()}';
      continue;
    }
    kept.add('$pending$line');
    pending = '';
  }
  if (pending.isNotEmpty) kept.add(pending);
  return kept.join('\n');
}

String _dedent(String source) {
  final lines = source.split('\n');
  while (lines.isNotEmpty && lines.first.trim().isEmpty) {
    lines.removeAt(0);
  }
  while (lines.isNotEmpty && lines.last.trim().isEmpty) {
    lines.removeLast();
  }
  var indent = 1 << 30;
  for (final line in lines) {
    if (line.trim().isEmpty) continue;
    final width = line.length - line.trimLeft().length;
    if (width < indent) indent = width;
  }
  if (indent == 1 << 30 || indent == 0) return lines.join('\n');
  return [
    for (final line in lines)
      line.length >= indent ? line.substring(indent) : line,
  ].join('\n');
}
