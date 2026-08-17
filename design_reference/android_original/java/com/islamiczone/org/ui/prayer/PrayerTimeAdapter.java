package com.islamiczone.org.ui.prayer;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;
import com.google.android.material.card.MaterialCardView;
import com.islamiczone.org.R;
import java.util.List;

public class PrayerTimeAdapter extends RecyclerView.Adapter<PrayerTimeAdapter.ViewHolder> {
    private List<PrayerTime> prayerTimes;

    public PrayerTimeAdapter(List<PrayerTime> prayerTimes) {
        this.prayerTimes = prayerTimes;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_prayer_time, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        PrayerTime prayer = prayerTimes.get(position);
        holder.tvName.setText(prayer.getName());
        holder.tvTime.setText(prayer.getTime());
        
        int color = ContextCompat.getColor(holder.itemView.getContext(), prayer.getColorResId());
        holder.colorIndicator.setBackgroundColor(color);
        
        if (prayer.isNext()) {
            holder.cardView.setStrokeColor(color);
            holder.cardView.setStrokeWidth(4);
            holder.tvNext.setVisibility(View.VISIBLE);
        } else {
            holder.cardView.setStrokeWidth(0);
            holder.tvNext.setVisibility(View.GONE);
        }
    }

    @Override
    public int getItemCount() {
        return prayerTimes.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        MaterialCardView cardView;
        View colorIndicator;
        TextView tvName, tvTime, tvNext;
        ImageView ivAlarm;

        ViewHolder(View itemView) {
            super(itemView);
            cardView = itemView.findViewById(R.id.card_prayer);
            colorIndicator = itemView.findViewById(R.id.color_indicator);
            tvName = itemView.findViewById(R.id.tv_prayer_name);
            tvTime = itemView.findViewById(R.id.tv_prayer_time);
            tvNext = itemView.findViewById(R.id.tv_next);
            ivAlarm = itemView.findViewById(R.id.iv_alarm);
        }
    }
}
