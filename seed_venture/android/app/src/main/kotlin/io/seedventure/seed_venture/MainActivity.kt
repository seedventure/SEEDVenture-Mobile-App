package io.seedventure.seed_venture

import android.content.pm.PackageManager
import android.os.Bundle
import android.os.Environment
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

import io.flutter.app.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.io.File
import java.io.IOException
import java.util.*
import java.util.UUID.randomUUID




class MainActivity: FlutterActivity() {


  private val CHANNEL_PERMISSIONS = "seedventure.io/permissions"
  private val CHANNEL_AES = "seedventure.io/aes"
  private val CHANNEL_EXPORT = "seedventure.io/export_config"


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

            var mainDir = File(Environment.getExternalStorageDirectory().getPath() + File.separator + "SeedVenture")
            if(!mainDir.exists()) {
              mainDir.mkdirs()
            }

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

    MethodChannel(flutterView, CHANNEL_EXPORT).setMethodCallHandler { call, result ->
      if(call.method == "exportConfig"){

        try {

          var seedVentureDir = File(Environment.getExternalStorageDirectory().getPath() + File.separator + "SeedVenture")

          var path = call.argument<String>("path")

          val input = File(path)

         val calendar = Calendar.getInstance()

            val uuid = UUID.randomUUID()
            val str = uuid.toString().subSequence(0, 5)

          val output = File(seedVentureDir.path + File.separator + calendar.get(Calendar.DAY_OF_MONTH) + "_" + (calendar.get(Calendar.MONTH) + 1) +
                  "_" + calendar.get(Calendar.YEAR) + "_" + str + "_configuration.json")

          input.copyTo(output)

          Toast.makeText(this, "Config File exported to /SeedVenture folder", Toast.LENGTH_LONG).show()


          result.success(true);
        } catch (e: IOException) {
          e.printStackTrace()
        }



      }
    }
  }
}
