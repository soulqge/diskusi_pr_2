import java.io.File;
import java.io.IOException;
import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.util.Iterator;
import javax.imageio.metadata.IIOMetadata;
import javax.imageio.ImageReader;
import javax.imageio.stream.ImageInputStream;

public class ImageScanner {

    // Method to check file size
    public static boolean isSuspiciousFileSize(File imageFile) {
        // Limit to 2MB
        long maxFileSize = 2 * 1024 * 1024; // 2MB in bytes
        return imageFile.length() > maxFileSize;
    }

    // Method to check metadata anomalies
    public static boolean hasSuspiciousMetadata(File imageFile) {
        try {
            ImageInputStream input = ImageIO.createImageInputStream(imageFile);
            Iterator<ImageReader> readers = ImageIO.getImageReaders(input);
            if (readers.hasNext()) {
                ImageReader reader = readers.next();
                reader.setInput(input);
                IIOMetadata metadata = reader.getImageMetadata(0);

                String[] metadataNames = metadata.getMetadataFormatNames();
                for (String name : metadataNames) {
                    if (name.contains("suspicious")) { // Simple check
                        return true; // Return true if suspicious metadata is found
                    }
                }
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return false; // No suspicious metadata found
    }

    // Main method to scan image for hidden content
    public static boolean scanImage(File imageFile) {
        boolean isSuspicious = isSuspiciousFileSize(imageFile) || hasSuspiciousMetadata(imageFile);
        if (isSuspicious) {
            System.out.println("Suspicious image detected!");
        } else {
            System.out.println("Image is clean.");
        }
        return isSuspicious;
    }

    public static void main(String[] args) {
        File imageFile = new File("path_to_your_image.jpg");
        scanImage(imageFile);
    }
}
