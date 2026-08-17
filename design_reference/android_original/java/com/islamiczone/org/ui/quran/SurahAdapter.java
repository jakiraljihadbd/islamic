package com.islamiczone.org.ui.quran;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.google.android.material.card.MaterialCardView;
import com.islamiczone.org.R;
import java.util.List;

public class SurahAdapter extends RecyclerView.Adapter<SurahAdapter.ViewHolder> {
    private List<Surah> surahs;
    private OnSurahClickListener listener;

    public interface OnSurahClickListener {
        void onSurahClick(Surah surah);
    }

    public SurahAdapter(List<Surah> surahs, OnSurahClickListener listener) {
        this.surahs = surahs;
        this.listener = listener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_surah, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        Surah surah = surahs.get(position);
        holder.tvNumber.setText(String.valueOf(surah.getNumber()));
        holder.tvArabicName.setText(surah.getArabicName());
        holder.tvBanglaName.setText(surah.getBanglaName());
        holder.tvInfo.setText(surah.getRevelationType() + " • " + surah.getAyahCount() + " আয়াত");
        
        holder.cardView.setOnClickListener(v -> {
            if (listener != null) {
                listener.onSurahClick(surah);
            }
        });
    }

    @Override
    public int getItemCount() {
        return surahs.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        MaterialCardView cardView;
        TextView tvNumber, tvArabicName, tvBanglaName, tvInfo;

        ViewHolder(View itemView) {
            super(itemView);
            cardView = itemView.findViewById(R.id.card_surah);
            tvNumber = itemView.findViewById(R.id.tv_number);
            tvArabicName = itemView.findViewById(R.id.tv_arabic_name);
            tvBanglaName = itemView.findViewById(R.id.tv_bangla_name);
            tvInfo = itemView.findViewById(R.id.tv_info);
        }
    }
}
