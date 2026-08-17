package com.islamiczone.org.ui.quran;

public class Surah {
    private int number;
    private String arabicName;
    private String banglaName;
    private String englishName;
    private int ayahCount;
    private String revelationType;

    public Surah(int number, String arabicName, String banglaName, String englishName, int ayahCount, String revelationType) {
        this.number = number;
        this.arabicName = arabicName;
        this.banglaName = banglaName;
        this.englishName = englishName;
        this.ayahCount = ayahCount;
        this.revelationType = revelationType;
    }

    public int getNumber() { return number; }
    public String getArabicName() { return arabicName; }
    public String getBanglaName() { return banglaName; }
    public String getEnglishName() { return englishName; }
    public int getAyahCount() { return ayahCount; }
    public String getRevelationType() { return revelationType; }
}
