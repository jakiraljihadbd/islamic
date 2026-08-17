package com.islamiczone.org.ui.home;

public class QuickAction {
    private String title;
    private int iconResId;

    public QuickAction(String title, int iconResId) {
        this.title = title;
        this.iconResId = iconResId;
    }

    public String getTitle() {
        return title;
    }

    public int getIconResId() {
        return iconResId;
    }
}
