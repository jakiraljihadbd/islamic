package com.islamiczone.org.ui.dua;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.google.android.material.card.MaterialCardView;
import com.islamiczone.org.R;
import java.util.List;

public class DuaCategoryAdapter extends RecyclerView.Adapter<DuaCategoryAdapter.ViewHolder> {
    private List<DuaCategory> categories;
    private OnCategoryClickListener listener;

    public interface OnCategoryClickListener {
        void onCategoryClick(DuaCategory category);
    }

    public DuaCategoryAdapter(List<DuaCategory> categories, OnCategoryClickListener listener) {
        this.categories = categories;
        this.listener = listener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_dua_category, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        DuaCategory category = categories.get(position);
        holder.tvName.setText(category.getName());
        holder.tvCount.setText(category.getDuaCount() + " টি দোয়া");
        holder.ivIcon.setImageResource(category.getIconResId());
        
        holder.cardView.setOnClickListener(v -> {
            if (listener != null) {
                listener.onCategoryClick(category);
            }
        });
    }

    @Override
    public int getItemCount() {
        return categories.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        MaterialCardView cardView;
        ImageView ivIcon;
        TextView tvName, tvCount;

        ViewHolder(View itemView) {
            super(itemView);
            cardView = itemView.findViewById(R.id.card_category);
            ivIcon = itemView.findViewById(R.id.iv_icon);
            tvName = itemView.findViewById(R.id.tv_name);
            tvCount = itemView.findViewById(R.id.tv_count);
        }
    }
}
