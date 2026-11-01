package com.example.example

import android.content.res.Configuration
import android.graphics.Color
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // FlutterActivity tints the status bar black at 25% until the first
        // frame; keep it clear, with icons that read on the theme instead.
        window.statusBarColor = Color.TRANSPARENT
        matchStatusBarIcons()
    }

    override fun onPostResume() {
        super.onPostResume()
        // Flutter resets the system UI flags here, which turns the icons
        // white until its first frame sets them again.
        matchStatusBarIcons()
    }

    /** Dark status bar icons in light mode, light ones in dark mode. */
    private fun matchStatusBarIcons() {
        val night = (resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        WindowCompat.getInsetsController(window, window.decorView)
            .isAppearanceLightStatusBars = !night
    }
}
