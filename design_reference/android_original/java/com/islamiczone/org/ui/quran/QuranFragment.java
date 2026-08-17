package com.islamiczone.org.ui.quran;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.islamiczone.org.databinding.FragmentQuranBinding;
import java.util.ArrayList;
import java.util.List;

public class QuranFragment extends Fragment {
    private FragmentQuranBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = FragmentQuranBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        setupSurahList();
        binding.btnReadQuran.setOnClickListener(v ->
                startActivity(new Intent(getContext(), QuranPdfActivity.class)));
    }

    private void setupSurahList() {
        List<Surah> surahs = getSurahList();
        SurahAdapter adapter = new SurahAdapter(surahs, surah -> {
            // Open Surah detail
        });
        binding.rvSurahs.setLayoutManager(new LinearLayoutManager(getContext()));
        binding.rvSurahs.setAdapter(adapter);
    }

    private List<Surah> getSurahList() {
        List<Surah> surahs = new ArrayList<>();
        surahs.add(new Surah(1, "الفاتحة", "আল-ফাতিহা", "The Opening", 7, "মক্কা"));
        surahs.add(new Surah(2, "البقرة", "আল-বাকারা", "The Cow", 286, "মদিনা"));
        surahs.add(new Surah(3, "آل عمران", "আলে ইমরান", "The Family of Imran", 200, "মদিনা"));
        surahs.add(new Surah(4, "النساء", "আন-নিসা", "The Women", 176, "মদিনা"));
        surahs.add(new Surah(5, "المائدة", "আল-মায়িদাহ", "The Table Spread", 120, "মদিনা"));
        surahs.add(new Surah(6, "الأنعام", "আল-আনআম", "The Cattle", 165, "মক্কা"));
        surahs.add(new Surah(7, "الأعراف", "আল-আরাফ", "The Heights", 206, "মক্কা"));
        surahs.add(new Surah(8, "الأنفال", "আল-আনফাল", "The Spoils of War", 75, "মদিনা"));
        surahs.add(new Surah(9, "التوبة", "আত-তাওবাহ", "The Repentance", 129, "মদিনা"));
        surahs.add(new Surah(10, "يونس", "ইউনুস", "Jonah", 109, "মক্কা"));
        // Add more surahs...
        surahs.add(new Surah(112, "الإخلاص", "আল-ইখলাস", "The Sincerity", 4, "মক্কা"));
        surahs.add(new Surah(113, "الفلق", "আল-ফালাক", "The Daybreak", 5, "মক্কা"));
        surahs.add(new Surah(114, "الناس", "আন-নাস", "Mankind", 6, "মক্কা"));
        return surahs;
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
