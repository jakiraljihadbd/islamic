package com.islamiczone.org.ui.more;

public class MenuItem {
    public enum Type { TOOL, LEARNING, SETTINGS }
    
    private String title;
    private String subtitle;
    private int iconResId;
    private Type type;

    public MenuItem(String title, String subtitle, int iconResId, Type type) {
        this.title = title;
        this.subtitle = subtitle;
        this.iconResId = iconResId;
        this.type = type;
    }

    public String getTitle() { return title; }
    public String getSubtitle() { return subtitle; }
    public int getIconResId() { return iconResId; }
    public Type getType() { return type; }
}
