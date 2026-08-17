package com.islamiczone.org.ui.dua;

public class DuaCategory {
    private String name;
    private int iconResId;
    private int duaCount;

    public DuaCategory(String name, int iconResId, int duaCount) {
        this.name = name;
        this.iconResId = iconResId;
        this.duaCount = duaCount;
    }

    public String getName() { return name; }
    public int getIconResId() { return iconResId; }
    public int getDuaCount() { return duaCount; }
}
