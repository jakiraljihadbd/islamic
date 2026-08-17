package com.islamiczone.org.ui.quran;

import android.graphics.Bitmap;
import android.graphics.pdf.PdfRenderer;
import android.os.Bundle;
import android.os.ParcelFileDescriptor;
import android.view.View;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import com.islamiczone.org.R;
import com.islamiczone.org.databinding.ActivityQuranPdfBinding;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

public class QuranPdfActivity extends AppCompatActivity {

    private ActivityQuranPdfBinding binding;
    private PdfRenderer pdfRenderer;
    private PdfRenderer.Page currentPage;
    private ParcelFileDescriptor fileDescriptor;
    private int pageIndex = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityQuranPdfBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        binding.btnBack.setOnClickListener(v -> finish());
        binding.btnNext.setOnClickListener(v -> showPage(pageIndex + 1));
        binding.btnPrev.setOnClickListener(v -> showPage(pageIndex - 1));

        openRenderer();
    }

    private void openRenderer() {
        try {
            File cacheFile = new File(getCacheDir(), "quran.pdf");
            if (!cacheFile.exists()) {
                copyAssetToCache(cacheFile);
            }
            fileDescriptor = ParcelFileDescriptor.open(cacheFile, ParcelFileDescriptor.MODE_READ_ONLY);
            pdfRenderer = new PdfRenderer(fileDescriptor);
            showPage(0);
        } catch (IOException e) {
            Toast.makeText(this, "কুরআন পিডিএফ খুলতে সমস্যা হয়েছে", Toast.LENGTH_SHORT).show();
            finish();
        }
    }

    private void copyAssetToCache(File outFile) throws IOException {
        try (InputStream in = getAssets().open("quran.pdf");
             FileOutputStream out = new FileOutputStream(outFile)) {
            byte[] buffer = new byte[8192];
            int len;
            while ((len = in.read(buffer)) != -1) {
                out.write(buffer, 0, len);
            }
        }
    }

    private void showPage(int index) {
        if (pdfRenderer == null || index < 0 || index >= pdfRenderer.getPageCount()) {
            return;
        }
        binding.progressBar.setVisibility(View.VISIBLE);

        if (currentPage != null) {
            currentPage.close();
        }

        pageIndex = index;
        currentPage = pdfRenderer.openPage(pageIndex);

        Bitmap bitmap = Bitmap.createBitmap(
                currentPage.getWidth() * 2,
                currentPage.getHeight() * 2,
                Bitmap.Config.ARGB_8888);
        currentPage.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY);

        binding.ivPdfPage.setImageBitmap(bitmap);
        binding.tvPageNumber.setText((pageIndex + 1) + " / " + pdfRenderer.getPageCount());
        binding.progressBar.setVisibility(View.GONE);

        binding.btnPrev.setEnabled(pageIndex > 0);
        binding.btnNext.setEnabled(pageIndex < pdfRenderer.getPageCount() - 1);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        try {
            if (currentPage != null) currentPage.close();
            if (pdfRenderer != null) pdfRenderer.close();
            if (fileDescriptor != null) fileDescriptor.close();
        } catch (IOException ignored) {
        }
    }
}
