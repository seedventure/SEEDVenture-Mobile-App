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
  private val CHANNEL_AES = "seedventure.io/aes"


  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    GeneratedPluginRegistrant.registerWith(this)



    MethodChannel(flutterView, CHANNEL_PERMISSIONS).setMethodCallHandler { call, result ->
      if(call.method == "getPermission"){

        try {
          val PERMISSION = 100

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

    MethodChannel(flutterView, CHANNEL_AES).setMethodCallHandler { call, result ->
      if(call.method == "encrypt"){

        try {
          val plainData = call.argument<String>("plainData")
          val realPass = call.argument<String>("realPass")

          val encryptedData = AES256.encrypt(plainData, realPass)

          result.success(encryptedData)



        } catch (e: IOException) {
          e.printStackTrace()
        }



      }

      if(call.method == "decrypt"){

        try {
          val encrypted = call.argument<String>("encrypted")
          val pass = call.argument<String>("realPass")

          val decryptedData = AES256.decrypt(encrypted, pass);

          result.success(decryptedData)



        } catch (e: IOException) {
          e.printStackTrace()
        }



      }
    }
  }
}
