package com.photo.watermark;

import com.photo.watermark.model.WatermarkPosition;
import com.photo.watermark.model.WatermarkSettings;
import com.photo.watermark.service.*;
import javafx.application.Application;
import javafx.geometry.Insets;
import javafx.geometry.Pos;
import javafx.scene.Scene;
import javafx.scene.canvas.Canvas;
import javafx.scene.canvas.GraphicsContext;
import javafx.scene.control.*;
import javafx.scene.image.Image;
import javafx.scene.image.ImageView;
import javafx.scene.layout.*;
import javafx.scene.paint.Color;
import javafx.scene.text.Font;
import javafx.scene.text.Text;
import javafx.stage.FileChooser;
import javafx.stage.Stage;

import java.awt.image.BufferedImage;
import java.io.File;
import java.nio.file.Path;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

public class MainApp extends Application {
    private final ExifService exifService = new MetadataExtractorExifService();
    private final ImageIOService imageIOService = new ImageIOService();
    private final OutputPathService outputPathService = new OutputPathService();
    private final FallbackDateProvider fallbackDateProvider = new FallbackDateProvider();
    private final WatermarkService watermarkService = new WatermarkService();

    private final WatermarkSettings settings = new WatermarkSettings(24, Color.WHITE, WatermarkPosition.BOTTOM_RIGHT, 16);

    private final Label statusBar = new Label("请选择图片");
    private final ImageView imageView = new ImageView();
    private final Canvas overlay = new Canvas();

    private Path currentImagePath;
    private BufferedImage currentBufferedImage;
    private String watermarkText;

    @Override
    public void start(Stage stage) {
        stage.setTitle("Photo Watermark");

        BorderPane root = new BorderPane();
        root.setTop(buildMenuBar(stage));
        root.setRight(buildSettingsPane());
        root.setBottom(buildStatusBar());
        root.setCenter(buildPreviewPane());

        Scene scene = new Scene(root, 1000, 700);
        stage.setScene(scene);
        stage.show();

        // Keep overlay sized to imageView view size
        imageView.fitWidthProperty().bind(((Region) root.getCenter()).widthProperty());
        imageView.fitHeightProperty().bind(((Region) root.getCenter()).heightProperty());
        imageView.setPreserveRatio(true);

        ((Region) root.getCenter()).widthProperty().addListener((obs, oldV, newV) -> resizeOverlay());
        ((Region) root.getCenter()).heightProperty().addListener((obs, oldV, newV) -> resizeOverlay());
    }

    private MenuBar buildMenuBar(Stage stage) {
        Menu fileMenu = new Menu("文件");
        MenuItem openItem = new MenuItem("打开");
        MenuItem saveItem = new MenuItem("保存");
        openItem.setOnAction(e -> openImage(stage));
        saveItem.setOnAction(e -> saveWatermarked());
        fileMenu.getItems().addAll(openItem, saveItem);

        Menu helpMenu = new Menu("帮助");
        MenuItem aboutItem = new MenuItem("关于");
        aboutItem.setOnAction(e -> new Alert(Alert.AlertType.INFORMATION, "Photo Watermark - 在图片上添加拍摄日期水印").showAndWait());
        helpMenu.getItems().add(aboutItem);

        return new MenuBar(fileMenu, helpMenu);
    }

    private Pane buildPreviewPane() {
        StackPane stack = new StackPane();
        stack.setStyle("-fx-background-color: #2b2b2b;");
        imageView.setSmooth(true);
        overlay.setMouseTransparent(true);
        StackPane.setAlignment(overlay, Pos.TOP_LEFT);
        stack.getChildren().addAll(imageView, overlay);

        BorderPane wrapper = new BorderPane(stack);
        return wrapper;
    }

    private VBox buildSettingsPane() {
        VBox box = new VBox(10);
        box.setPadding(new Insets(12));
        box.setPrefWidth(280);
        Label title = new Label("水印设置");
        title.setStyle("-fx-font-size: 16px; -fx-font-weight: bold;");

        // Font size
        Spinner<Integer> fontSize = new Spinner<>(12, 96, settings.getFontSize());
        fontSize.valueProperty().addListener((obs, o, n) -> {
            settings.setFontSize(n);
            redrawOverlay();
        });

        // Color picker
        ColorPicker colorPicker = new ColorPicker(settings.getColor());
        colorPicker.valueProperty().addListener((obs, o, n) -> {
            settings.setColor(n);
            redrawOverlay();
        });

        // Position
        ChoiceBox<WatermarkPosition> positionChoice = new ChoiceBox<>();
        positionChoice.getItems().addAll(WatermarkPosition.TOP_LEFT, WatermarkPosition.CENTER, WatermarkPosition.BOTTOM_RIGHT);
        positionChoice.setValue(settings.getPosition());
        positionChoice.valueProperty().addListener((obs, o, n) -> {
            settings.setPosition(n);
            redrawOverlay();
        });

        // Margin
        Spinner<Integer> marginSpinner = new Spinner<>(0, 256, settings.getMargin());
        marginSpinner.valueProperty().addListener((obs, o, n) -> {
            settings.setMargin(n);
            redrawOverlay();
        });

        GridPane form = new GridPane();
        form.setHgap(8);
        form.setVgap(8);
        form.add(new Label("字体大小"), 0, 0); form.add(fontSize, 1, 0);
        form.add(new Label("颜色"), 0, 1); form.add(colorPicker, 1, 1);
        form.add(new Label("位置"), 0, 2); form.add(positionChoice, 1, 2);
        form.add(new Label("边距"), 0, 3); form.add(marginSpinner, 1, 3);

        box.getChildren().addAll(title, form);
        return box;
    }

    private Pane buildStatusBar() {
        HBox bar = new HBox(statusBar);
        bar.setPadding(new Insets(6));
        bar.setStyle("-fx-background-color: #ececec;");
        return bar;
    }

    private void openImage(Stage stage) {
        FileChooser chooser = new FileChooser();
        chooser.setTitle("选择图片");
        chooser.getExtensionFilters().addAll(
                new FileChooser.ExtensionFilter("图片", "*.jpg", "*.jpeg", "*.png", "*.JPG", "*.JPEG", "*.PNG")
        );
        File file = chooser.showOpenDialog(stage);
        if (file == null) return;
        try {
            currentImagePath = file.toPath();
            Image fxImage = new Image(file.toURI().toString());
            imageView.setImage(fxImage);
            currentBufferedImage = imageIOService.load(currentImagePath);

            Optional<LocalDate> exifDate = exifService.readCaptureDate(currentImagePath);
            if (exifDate.isPresent()) {
                watermarkText = exifDate.get().format(DateTimeFormatter.ISO_DATE);
                statusBar.setText("已读取拍摄日期：" + watermarkText);
            } else {
                // fallback: offer manual input or file creation date
                Alert alert = new Alert(Alert.AlertType.CONFIRMATION);
                alert.setTitle("缺少EXIF日期");
                alert.setHeaderText("未找到拍摄日期");
                alert.setContentText("请选择替代方案：\n- 使用文件创建日期\n- 手动输入 YYYY-MM-DD");
                ButtonType useFileDate = new ButtonType("使用文件创建日期", ButtonBar.ButtonData.YES);
                ButtonType manualInput = new ButtonType("手动输入", ButtonBar.ButtonData.NO);
                alert.getButtonTypes().setAll(useFileDate, manualInput, ButtonType.CANCEL);

                ButtonType choice = alert.showAndWait().orElse(ButtonType.CANCEL);
                if (choice == manualInput) {
                    TextInputDialog td = new TextInputDialog(LocalDate.now().format(DateTimeFormatter.ISO_DATE));
                    td.setTitle("输入拍摄日期");
                    td.setHeaderText("请输入日期（YYYY-MM-DD）");
                    Optional<String> input = td.showAndWait();
                    if (input.isPresent()) {
                        watermarkText = input.get();
                        statusBar.setText("使用手动日期：" + watermarkText);
                    } else {
                        LocalDate fb = fallbackDateProvider.fromFileAttributes(currentImagePath);
                        watermarkText = fb.format(DateTimeFormatter.ISO_DATE);
                        statusBar.setText("未输入，使用文件创建日期：" + watermarkText);
                    }
                } else if (choice == useFileDate) {
                    LocalDate fb = fallbackDateProvider.fromFileAttributes(currentImagePath);
                    watermarkText = fb.format(DateTimeFormatter.ISO_DATE);
                    statusBar.setText("使用文件创建日期：" + watermarkText);
                } else {
                    watermarkText = null;
                    statusBar.setText("已取消日期选择");
                }
            }
            resizeOverlay();
            redrawOverlay();
        } catch (Exception ex) {
            statusBar.setText("打开失败：" + ex.getMessage());
            new Alert(Alert.AlertType.ERROR, "打开图片失败: " + ex.getMessage()).showAndWait();
        }
    }

    private void saveWatermarked() {
        if (currentBufferedImage == null || currentImagePath == null || watermarkText == null) {
            new Alert(Alert.AlertType.WARNING, "请先打开图片").showAndWait();
            return;
        }
        try {
            Path outDir = outputPathService.resolveOutputDir(currentImagePath);
            imageIOService.ensureDirectory(outDir);
            Path outFile = outputPathService.resolveOutputFile(currentImagePath);
            BufferedImage out = watermarkService.applyWatermark(currentBufferedImage, watermarkText, settings);
            String format = imageIOService.detectFormat(currentImagePath);
            imageIOService.save(out, outFile, format, 0.9f);
            statusBar.setText("已保存至：" + outFile);
            new Alert(Alert.AlertType.INFORMATION, "保存成功：" + outFile).showAndWait();
        } catch (Exception ex) {
            statusBar.setText("保存失败：" + ex.getMessage());
            new Alert(Alert.AlertType.ERROR, "保存失败: " + ex.getMessage()).showAndWait();
        }
    }

    private void resizeOverlay() {
        Pane center = (Pane) ((BorderPane) imageView.getParent().getParent()).getCenter();
        double w = center.getWidth();
        double h = center.getHeight();
        overlay.setWidth(w);
        overlay.setHeight(h);
    }

    private void redrawOverlay() {
        GraphicsContext g = overlay.getGraphicsContext2D();
        g.clearRect(0, 0, overlay.getWidth(), overlay.getHeight());
        if (imageView.getImage() == null || watermarkText == null) return;

        // Measure text in JavaFX
        Font font = Font.font(settings.getFontSize());
        Text textNode = new Text(watermarkText);
        textNode.setFont(font);
        double textW = textNode.getLayoutBounds().getWidth();
        double textH = textNode.getLayoutBounds().getHeight();

        // ImageView viewport size
        double viewW = overlay.getWidth();
        double viewH = overlay.getHeight();

        double x; double y;
        switch (settings.getPosition()) {
            case TOP_LEFT -> {
                x = settings.getMargin();
                y = settings.getMargin() + textH; // approximate baseline
            }
            case CENTER -> {
                x = (viewW - textW) / 2.0;
                y = (viewH - textH) / 2.0 + textH; // baseline approx
            }
            case BOTTOM_RIGHT -> {
                x = viewW - textW - settings.getMargin();
                y = viewH - settings.getMargin();
            }
            default -> {
                x = settings.getMargin();
                y = settings.getMargin() + textH;
            }
        }

        g.setFill(settings.getColor());
        g.setFont(font);
        g.fillText(watermarkText, x, y);
    }

    public static void main(String[] args) {
        launch(args);
    }
}