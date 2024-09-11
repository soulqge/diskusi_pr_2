import sys
import numpy as np
from PIL import Image
from skimage.metrics import structural_similarity as ssim

def compute_metrics(original_array, processed_array):
    # Convert images to grayscale if they are not already
    if len(original_array.shape) == 3:
        original_array = np.mean(original_array, axis=2)
    if len(processed_array.shape) == 3:
        processed_array = np.mean(processed_array, axis=2)

    # Ensure the images have the same shape
    if original_array.shape != processed_array.shape:
        raise ValueError("Image shapes do not match for metric computation")

    mse = np.mean((original_array - processed_array) ** 2)
    psnr = 20 * np.log10(255.0 / np.sqrt(mse))
    return mse, psnr

def analyze_image(image_path):
    try:
        img = Image.open(image_path)
        img_array = np.array(img)

        # Apply a median filter to the image
        from scipy.ndimage import median_filter
        smoothed_img_array = median_filter(img_array, size=3)
        
        # Compute metrics
        mse, psnr = compute_metrics(img_array, smoothed_img_array)

        print(f'MSE: {mse}')
        print(f'PSNR: {psnr}')
        
        # Use a threshold to determine if hidden data is present
        if mse > 100 or psnr < 31:  # These values are examples; adjust as needed
            return "Hidden message detected"
        else:
            return "No hidden message detected"

    except Exception as e:
        print(f"Error analyzing image: {e}")
        return "Error analyzing image"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python steganography_check.py <image_path>")
        sys.exit(1)

    result = analyze_image(sys.argv[1])
    print(result)