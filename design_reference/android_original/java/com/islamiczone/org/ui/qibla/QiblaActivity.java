package com.islamiczone.org.ui.qibla;

import android.Manifest;
import android.content.pm.PackageManager;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.location.Location;
import android.os.Bundle;
import android.view.animation.Animation;
import android.view.animation.RotateAnimation;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import com.islamiczone.org.databinding.ActivityQiblaBinding;

public class QiblaActivity extends AppCompatActivity implements SensorEventListener {
    private ActivityQiblaBinding binding;
    private SensorManager sensorManager;
    private Sensor accelerometer;
    private Sensor magnetometer;
    
    private float[] gravity;
    private float[] geomagnetic;
    private float currentDegree = 0f;
    
    // Kaaba coordinates
    private static final double KAABA_LAT = 21.4225;
    private static final double KAABA_LNG = 39.8262;
    
    // Default location (Dhaka)
    private double userLat = 23.8103;
    private double userLng = 90.4125;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityQiblaBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        sensorManager = (SensorManager) getSystemService(SENSOR_SERVICE);
        accelerometer = sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        magnetometer = sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD);

        binding.btnBack.setOnClickListener(v -> finish());
        
        updateQiblaDirection();
    }

    @Override
    protected void onResume() {
        super.onResume();
        sensorManager.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_UI);
        sensorManager.registerListener(this, magnetometer, SensorManager.SENSOR_DELAY_UI);
    }

    @Override
    protected void onPause() {
        super.onPause();
        sensorManager.unregisterListener(this);
    }

    @Override
    public void onSensorChanged(SensorEvent event) {
        if (event.sensor.getType() == Sensor.TYPE_ACCELEROMETER) {
            gravity = event.values;
        }
        if (event.sensor.getType() == Sensor.TYPE_MAGNETIC_FIELD) {
            geomagnetic = event.values;
        }

        if (gravity != null && geomagnetic != null) {
            float[] R = new float[9];
            float[] I = new float[9];
            
            if (SensorManager.getRotationMatrix(R, I, gravity, geomagnetic)) {
                float[] orientation = new float[3];
                SensorManager.getOrientation(R, orientation);
                
                float azimuth = (float) Math.toDegrees(orientation[0]);
                azimuth = (azimuth + 360) % 360;
                
                float qiblaDirection = calculateQiblaDirection();
                float targetDegree = qiblaDirection - azimuth;
                
                // Rotate compass
                RotateAnimation ra = new RotateAnimation(
                    currentDegree,
                    -azimuth,
                    Animation.RELATIVE_TO_SELF, 0.5f,
                    Animation.RELATIVE_TO_SELF, 0.5f
                );
                ra.setDuration(200);
                ra.setFillAfter(true);
                binding.ivCompass.startAnimation(ra);
                
                // Rotate qibla indicator
                RotateAnimation qiblaRa = new RotateAnimation(
                    currentDegree,
                    targetDegree,
                    Animation.RELATIVE_TO_SELF, 0.5f,
                    Animation.RELATIVE_TO_SELF, 0.5f
                );
                qiblaRa.setDuration(200);
                qiblaRa.setFillAfter(true);
                binding.ivQibla.startAnimation(qiblaRa);
                
                currentDegree = -azimuth;
                
                binding.tvDegree.setText(String.format("%.0f°", qiblaDirection));
            }
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // Not used
    }

    private float calculateQiblaDirection() {
        double phiK = Math.toRadians(KAABA_LAT);
        double lambdaK = Math.toRadians(KAABA_LNG);
        double phi = Math.toRadians(userLat);
        double lambda = Math.toRadians(userLng);
        
        double qibla = Math.atan2(
            Math.sin(lambdaK - lambda),
            Math.cos(phi) * Math.tan(phiK) - Math.sin(phi) * Math.cos(lambdaK - lambda)
        );
        
        return (float) ((Math.toDegrees(qibla) + 360) % 360);
    }

    private void updateQiblaDirection() {
        float qiblaDirection = calculateQiblaDirection();
        binding.tvDirection.setText("কিবলার দিক");
        binding.tvLocation.setText("ঢাকা, বাংলাদেশ");
    }
}
