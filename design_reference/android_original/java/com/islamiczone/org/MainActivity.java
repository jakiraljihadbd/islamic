package com.islamiczone.org;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;
import com.islamiczone.org.databinding.ActivityMainBinding;
import com.islamiczone.org.ui.home.HomeFragment;
import com.islamiczone.org.ui.quran.QuranFragment;
import com.islamiczone.org.ui.prayer.PrayerFragment;
import com.islamiczone.org.ui.dua.DuaFragment;
import com.islamiczone.org.ui.more.MoreFragment;

public class MainActivity extends AppCompatActivity {
    private ActivityMainBinding binding;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        setupBottomNavigation();

        if (savedInstanceState == null) {
            loadFragment(new HomeFragment());
        }
    }

    private void setupBottomNavigation() {
        binding.bottomNavigation.setOnItemSelectedListener(item -> {
            Fragment fragment = null;
            int itemId = item.getItemId();

            if (itemId == R.id.nav_home) {
                fragment = new HomeFragment();
            } else if (itemId == R.id.nav_quran) {
                fragment = new QuranFragment();
            } else if (itemId == R.id.nav_prayer) {
                fragment = new PrayerFragment();
            } else if (itemId == R.id.nav_dua) {
                fragment = new DuaFragment();
            } else if (itemId == R.id.nav_more) {
                fragment = new MoreFragment();
            }

            return loadFragment(fragment);
        });
    }

    private boolean loadFragment(Fragment fragment) {
        if (fragment != null) {
            getSupportFragmentManager()
                .beginTransaction()
                .replace(R.id.fragment_container, fragment)
                .commit();
            return true;
        }
        return false;
    }
}
