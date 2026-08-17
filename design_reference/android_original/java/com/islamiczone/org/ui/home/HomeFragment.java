package com.islamiczone.org.ui.home;

import android.content.Intent;
import android.graphics.Typeface;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.core.content.res.ResourcesCompat;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.GridLayoutManager;
import com.islamiczone.org.R;
import com.islamiczone.org.databinding.FragmentHomeBinding;
import com.islamiczone.org.ui.tasbih.TasbihActivity;
import com.islamiczone.org.ui.qibla.QiblaActivity;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class HomeFragment extends Fragment {

    private static class Petal {
        final View layout;
        final String name;
        final String time;
        final int drawableGreen;
        final int drawableBlue;
        Petal(View layout, String name, String time, int drawableGreen, int drawableBlue) {
            this.layout = layout; this.name = name; this.time = time;
            this.drawableGreen = drawableGreen; this.drawableBlue = drawableBlue;
        }
    }

    private FragmentHomeBinding binding;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private Runnable timeRunnable;
    private Runnable revertRunnable;
    private Petal[] petals;
    private int activeIndex = 0;
    private Integer selectedIndex = null;

    @Nullable @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = FragmentHomeBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        setupHeader();
        setupPrayerFlower();
        setupQuickActions();
        setupTodaysVerse();
        startTimeUpdater();
    }

    private void setupHeader() {
        SimpleDateFormat dateFormat = new SimpleDateFormat("EEEE, dd MMMM yyyy", new Locale("bn"));
        binding.tvDate.setText(dateFormat.format(new Date()));
        binding.tvHijriDate.setText("১৫ জুমাদাল আউয়াল ১৪৪৬");
        binding.tvLocation.setText("ঢাকা, বাংলাদেশ");
    }

    private void setupPrayerFlower() {
        SimpleDateFormat tf = new SimpleDateFormat("h:mm a", new Locale("bn"));
        binding.tvCurrentTime.setText(tf.format(new Date()));

        binding.tvFajrTime.setText("৫:০০ AM");
        binding.tvSunriseTime.setText("৬:১৫ AM");
        binding.tvDhuhrTime.setText("১২:৩০ PM");
        binding.tvAsrTime.setText("৪:৩০ PM");
        binding.tvMaghribTime.setText("৬:১৫ PM");
        binding.tvIshaTime.setText("৭:৩০ PM");

        petals = new Petal[]{
            new Petal(binding.layoutFajr,    "ফজর",     "৫:০০ AM",  R.drawable.img_flower_fajr_green,    R.drawable.img_flower_fajr_blue),
            new Petal(binding.layoutSunrise, "সূর্যোদয়", "৬:১৫ AM",  R.drawable.img_flower_sunrise_green, R.drawable.img_flower_sunrise_blue),
            new Petal(binding.layoutDhuhr,   "যোহর",    "১২:৩০ PM", R.drawable.img_flower_dhuhr_green,   R.drawable.img_flower_dhuhr_blue),
            new Petal(binding.layoutAsr,     "আসর",     "৪:৩০ PM",  R.drawable.img_flower_asr_green,     R.drawable.img_flower_asr_blue),
            new Petal(binding.layoutMaghrib, "মাগরিব",  "৬:১৫ PM",  R.drawable.img_flower_maghrib_green, R.drawable.img_flower_maghrib_blue),
            new Petal(binding.layoutIsha,    "ইশা",     "৭:৩০ PM",  R.drawable.img_flower_isha_green,    R.drawable.img_flower_isha_blue),
        };

        for (int i = 0; i < petals.length; i++) {
            final int idx = i;
            petals[i].layout.setOnClickListener(v -> onPetalTapped(idx));
        }

        activeIndex = calcActiveIndex();
        binding.ivFlowerBg.setImageResource(petals[activeIndex].drawableGreen);
        highlightLabel(activeIndex);
    }

    private void onPetalTapped(int index) {
        selectedIndex = index;
        Toast.makeText(getContext(), petals[index].name + " — " + petals[index].time, Toast.LENGTH_SHORT).show();
        spinToFlower(petals[index].drawableBlue);
        highlightLabel(index);
        if (revertRunnable != null) handler.removeCallbacks(revertRunnable);
        revertRunnable = () -> {
            selectedIndex = null;
            spinToFlower(petals[activeIndex].drawableGreen);
            highlightLabel(activeIndex);
        };
        handler.postDelayed(revertRunnable, 2500);
    }

    private int calcActiveIndex() {
        int h = Calendar.getInstance().get(Calendar.HOUR_OF_DAY);
        if (h >= 19 || h < 5) return 5;
        if (h >= 18) return 4;
        if (h >= 16) return 3;
        if (h >= 12) return 2;
        if (h >= 6)  return 1;
        return 0;
    }

    private void spinToFlower(int drawableRes) {
        if (binding == null) return;
        binding.ivFlowerBg.animate().cancel();
        binding.ivFlowerBg.animate()
            .rotationBy(180f).scaleX(0.92f).scaleY(0.92f).setDuration(200)
            .withEndAction(() -> {
                if (binding == null) return;
                binding.ivFlowerBg.setImageResource(drawableRes);
                binding.ivFlowerBg.animate()
                    .rotationBy(180f).scaleX(1f).scaleY(1f).setDuration(200).start();
            }).start();
    }

    private void highlightLabel(int index) {
        for (int i = 0; i < petals.length; i++) {
            int colorRes = (i == index) ? R.color.primary : R.color.on_surface;
            setPetalTextColor(petals[i].layout, colorRes);
        }
    }

    private void setPetalTextColor(View petalLayout, int colorRes) {
        if (!(petalLayout instanceof ViewGroup)) return;
        int color = ContextCompat.getColor(requireContext(), colorRes);
        for (int i = 0; i < ((ViewGroup) petalLayout).getChildCount(); i++) {
            View child = ((ViewGroup) petalLayout).getChildAt(i);
            if (child instanceof TextView) ((TextView) child).setTextColor(color);
        }
    }

    private void setupQuickActions() {
        List<QuickAction> actions = new ArrayList<>();
        actions.add(new QuickAction("কুরআন",  R.drawable.img_quran));
        actions.add(new QuickAction("হাদিস",  R.drawable.img_hadith));
        actions.add(new QuickAction("তাসবিহ", R.drawable.img_tasbih));
        actions.add(new QuickAction("কিবলা",  R.drawable.img_qibla));
        actions.add(new QuickAction("যাকাত",  R.drawable.img_zakat));
        actions.add(new QuickAction("রমজান",  R.drawable.img_ramadan));
        actions.add(new QuickAction("হজ্জ",   R.drawable.img_hajj));
        actions.add(new QuickAction("আরো",    R.drawable.img_more));

        QuickActionAdapter adapter = new QuickActionAdapter(actions, this::onQuickActionClick);
        binding.rvQuickActions.setLayoutManager(new GridLayoutManager(getContext(), 4));
        binding.rvQuickActions.setAdapter(adapter);
    }

    private void onQuickActionClick(QuickAction action) {
        switch (action.getTitle()) {
            case "তাসবিহ": startActivity(new Intent(getContext(), TasbihActivity.class)); break;
            case "কিবলা":  startActivity(new Intent(getContext(), QiblaActivity.class));  break;
        }
    }

    private void setupTodaysVerse() {
        Typeface arabicFont = ResourcesCompat.getFont(requireContext(), R.font.arabic);
        Typeface bahijFont  = ResourcesCompat.getFont(requireContext(), R.font.bahij);
        if (arabicFont != null) binding.tvArabicVerse.setTypeface(arabicFont);
        if (bahijFont  != null) binding.tvBanglaVerse.setTypeface(bahijFont);
        binding.tvArabicVerse.setText("إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ");
        binding.tvBanglaVerse.setText("নিশ্চয়ই আমি তোমাকে কাউসার (জান্নাতের নহর) দান করেছি।");
        binding.tvVerseReference.setText("সূরা আল-কাউসার: ১");
    }

    private void startTimeUpdater() {
        timeRunnable = new Runnable() {
            @Override public void run() {
                updateClock();
                handler.postDelayed(this, 60000);
            }
        };
        handler.post(timeRunnable);
    }

    private void updateClock() {
        if (binding == null || petals == null) return;
        SimpleDateFormat tf = new SimpleDateFormat("h:mm a", new Locale("bn"));
        binding.tvCurrentTime.setText(tf.format(new Date()));
        int newIndex = calcActiveIndex();
        boolean changed = newIndex != activeIndex;
        activeIndex = newIndex;
        if (selectedIndex == null) {
            if (changed) spinToFlower(petals[activeIndex].drawableGreen);
            else binding.ivFlowerBg.setImageResource(petals[activeIndex].drawableGreen);
            highlightLabel(activeIndex);
        }
    }

    @Override public void onDestroyView() {
        super.onDestroyView();
        if (handler != null) {
            if (timeRunnable  != null) handler.removeCallbacks(timeRunnable);
            if (revertRunnable!= null) handler.removeCallbacks(revertRunnable);
        }
        binding = null;
    }
}
