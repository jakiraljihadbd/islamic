package com.islamiczone.org.ui.more;

import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import com.islamiczone.org.R;
import com.islamiczone.org.databinding.FragmentMoreBinding;
import com.islamiczone.org.ui.tasbih.TasbihActivity;
import com.islamiczone.org.ui.qibla.QiblaActivity;
import java.util.ArrayList;
import java.util.List;

public class MoreFragment extends Fragment {
    private FragmentMoreBinding binding;

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        binding = FragmentMoreBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        setupMenuItems();
    }

    private void setupMenuItems() {
        List<MenuItem> items = new ArrayList<>();
        
        // Tools
        items.add(new MenuItem("তাসবিহ কাউন্টার", "ডিজিটাল তাসবিহ", R.drawable.img_tasbih, MenuItem.Type.TOOL));
        items.add(new MenuItem("কিবলা কম্পাস", "কিবলার দিক নির্ণয়", R.drawable.img_qibla, MenuItem.Type.TOOL));
        items.add(new MenuItem("যাকাত ক্যালকুলেটর", "যাকাত হিসাব", R.drawable.img_zakat, MenuItem.Type.TOOL));
        items.add(new MenuItem("আল্লাহর ৩৩ নাম", "আসমাউল হুসনা", R.drawable.img_names, MenuItem.Type.TOOL));
        items.add(new MenuItem("ইসলামিক ক্যালেন্ডার", "হিজরি তারিখ", R.drawable.img_calendar, MenuItem.Type.TOOL));
        
        // Learning
        items.add(new MenuItem("হাদিস শরীফ", "৬ টি হাদিস গ্রন্থ", R.drawable.img_hadith, MenuItem.Type.LEARNING));
        items.add(new MenuItem("রমজান", "সেহরি/ইফতার সময়", R.drawable.img_ramadan, MenuItem.Type.LEARNING));
        items.add(new MenuItem("হজ্জ ও উমরাহ", "সম্পূর্ণ গাইড", R.drawable.img_hajj, MenuItem.Type.LEARNING));
        
        // Settings
        items.add(new MenuItem("সেটিংস", "অ্যাপ সেটিংস", R.drawable.img_settings, MenuItem.Type.SETTINGS));
        items.add(new MenuItem("আমাদের সম্পর্কে", "অ্যাপ সম্পর্কে জানুন", R.drawable.img_info, MenuItem.Type.SETTINGS));

        MenuAdapter adapter = new MenuAdapter(items, this::onMenuItemClick);
        binding.rvMenu.setLayoutManager(new LinearLayoutManager(getContext()));
        binding.rvMenu.setAdapter(adapter);
    }

    private void onMenuItemClick(MenuItem item) {
        switch (item.getTitle()) {
            case "তাসবিহ কাউন্টার":
                startActivity(new Intent(getContext(), TasbihActivity.class));
                break;
            case "কিবলা কম্পাস":
                startActivity(new Intent(getContext(), QiblaActivity.class));
                break;
        }
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        binding = null;
    }
}
