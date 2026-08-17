package com.islamiczone.org.ui.prayer;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.islamiczone.org.R;
import com.islamiczone.org.databinding.FragmentPrayerBinding;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Locale;

public class PrayerFragment extends Fragment {
    private FragmentPrayerBinding binding;

    @Nullable @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = FragmentPrayerBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        setupHeader();
        setupPrayerTimes();
    }

    private void setupHeader() {
        SimpleDateFormat df = new SimpleDateFormat("dd MMMM yyyy", new Locale("bn"));
        binding.tvDate.setText(df.format(new Date()));
        binding.tvLocation.setText("ঢাকা, বাংলাদেশ");
    }

    private int getNextPrayerIndex() {
        Calendar cal = Calendar.getInstance();
        int now = cal.get(Calendar.HOUR_OF_DAY) * 60 + cal.get(Calendar.MINUTE);
        int[] times = {5*60, 6*60+15, 12*60+30, 16*60+30, 18*60+15, 19*60+30};
        for (int i = 0; i < times.length; i++) if (now < times[i]) return i;
        return 0;
    }

    private void setupPrayerTimes() {
        int next = getNextPrayerIndex();
        List<PrayerTime> list = new ArrayList<>();
        list.add(new PrayerTime("ফজর",     "5:00 AM",  R.color.prayer_fajr,    next == 0));
        list.add(new PrayerTime("সূর্যোদয়","6:15 AM",  R.color.prayer_sunrise, next == 1));
        list.add(new PrayerTime("যোহর",    "12:30 PM", R.color.prayer_dhuhr,   next == 2));
        list.add(new PrayerTime("আসর",     "4:30 PM",  R.color.prayer_asr,     next == 3));
        list.add(new PrayerTime("মাগরিব",  "6:15 PM",  R.color.prayer_maghrib, next == 4));
        list.add(new PrayerTime("ইশা",     "7:30 PM",  R.color.prayer_isha,    next == 5));
        PrayerTimeAdapter adapter = new PrayerTimeAdapter(list);
        binding.rvPrayerTimes.setLayoutManager(new LinearLayoutManager(getContext()));
        binding.rvPrayerTimes.setAdapter(adapter);
    }

    @Override public void onDestroyView() { super.onDestroyView(); binding = null; }
}
