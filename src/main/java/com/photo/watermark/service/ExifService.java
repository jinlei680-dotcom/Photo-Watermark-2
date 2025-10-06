package com.photo.watermark.service;

import java.nio.file.Path;
import java.time.LocalDate;
import java.util.Optional;

public interface ExifService {
    Optional<LocalDate> readCaptureDate(Path path);
}