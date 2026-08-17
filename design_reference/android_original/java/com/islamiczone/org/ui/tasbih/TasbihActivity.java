package com.islamiczone.org.ui.tasbih;

import android.os.Bundle;
import android.os.Vibrator;
import android.view.View;
import androidx.appcompat.app.AppCompatActivity;
import com.islamiczone.org.R;
import com.islamiczone.org.databinding.ActivityTasbihBinding;

public class TasbihActivity extends AppCompatActivity {
    private ActivityTasbihBinding binding;
    private int count = 0;
    private int totalCount = 0;
    private int targetCount = 33;
    private Vibrator vibrator;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityTasbihBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        vibrator = (Vibrator) getSystemService(VIBRATOR_SERVICE);
        setupUI();
        setupClickListeners();
    }

    private void setupUI() {
        updateCountDisplay();
        binding.tvTarget.setText("লক্ষ্য: " + targetCount);
    }

    private void setupClickListeners() {
        // Main counter button
        binding.btnCount.setOnClickListener(v -> {
            incrementCount();
        });

        // Reset button
        binding.btnReset.setOnClickListener(v -> {
            count = 0;
            updateCountDisplay();
        });

        // Target buttons
        binding.chip33.setOnClickListener(v -> setTarget(33));
        binding.chip99.setOnClickListener(v -> setTarget(99));
        binding.chip100.setOnClickListener(v -> setTarget(100));

        // Back button
        binding.btnBack.setOnClickListener(v -> finish());
    }

    private void incrementCount() {
        count++;
        totalCount++;
        
        // Vibrate
        if (vibrator != null) {
            vibrator.vibrate(50);
        }

        // Check if target reached
        if (count >= targetCount) {
            // Longer vibration for completion
            if (vibrator != null) {
                vibrator.vibrate(200);
            }
            count = 0;
        }

        updateCountDisplay();
    }

    private void setTarget(int target) {
        targetCount = target;
        count = 0;
        binding.tvTarget.setText("লক্ষ্য: " + targetCount);
        updateCountDisplay();
        
        // Update chip selection
        binding.chip33.setChecked(target == 33);
        binding.chip99.setChecked(target == 99);
        binding.chip100.setChecked(target == 100);
    }

    private void updateCountDisplay() {
        binding.tvCount.setText(String.valueOf(count));
        binding.tvTotal.setText("মোট: " + totalCount);
        
        // Update progress
        int progress = (int) ((count * 100.0f) / targetCount);
        binding.progressBar.setProgress(progress);
    }
}
