// FLAKY: Timing-sensitive test with async operations and DateTime.now()
// Tracked in docs/D3_D6_ROADMAP.md (D3.2 POC)
//
// This is a POC marker file for D3.2 flaky detection.
// Original test logic untouched, just renamed to demonstrate file-based detection.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('POC flaky marker (file-based) - timing sensitive', () {
    // This is just a POC test to demonstrate flaky detection
    expect(true, isTrue);
  }, tags: ['flaky']);
}
