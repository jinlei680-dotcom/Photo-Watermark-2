package com.photo.watermark.service;

import com.photo.watermark.model.WatermarkPosition;
import com.photo.watermark.model.WatermarkSettings;

import java.awt.*;
import java.awt.image.BufferedImage;

public class WatermarkService {
    public BufferedImage applyWatermark(BufferedImage src, String text, WatermarkSettings settings) {
        BufferedImage copy = new BufferedImage(src.getWidth(), src.getHeight(), BufferedImage.TYPE_INT_ARGB);
        Graphics2D g = copy.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.drawImage(src, 0, 0, null);

        Font font = new Font(Font.SANS_SERIF, Font.PLAIN, settings.getFontSize());
        g.setFont(font);
        FontMetrics metrics = g.getFontMetrics();
        int textW = metrics.stringWidth(text);
        int textH = metrics.getHeight();
        int ascent = metrics.getAscent();

        int x, y;
        switch (settings.getPosition()) {
            case TOP_LEFT -> {
                x = settings.getMargin();
                y = settings.getMargin() + ascent;
            }
            case CENTER -> {
                x = (src.getWidth() - textW) / 2;
                y = (src.getHeight() - textH) / 2 + ascent;
            }
            case BOTTOM_RIGHT -> {
                x = src.getWidth() - textW - settings.getMargin();
                y = src.getHeight() - settings.getMargin();
            }
            default -> {
                x = settings.getMargin();
                y = settings.getMargin() + ascent;
            }
        }

        Color awtColor = new Color((float) settings.getColor().getRed(), (float) settings.getColor().getGreen(), (float) settings.getColor().getBlue(), 1.0f);
        g.setColor(awtColor);
        g.drawString(text, x, y);
        g.dispose();
        return copy;
    }
}