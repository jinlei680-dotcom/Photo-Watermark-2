package com.photo.watermark.service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.BasicFileAttributes;
import java.time.LocalDate;
import java.time.ZoneId;

public class FallbackDateProvider {
    public LocalDate fromFileAttributes(Path path) throws IOException {
        BasicFileAttributes attrs = Files.readAttributes(path, BasicFileAttributes.class);
        return attrs.creationTime().toInstant().atZone(ZoneId.systemDefault()).toLocalDate();
    }
}