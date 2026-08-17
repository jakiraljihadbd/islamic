package com.islamiczone.org.ui.home;

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

public class QuickActionAdapter extends RecyclerView.Adapter<QuickActionAdapter.ViewHolder> {
    private List<QuickAction> actions;
    private OnActionClickListener listener;

    public interface OnActionClickListener {
        void onActionClick(QuickAction action);
    }

    public QuickActionAdapter(List<QuickAction> actions, OnActionClickListener listener) {
        this.actions = actions;
        this.listener = listener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_quick_action, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
        QuickAction action = actions.get(position);
        holder.tvTitle.setText(action.getTitle());
        holder.ivIcon.setImageResource(action.getIconResId());
        holder.cardView.setOnClickListener(v -> {
            if (listener != null) {
                listener.onActionClick(action);
            }
        });
    }

    @Override
    public int getItemCount() {
        return actions.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        MaterialCardView cardView;
        ImageView ivIcon;
        TextView tvTitle;

        ViewHolder(View itemView) {
            super(itemView);
            cardView = itemView.findViewById(R.id.card_action);
            ivIcon = itemView.findViewById(R.id.iv_icon);
            tvTitle = itemView.findViewById(R.id.tv_title);
        }
    }
}
