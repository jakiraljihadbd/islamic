package com.islamiczone.org.ui.dua;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.GridLayoutManager;
import com.islamiczone.org.R;
import com.islamiczone.org.databinding.FragmentDuaBinding;
import java.util.ArrayList;
import java.util.List;

public class DuaFragment extends Fragment {
    private FragmentDuaBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = FragmentDuaBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        setupCategories();
    }

    private void setupCategories() {
        List<DuaCategory> categories = new ArrayList<>();
        categories.add(new DuaCategory("সকালের আজকার", R.drawable.ic_morning, 33));
        categories.add(new DuaCategory("সন্ধ্যার আজকার", R.drawable.ic_evening, 29));
        categories.add(new DuaCategory("ঘুমানোর দোয়া", R.drawable.ic_sleep, 15));
        categories.add(new DuaCategory("নামাজের দোয়া", R.drawable.ic_mosque, 25));
        categories.add(new DuaCategory("ভ্রমণের দোয়া", R.drawable.ic_travel, 18));
        categories.add(new DuaCategory("খাবারের দোয়া", R.drawable.ic_food, 12));
        categories.add(new DuaCategory("অসুস্থতার দোয়া", R.drawable.ic_health, 20));
        categories.add(new DuaCategory("বিবাহের দোয়া", R.drawable.ic_marriage, 10));
        categories.add(new DuaCategory("রুকিয়াহ", R.drawable.ic_ruqyah, 15));
        categories.add(new DuaCategory("ইস্তিগফার", R.drawable.ic_istighfar, 10));
        categories.add(new DuaCategory("দরুদ", R.drawable.ic_darood, 8));
        categories.add(new DuaCategory("কুরআনের দোয়া", R.drawable.ic_quran, 40));

        DuaCategoryAdapter adapter = new DuaCategoryAdapter(categories, category -> {
            // Open dua list
        });
        binding.rvCategories.setLayoutManager(new GridLayoutManager(getContext(), 2));
        binding.rvCategories.setAdapter(adapter);
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
