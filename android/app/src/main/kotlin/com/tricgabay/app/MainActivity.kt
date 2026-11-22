package com.tricgabay.app

import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Android 12+ fades its launch icon out before showing the app, so
        // the logo blinked even though the app draws the identical logo in
        // the same place. Remove the launch screen at once instead.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            splashScreen.setOnExitAnimationListener { view -> view.remove() }
        }
        super.onCreate(savedInstanceState)
    }
}
