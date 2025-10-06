package com.photo.watermark.model;

import javafx.scene.paint.Color;

public class WatermarkSettings {
    private int fontSize;
    private Color color;
    private WatermarkPosition position;
    private int margin;

    public WatermarkSettings(int fontSize, Color color, WatermarkPosition position, int margin) {
        this.fontSize = fontSize;
        this.color = color;
        this.position = position;
        this.margin = margin;
    }

    public int getFontSize() { return fontSize; }
    public void setFontSize(int fontSize) { this.fontSize = fontSize; }

    public Color getColor() { return color; }
    public void setColor(Color color) { this.color = color; }

    public WatermarkPosition getPosition() { return position; }
    public void setPosition(WatermarkPosition position) { this.position = position; }

    public int getMargin() { return margin; }
    public void setMargin(int margin) { this.margin = margin; }
}