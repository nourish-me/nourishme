#!/usr/bin/env python3
"""Generate the NourishMe app icon as a 1024x1024 PNG.

White "N" lettermark on the app's teal seed color, no transparency
(iOS app icons must be opaque). Run from the project root:
    python3 tools/generate_icon.py
"""
from PIL import Image, ImageDraw, ImageFont

SIZE = 1024
BG = (79, 138, 139)  # 0xFF4F8A8B, matches ColorScheme.fromSeed
FG = (255, 255, 255)
FONT_PATH = '/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf'
LETTER = 'N'
LETTER_SIZE = 720

img = Image.new('RGB', (SIZE, SIZE), BG)
draw = ImageDraw.Draw(img)
font = ImageFont.truetype(FONT_PATH, LETTER_SIZE)

bbox = draw.textbbox((0, 0), LETTER, font=font)
text_w = bbox[2] - bbox[0]
text_h = bbox[3] - bbox[1]
x = (SIZE - text_w) // 2 - bbox[0]
y = (SIZE - text_h) // 2 - bbox[1]

draw.text((x, y), LETTER, font=font, fill=FG)
img.save('assets/icon/icon.png', 'PNG')
print(f'Wrote assets/icon/icon.png ({SIZE}x{SIZE})')
