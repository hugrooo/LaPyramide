from PIL import Image, ImageDraw, ImageFont
import os

img_path = '/Users/hugo/.gemini/antigravity/brain/a7fd23c4-5312-4716-9324-4b281c8dff5c/media__1780569193594.png'
out_path = '/Users/hugo/.gemini/antigravity/brain/a7fd23c4-5312-4716-9324-4b281c8dff5c/media_patched.png'

img = Image.open(img_path).convert('RGBA')

# The pill bounding box
x1, y1 = 145, 308
x2, y2 = 225, 330

# Background color slightly above the pill
bg_color = img.getpixel((185, 300))

draw = ImageDraw.Draw(img)
# Erase old pill
draw.rectangle([x1, y1, x2, y2], fill=bg_color)

# Draw new pill
# Teal color: #00D1FF with 30% opacity on top of bg_color
# approx (4, 75, 95)
pill_color = (6, 75, 99, 255)
# Draw rounded rectangle
draw.rounded_rectangle([x1-5, y1, x2+15, y2], radius=10, fill=pill_color)

# Try to load a nice font
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 11)
except:
    font = ImageFont.load_default()

# Draw text
text = "🃏 1 pénalité"
draw.text((x1+2, y1+4), text, font=font, fill=(255, 255, 255, 255))

img.save(out_path)
print("Saved to", out_path)
