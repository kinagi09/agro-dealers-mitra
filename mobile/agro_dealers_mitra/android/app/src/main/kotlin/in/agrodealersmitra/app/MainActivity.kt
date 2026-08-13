// `in` is a Kotlin reserved keyword (used in for-in loops, range checks), so
// the package segment from the agrodealersmitra.in domain must be escaped
// with backticks here. Any future Kotlin file added under this package
// needs the same `in`.agrodealersmitra.app escaping in its own package
// declaration and in any cross-package import referencing this one.
package `in`.agrodealersmitra.app

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
