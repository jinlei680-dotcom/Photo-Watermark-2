package com.photo.watermark.service;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Iterator;

public class ImageIOService {
    public BufferedImage load(Path path) throws IOException {
        return ImageIO.read(path.toFile());
    }

    public void ensureDirectory(Path dir) throws IOException {
        if (!Files.exists(dir)) {
            Files.createDirectories(dir);
        }
    }

    public String detectFormat(Path source) {
        String name = source.getFileName().toString().toLowerCase();
        if (name.endsWith(".png")) return "png";
        if (name.endsWith(".jpg") || name.endsWith(".jpeg")) return "jpg";
        return "jpg";
    }

    public void save(BufferedImage image, Path outFile, String format, float quality) throws IOException {
        if (format.equalsIgnoreCase("jpg") || format.equalsIgnoreCase("jpeg")) {
            Iterator<ImageWriter> writers = ImageIO.getImageWritersByFormatName("jpeg");
            ImageWriter writer = writers.hasNext() ? writers.next() : null;
            if (writer == null) throw new IOException("No JPEG writer available");
            try (ImageOutputStream ios = ImageIO.createImageOutputStream(outFile.toFile())) {
                writer.setOutput(ios);
                ImageWriteParam param = writer.getDefaultWriteParam();
                if (param.canWriteCompressed()) {
                    param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
                    param.setCompressionQuality(quality);
                }
                writer.write(null, new IIOImage(image, null, null), param);
            } finally {
                writer.dispose();
            }
        } else {
            ImageIO.write(image, format, outFile.toFile());
        }
    }
}