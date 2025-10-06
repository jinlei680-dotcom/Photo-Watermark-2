package com.photo.watermark.service;

import com.drew.imaging.ImageMetadataReader;
import com.drew.metadata.Metadata;
import com.drew.metadata.exif.ExifIFD0Directory;
import com.drew.metadata.exif.ExifSubIFDDirectory;

import java.io.File;
import java.nio.file.Path;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.Date;
import java.util.Optional;

public class MetadataExtractorExifService implements ExifService {
    @Override
    public Optional<LocalDate> readCaptureDate(Path path) {
        try {
            Metadata metadata = ImageMetadataReader.readMetadata(path.toFile());
            Date date = null;
            ExifSubIFDDirectory subIFD = metadata.getFirstDirectoryOfType(ExifSubIFDDirectory.class);
            if (subIFD != null) {
                date = subIFD.getDate(ExifSubIFDDirectory.TAG_DATETIME_ORIGINAL);
                if (date == null) {
                    date = subIFD.getDate(ExifSubIFDDirectory.TAG_DATETIME);
                }
            }
            if (date == null) {
                ExifIFD0Directory ifd0 = metadata.getFirstDirectoryOfType(ExifIFD0Directory.class);
                if (ifd0 != null) {
                    date = ifd0.getDate(ExifIFD0Directory.TAG_DATETIME);
                }
            }
            if (date != null) {
                return Optional.of(date.toInstant().atZone(ZoneId.systemDefault()).toLocalDate());
            }
        } catch (Exception e) {
            // ignore and return empty
        }
        return Optional.empty();
    }
}