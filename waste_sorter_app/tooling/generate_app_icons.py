from pathlib import Path
import math

from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "icon" / "app_icon.png"


def lerp(a, b, t):
    return int(a + (b - a) * t)


def gradient_background(size):
    image = Image.new("RGBA", (size, size))
    pixels = image.load()
    top = (16, 148, 108)
    mid = (20, 175, 111)
    bottom = (18, 84, 132)

    for y in range(size):
        t = y / (size - 1)
        if t < 0.55:
            k = t / 0.55
            color = tuple(lerp(top[i], mid[i], k) for i in range(3))
        else:
            k = (t - 0.55) / 0.45
            color = tuple(lerp(mid[i], bottom[i], k) for i in range(3))

        for x in range(size):
            dx = (x - size * 0.30) / size
            dy = (y - size * 0.18) / size
            glow = max(0.0, 1.0 - math.sqrt(dx * dx + dy * dy) * 2.2)
            r = min(255, color[0] + int(34 * glow))
            g = min(255, color[1] + int(42 * glow))
            b = min(255, color[2] + int(28 * glow))
            pixels[x, y] = (r, g, b, 255)

    return image


def rounded_mask(size, radius):
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def polygon_arrow(draw, center, radius, angle_deg, color, scale=1.0):
    angle = math.radians(angle_deg)
    tangent = angle + math.pi / 2
    x = center + radius * math.cos(angle)
    y = center + radius * math.sin(angle)
    length = 120 * scale
    width = 95 * scale

    tip = (x + math.cos(tangent) * length * 0.38, y + math.sin(tangent) * length * 0.38)
    base = (x - math.cos(tangent) * length * 0.58, y - math.sin(tangent) * length * 0.58)
    left = (
        base[0] + math.cos(tangent + math.pi / 2) * width * 0.5,
        base[1] + math.sin(tangent + math.pi / 2) * width * 0.5,
    )
    right = (
        base[0] + math.cos(tangent - math.pi / 2) * width * 0.5,
        base[1] + math.sin(tangent - math.pi / 2) * width * 0.5,
    )
    draw.polygon([tip, left, right], fill=color)


def bezier(p0, p1, p2, p3, steps=28):
    points = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = (
            u * u * u * p0[0]
            + 3 * u * u * t * p1[0]
            + 3 * u * t * t * p2[0]
            + t * t * t * p3[0]
        )
        y = (
            u * u * u * p0[1]
            + 3 * u * u * t * p1[1]
            + 3 * u * t * t * p2[1]
            + t * t * t * p3[1]
        )
        points.append((x, y))
    return points


def draw_recycle_mark(draw, size, offset=(0, 0), color=(255, 255, 255, 246)):
    center = size / 2
    radius = size * 0.225
    width = int(size * 0.058)
    bbox = (
        center - radius + offset[0],
        center - radius + offset[1],
        center + radius + offset[0],
        center + radius + offset[1],
    )

    arcs = [(-35, 62), (85, 182), (205, 302)]
    for start, end in arcs:
        draw.arc(bbox, start=start, end=end, fill=color, width=width)

    for angle in (62, 182, 302):
        polygon_arrow(draw, center + offset[0], radius, angle, color, size / 1024)


def draw_leaf(draw, size):
    c = size / 2
    stem = (c + size * 0.045, c - size * 0.115)
    tip = (c + size * 0.285, c - size * 0.265)
    upper = bezier(
        stem,
        (c + size * 0.125, c - size * 0.305),
        (c + size * 0.245, c - size * 0.345),
        tip,
    )
    lower = bezier(
        tip,
        (c + size * 0.345, c - size * 0.100),
        (c + size * 0.155, c + size * 0.040),
        stem,
    )
    draw.polygon(upper + lower, fill=(198, 255, 217, 255))
    draw.line(
        [
            (c + size * 0.075, c - size * 0.125),
            (c + size * 0.245, c - size * 0.225),
        ],
        fill=(37, 143, 98, 220),
        width=int(size * 0.014),
    )


def draw_ai_nodes(draw, size):
    color = (205, 250, 255, 230)
    line = (205, 250, 255, 120)
    points = [
        (size * 0.30, size * 0.68),
        (size * 0.42, size * 0.77),
        (size * 0.56, size * 0.68),
        (size * 0.66, size * 0.78),
    ]
    for a, b in zip(points, points[1:]):
        draw.line([a, b], fill=line, width=int(size * 0.012))
    for x, y in points:
        r = size * 0.026
        draw.ellipse((x - r, y - r, x + r, y + r), fill=color)


def create_source_icon():
    size = 1024
    scale = 4
    canvas_size = size * scale
    image = gradient_background(canvas_size)

    mask = rounded_mask(canvas_size, int(canvas_size * 0.22))
    image.putalpha(mask)

    shadow = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    draw_recycle_mark(
        shadow_draw,
        canvas_size,
        offset=(0, int(canvas_size * 0.018)),
        color=(0, 36, 34, 82),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(canvas_size * 0.008))
    image.alpha_composite(shadow)

    draw = ImageDraw.Draw(image)
    draw.rounded_rectangle(
        (canvas_size * 0.055, canvas_size * 0.055, canvas_size * 0.945, canvas_size * 0.945),
        radius=int(canvas_size * 0.18),
        outline=(255, 255, 255, 42),
        width=int(canvas_size * 0.012),
    )
    draw_recycle_mark(draw, canvas_size)
    draw_leaf(draw, canvas_size)
    draw_ai_nodes(draw, canvas_size)

    image = image.resize((size, size), Image.Resampling.LANCZOS)
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    image.save(SOURCE)
    return image


def save_png(image, path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(path)


def generate_platform_icons(source):
    android = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, size in android.items():
        save_png(source, ROOT / "android" / "app" / "src" / "main" / "res" / folder / "ic_launcher.png", size)

    web = {
        "Icon-192.png": 192,
        "Icon-maskable-192.png": 192,
        "Icon-512.png": 512,
        "Icon-maskable-512.png": 512,
    }
    for filename, size in web.items():
        save_png(source, ROOT / "web" / "icons" / filename, size)
    save_png(source, ROOT / "web" / "favicon.png", 32)

    ios = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for filename, size in ios.items():
        save_png(source, ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / filename, size)

    macos = {
        "app_icon_16.png": 16,
        "app_icon_32.png": 32,
        "app_icon_64.png": 64,
        "app_icon_128.png": 128,
        "app_icon_256.png": 256,
        "app_icon_512.png": 512,
        "app_icon_1024.png": 1024,
    }
    for filename, size in macos.items():
        save_png(source, ROOT / "macos" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / filename, size)

    ico_sizes = [16, 24, 32, 48, 64, 128, 256]
    ico_images = [source.resize((s, s), Image.Resampling.LANCZOS) for s in ico_sizes]
    ico_path = ROOT / "windows" / "runner" / "resources" / "app_icon.ico"
    ico_path.parent.mkdir(parents=True, exist_ok=True)
    ico_images[-1].save(ico_path, sizes=[(s, s) for s in ico_sizes], append_images=ico_images[:-1])


def main():
    source = create_source_icon()
    generate_platform_icons(source)
    print(f"Generated app icon source: {SOURCE}")


if __name__ == "__main__":
    main()
