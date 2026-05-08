package com.example.app

import android.media.AudioManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private lateinit var audioManager: AudioManager

    override fun onResume() {
        super.onResume()
        audioManager = getSystemService(AUDIO_SERVICE) as AudioManager
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
    }

    override fun onPause() {
        super.onPause()
        if (::audioManager.isInitialized) {
            audioManager.mode = AudioManager.MODE_NORMAL
        }
    }
}
