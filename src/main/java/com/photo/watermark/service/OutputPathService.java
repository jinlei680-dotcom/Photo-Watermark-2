package com.photo.watermark.service;

import java.nio.file.Path;
import java.nio.file.Paths;

public class OutputPathService {
    public Path resolveOutputDir(Path source) {
        Path parent = source.getParent();
        String dirName = parent.getFileName().toString();
        return parent.resolve(dirName + "_watermark");
    }

    public Path resolveOutputFile(Path source) {
        Path parent = source.getParent();
        String name = source.getFileName().toString();
        int dot = name.lastIndexOf('.');
        String base = dot > 0 ? name.substring(0, dot) : name;
        String ext = dot > 0 ? name.substring(dot) : "";
        return resolveOutputDir(source).resolve(base + "_watermark" + ext);
    }
}