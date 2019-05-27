package io.seedventure.seed_venture

import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.IOException


class MainActivity: FlutterActivity() {


  private val CHANNEL_PERMISSIONS = "seedventure.io/permissions"

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)



    MethodChannel(flutterView, CHANNEL_PERMISSIONS).setMethodCallHandler { call, result ->
      if(call.method == "getPermission"){

        try {
          val PERMISSION = 100;

          if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.WRITE_EXTERNAL_STORAGE)
                  != PackageManager.PERMISSION_GRANTED) {
            // Permission is not granted


            // No explanation needed, we can request the permission.
            ActivityCompat.requestPermissions(this,
                    arrayOf(android.Manifest.permission.WRITE_EXTERNAL_STORAGE),
                    PERMISSION)




          }
          else{
            result.success(true);

          }


        } catch (e: IOException) {
          e.printStackTrace()
        }



      }
    }
  }
}
