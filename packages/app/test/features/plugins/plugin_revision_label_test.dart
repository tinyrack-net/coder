import 'package:app/src/features/plugins/domain/plugin_revision_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shows the leading characters of a full digest', () {
    expect(
      pluginRevisionLabel(
        'a71d7554b33bc6f9e462e185d0c2f4b8e3a19c6d5f78b0e2a4c6d8f0b2e4a6c8',
      ),
      'a71d7554b33b',
    );
  });

  test('keeps a digest that is already no longer than the label', () {
    expect(pluginRevisionLabel('a71d7554b33b'), 'a71d7554b33b');
    expect(pluginRevisionLabel('none'), 'none');
    expect(pluginRevisionLabel(''), '');
  });
}
