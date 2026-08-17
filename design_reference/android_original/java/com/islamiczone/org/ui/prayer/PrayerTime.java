package com.islamiczone.org.ui.prayer;

public class PrayerTime {
    private String name;
    private String time;
    private int colorResId;
    private boolean isNext;

    public PrayerTime(String name, String time, int colorResId, boolean isNext) {
        this.name = name;
        this.time = time;
        this.colorResId = colorResId;
        this.isNext = isNext;
    }

    public String getName() { return name; }
    public String getTime() { return time; }
    public int getColorResId() { return colorResId; }
    public boolean isNext() { return isNext; }
}
