from PIL import Image, ImageFilter, ImageEnhance, ImageDraw
import numpy as np

src = "/Users/kapilthakare/Downloads/Gemini_Generated_Image_5374bm5374bm5374.png"
img = Image.open(src).convert("RGB")
w, h = img.size

# 1. Create a subtle blue background layer
# Use a soft blue tone that complements the warm scene
bg = Image.new("RGB", (w, h), color=(220, 230, 240))  # Soft blue

# Add subtle gradient for depth
for y in range(h):
    factor = y / h
    r = int(220 - factor * 20)
    g = int(230 - factor * 15)
    b = int(240 - factor * 10)
    ImageDraw.Draw(bg).line([(0, y), (w, y)], fill=(r, g, b))

# Apply blur to background for bokeh effect
bg = bg.filter(ImageFilter.GaussianBlur(radius=15))

# 2. Extract foreground using simple method
# Since we don't have rembg working, let's use edge detection and masking
gray = img.convert("L")
# Simple approach: use the center portion as likely foreground
# Create a radial gradient mask
mask = Image.new("L", (w, h), 0)
draw = ImageDraw.Draw(mask)

# Create a soft oval mask in the center where subjects are
cx, cy = w // 2, h // 2
for r in range(min(w, h) // 2, 0, -1):
    opacity = int(255 * (r / (min(w, h) // 2)) ** 2)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=opacity)

# Soften the mask
mask = mask.filter(ImageFilter.GaussianBlur(radius=20))

# 3. Composite: sharp subject over blurred background
result = Image.composite(img, bg, mask)

# 4. Add subtle lens vignette
vignette = Image.new("L", (w, h), 255)
draw = ImageDraw.Draw(vignette)
for i in range(100):
    alpha = int(255 * (i / 100) ** 2)
    draw.rectangle([i, i, w - 1 - i, h - 1 - i], outline=alpha)
vignette = vignette.filter(ImageFilter.GaussianBlur(radius=30))
result = Image.composite(result, Image.new("RGB", (w, h), (0, 0, 0)), vignette)

# 5. Slight color enhancement for "pop"
enhancer = ImageEnhance.Color(result)
result = enhancer.enhance(1.1)
enhancer = ImageEnhance.Contrast(result)
result = enhancer.enhance(1.05)

out_path = src.replace(".png", "-bokeh.png")
result.save(out_path, quality=95)
print(f"Saved to {out_path}")
