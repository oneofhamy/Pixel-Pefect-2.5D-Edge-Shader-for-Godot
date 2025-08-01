![logo](https://github.com/oneofhamy/Pixel-Pefect-2.5D-Edge-Shader-for-Godot/blob/main/pp_ld_shader_logo%20large.png)

# v0.8 Pixel-Perfect 2.5D Edge Detection Super-Shader for Godot

[![MIT License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Godot Engine](https://img.shields.io/badge/godot-4.x-blue.svg)](https://godotengine.org/)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](../../pulls)
[![Made for Pixel Art](https://img.shields.io/badge/pixel--art-optimized-yellow.svg)](#)

> **A plug-and-play post-processing shader for crisp, stylized 2D, 2.5D, and 3D outlines, and comic-style edges in Godot. Perfect for pixel art games, retro and comic-book visuals, and stylized overlays.**

![Edge Detection Demo](demo.gif)
*Before and after: Original sprite → Edge detection applied*

## Features

-  **True Pixel-Perfect Edge Detection** - Keeps edges sharp and grid-aligned for classic pixel art
-  **Multiple Edge Detection Types** - Color, luminance, saturation, and hue changes independently
-  **Flexible Render Modes** - Edge-only, blend with original, or detail-enhancing sharpening
-  **Performance Optimized** - Configurable quality settings for real-time games
-  **Plug-and-Play Setup** - Single shader file, works immediately in Godot 4.x
-  **Advanced Effects** - Animation, dithering, lighting modulation, and adaptive thresholding
-  **Mobile Friendly** - Optimized presets for low-end devices

## Table of Contents

- [Installation](#-installation)
- [Quick Start](#-quick-start)
- [Adding the Edge Detection Shader to a ColorRect in Godot](#-adding-the-edge-detection-shader-to-a-colorrect-in-godot)
- [Usage Examples](#-usage-examples)
- [Presets & Recipes](#-presets--recipes)
- [Neon Tube Color Masking (Multicolor Neon Signs!)](#-neon-tube-color-masking-multicolor-neon-signs)
- [Inspector Organization](#-inspector-organization)
- [Parameter Reference](#-parameter-reference)
- [Performance Tips](#-performance-tips)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)
- [License](#-license)

### What is a Super-Shader?

A super-shader is what I'm calling these absurdly long shader scripts that are super mult-use that I am creating as part of a larger, pixel art project.

## Installation

1. **Download the shader file** `edge_detection.gdshader` from this repository
2. **Add to your Godot project** in your shaders folder
3. **Create a ShaderMaterial** and assign the shader
4. **Apply to a ColorRect** covering your viewport
5. **Set screen size in GDScript** (required!)

```gdscript
# In your scene script
func _ready():
    var material = $ColorRect.material as ShaderMaterial
    material.set_shader_parameter("screen_size", get_viewport().size)
```

## Quick Start

### Basic Setup (30 seconds)

1. Create a `ColorRect` node covering your entire viewport
2. Create a new `ShaderMaterial` on the ColorRect
3. Load the `edge_detection.gdshader` file
4. Add this to your scene script:

```gdscript
extends Control

func _ready():
    # Required: Set screen size for proper edge calculation
    var shader_material = $ColorRect.material as ShaderMaterial
    shader_material.set_shader_parameter("screen_size", get_viewport().size)
    
    # Optional: Apply pixel art preset
    apply_pixel_art_preset(shader_material)

func apply_pixel_art_preset(material: ShaderMaterial):
    material.set_shader_parameter("edge_color", Vector3(0, 0, 0))
    material.set_shader_parameter("edge_strength", 2.0)
    material.set_shader_parameter("edge_thickness", 1.0)
    material.set_shader_parameter("color_threshold", 0.08)
    material.set_shader_parameter("use_multi_sampling", false)
    material.set_shader_parameter("use_edge_smoothing", false)
```

### First Results in 1 Minute
With the basic setup above, you should immediately see black outlines around color changes in your scene!

## Adding the Edge Detection Shader to a ColorRect in Godot

![Instructions](https://github.com/oneofhamy/Pixel-Pefect-2.5D-Edge-Shader-for-Godot/blob/main/ED-CR_steps)

*image created by u/pandagoespoop*

Follow these steps to apply the Edge Detection shader to a `ColorRect`:

1. **Select your `ColorRect` node** in the **Scene** panel.
2. In the **Inspector**, scroll to the **Material** property.
3. Click the empty material slot and choose **New ShaderMaterial**.
4. Click the new **ShaderMaterial** to expand its options.
5. In the **Shader** slot, click empty and choose **New Shader** (or **Load...** if you already saved it).
6. Open the new shader and paste in the **Edge Detection shader code** from the repo.

Your `ColorRect` is now using the post-processing Edge Detection effect.





## Usage Examples

### Pixel Art Game Outlines
```gdscript
# Perfect for 16-bit style games
material.set_shader_parameter("use_color_edges", true)
material.set_shader_parameter("edge_color", Vector3(0, 0, 0))  # Black outlines
material.set_shader_parameter("edge_thickness", 1.0)           # 1-pixel lines
material.set_shader_parameter("color_threshold", 0.08)         # Catch all transitions
material.set_shader_parameter("use_multi_sampling", false)     # Sharp, no AA
```

### Comic Book Effect
```gdscript
# Bold, inked comic style
material.set_shader_parameter("edge_strength", 1.5)
material.set_shader_parameter("use_edge_dilation", true)
material.set_shader_parameter("use_dithered_edges", true)
material.set_shader_parameter("dither_strength", 0.6)
```

### Glowing UI Highlights
```gdscript
# Animated pulsing edges for UI elements
material.set_shader_parameter("animate_edges", true)
material.set_shader_parameter("edge_color", Vector3(0, 0.5, 1))     # Blue
material.set_shader_parameter("animation_color", Vector3(1, 1, 1))  # White
material.set_shader_parameter("animation_speed", 2.0)
```

## Presets & Recipes

### Pixel Art Perfection

For authentic retro game outlines with perfect pixel alignment:

```gdscript
# Pixel Art Preset - Copy these exact values
var pixel_art_settings = {
    "use_color_edges": true,
    "use_luminance_edges": false,           # Usually off for pixel art
    "use_saturation_edges": false,
    "use_hue_edges": false,
    
    "edge_color": Vector3(0, 0, 0),         # Pure black outlines
    "edge_strength": 2.0,                   # Strong visibility
    "edge_thickness": 1.0,                  # 1-pixel perfect
    "color_threshold": 0.08,                # Catch all palette changes
    
    "use_multi_sampling": false,            # No anti-aliasing
    "use_edge_smoothing": false,            # Keep it sharp
    "use_edge_dilation": false,             # No thickness
    "use_dithered_edges": false,            # Clean lines (or true for retro)
    
    "use_lighting_modulation": false,       # Ignore scene lighting
    "use_adaptive_threshold": false         # Fixed sensitivity
}

# Apply all settings
for key in pixel_art_settings:
    material.set_shader_parameter(key, pixel_art_settings[key])
```

**Result:** Perfect 1-pixel black outlines around every sprite and tile edge.

### Comic Book Style

```gdscript
var comic_settings = {
    "use_color_edges": true,
    "use_luminance_edges": true,
    "edge_color": Vector3(0, 0, 0),
    "edge_strength": 1.5,
    "edge_thickness": 1.25,
    "use_edge_dilation": true,
    "dilation_radius": 1.5,
    "use_dithered_edges": true,
    "dither_strength": 0.6
}
```

### Glowing Electric

```gdscript
var glow_settings = {
    "use_color_edges": true,
    "edge_color": Vector3(0, 0.5, 1),       # Electric blue
    "animation_color": Vector3(1, 1, 1),    # Bright white
    "animate_edges": true,
    "animation_speed": 2.0,
    "edge_strength": 1.25
}
```

### Technical Drawing

```gdscript
var technical_settings = {
    "use_luminance_edges": true,
    "use_color_edges": false,
    "edge_only_mode": true,                 # Only show lines
    "use_high_quality_sampling": true,
    "edge_color": Vector3(0, 0, 0)
}
```

## Neon Tube Color Masking (Multicolor Neon Signs!)

**NEW IN v0.8.2: Neon Sign Tool – Multicolor, and Flicker**

Edge detection isn’t just for outlines anymore—now your post-process shader can power true neon sign effects with animated, multi-color tubes and classic neon flicker.

- Assign up to 14+ vibrant neon tube colors per sign using a mask texture.
- Each pixel in your mask texture designates a “tube index” (color) for that sign segment.
- Use the built-in expanded neon palette for classic real-world neon effects: Electric Blue, Hot Pink, Lemon Yellow, Lime Green, Orange, Deep Red, and more!

### How It Works

1. Create a Mask/ID Texture:  
   Paint your sign’s tubes in solid colors (R/G/B or index values). Each channel or value in the mask maps to a neon color index.
2. Assign the mask in your material:  
   Set `use_mask_texture` to true. Assign your mask texture to `mask_texture`.
3. The shader uses your mask to look up the correct neon color from the built-in palette, per-pixel.
4. Supports at least 15 preset neon colors (see full palette below), and you can expand the palette as needed.

### Palette Reference

| Index | Name           | Color (RGB)      |
|-------|----------------|------------------|
| 0     | Electric Blue  | (0.0, 0.9, 1.0)  |
| 1     | Hot Pink       | (1.0, 0.27, 0.95)|
| 2     | Lemon Yellow   | (1.0, 1.0, 0.3)  |
| 3     | Lime Green     | (0.3, 1.0, 0.32) |
| 4     | Orange         | (1.0, 0.55, 0.1) |
| 5     | Deep Red       | (1.0, 0.12, 0.13)|
| 6     | Pure White     | (1.0, 1.0, 1.0)  |
| 7     | Aqua Cyan      | (0.08, 1.0, 0.85)|
| 8     | Violet Purple  | (0.63, 0.25, 1.0)|
| 9     | Mint Green     | (0.6, 1.0, 0.7)  |
| 10    | Tangerine      | (1.0, 0.75, 0.1) |
| 11    | Magenta        | (1.0, 0.14, 0.82)|
| 12    | Sky Blue       | (0.35, 0.67, 1.0)|
| 13    | Ruby Red       | (0.95, 0.1, 0.25)|
| 14    | Ultraviolet    | (0.64, 0.0, 1.0) |

Mask index values can be assigned using R, G, B channels or as a float in the RED channel (e.g. 0.0 = blue, 0.07 = pink, 0.14 = yellow, etc).

### Classic Neon Flicker and Animation

- Bring your signs to life with customizable neon flicker!
- Just set `animate_edges = true` and tweak `animation_speed` and `animation_color` for pulsing, glowing, or “broken” tube flicker.
- Advanced “broken flicker” mode: uses stuttered pseudo-random math for realistic, vintage-style tube flicker—per-pixel, per-tube if desired!
- Each tube can flicker independently for extra realism (see advanced docs).

### Example Settings for Flicker

uniform bool animate_edges = true;
uniform float animation_speed = 4.2;
uniform vec3 animation_color = vec3(1.0, 1.0, 1.0); // white or light tube color

### Custom Flicker

- Switch between smooth glow and harsh “broken” flicker in the shader (toggle provided).
- The flicker animation blends between tube color and animation color, with per-tube randomness available.

### How To Set Up Multicolor Neon Edges

1. Paint your mask texture:  
   Use any paint tool. Each tube gets a unique color (or index value) according to the palette table.
2. Add your mask as a texture parameter:  
   In your Godot material, assign the texture to mask_texture. Set use_mask_texture to true.
3. Pick your flicker settings:  
   Set animate_edges, animation_speed, and animation_color as needed.
4. Open the live preview panel:  
   Use the provided EditorPlugin to see your sign shader in action.

### What Else Can You Do?

- Edge-only output for bloom/composite:  
  Use edge_only_mode = true to output just the neon tubes as a mask for advanced bloom or composite workflows.
- Fully customizable tube palette:  
  Edit the neon_palette() function in the shader for infinite color possibilities.
- Smooth/anti-aliased or sharp pixel-perfect edges:  
  All existing edge detection quality and stylization controls work with neon mode!

Ready to bring your UI, game, or cutscene to life with true 80s arcade neon?  
This tool’s for you.

See /examples/ for sample masks and plugin usage.

## Inspector Organization

### Edge Detection

-  ```use_color_edges``` - Enable RGB difference detection
-  ```use_luminance_edges``` - Enable brightness detection
-  ```use_saturation_edges``` - Enable color intensity detection
-  ```use_hue_edges``` - Enable color hue detection

### Appearance

-  ```edge_color``` - Color of detected edges
-  ```edge_strength``` - Overall edge intensity
-  ```edge_thickness``` - Edge line thickness

### Sensitivity

-  ```color_threshold``` - Color detection sensitivity
-  ```luminance_threshold``` - Brightness detection sensitivity
-  ```saturation_threshold``` - Saturation detection sensitivity
-  ```hue_threshold``` - Hue detection sensitivity

### Sampling

-  ```use_multi_sampling``` - Use 8+ samples for quality
-  ```use_circular_sampling``` - Circular vs cross pattern
-  ```use_high_quality_sampling``` - Use 12 samples (slower)
-  ```use_wide_sampling``` - 1.5x sampling radius

### Render Modes

-  ```edge_only_mode``` - Show only edges
-  ```sharpening_mode``` - Add edges for enhancement
-  ```sharpening_strength``` - Sharpening intensity

### Enhancement

-  ```use_edge_smoothing``` - Anti-aliasing
-  ```use_edge_dilation``` - Expand edge thickness
-  ```dilation_radius``` - Expansion amount

### Stylization

-  ```use_dithered_edges``` - Retro pixel dithering
-  ```use_advanced_dither``` - Complex dither patterns
-  ```dither_scale``` - Dither pattern size
-  ```dither_strength``` - Dithering intensity

### Animation

-  ```animate_edges``` - Enable pulsing animation
-  ```animation_speed``` - Animation speed
-  ```animation_color``` - Secondary color for pulse

### Adaptation

-  ```use_lighting_modulation``` - Adapt to scene brightness
-  ```lighting_modulation_strength``` - Adaptation strength
-  ```use_adaptive_threshold``` - Auto-adjust sensitivity

## Parameter Reference

### Core Settings

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `screen_size` | Vector2 | (512, 512) | **REQUIRED:** Set from GDScript to viewport size |
| `edge_color` | Vector3 | (0, 0, 0) | Color of detected edges (RGB 0-1) |
| `edge_strength` | float | 1.0 | Overall edge intensity (0-2) |
| `edge_thickness` | float | 1.0 | Edge line thickness in pixels |

### Edge Detection Types

| Parameter | Type | Default | Description | Best For |
|-----------|------|---------|-------------|----------|
| `use_color_edges` | bool | true | Detect RGB color changes | General use, sprites |
| `use_luminance_edges` | bool | true | Detect brightness changes | Lighting, shadows |
| `use_saturation_edges` | bool | false | Detect color intensity changes | Artistic effects |
| `use_hue_edges` | bool | false | Detect color hue shifts | Psychedelic effects |

### Sensitivity Controls

| Parameter | Type | Range | Description |
|-----------|------|-------|-------------|
| `color_threshold` | float | 0.01-1.0 | How different colors must be (lower = more sensitive) |
| `luminance_threshold` | float | 0.01-1.0 | How different brightness must be |
| `saturation_threshold` | float | 0.01-1.0 | How different color intensity must be |
| `hue_threshold` | float | 0.01-1.0 | How different color hues must be |

### Quality & Performance

| Parameter | Type | Default | Impact | Description |
|-----------|------|---------|--------|-------------|
| `use_multi_sampling` | bool | true | Medium | Use 8 samples instead of 4 (better quality) |
| `use_high_quality_sampling` | bool | false | High | Use 12 samples (best quality, slower) |
| `use_circular_sampling` | bool | false | Low | Circular instead of cross pattern |
| `use_wide_sampling` | bool | false | Medium | 1.5x larger sampling radius |

### Render Modes

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `edge_only_mode` | bool | false | Show only edges on transparent background |
| `sharpening_mode` | bool | false | Add edges to original for enhancement |
| `sharpening_strength` | float | 0.5 | Intensity of sharpening effect |

### Effects & Stylization

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `use_dithered_edges` | bool | false | Add pixel-art style dithering |
| `dither_scale` | float | 4.0 | Size of dither pattern |
| `animate_edges` | bool | false | Pulse between two colors |
| `animation_speed` | float | 1.0 | Speed of edge animation |
| `animation_color` | Vector3 | (1, 0.5, 0) | Secondary color for animation |

### Advanced Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `use_edge_dilation` | bool | false | Expand edges for bolder lines |
| `use_edge_smoothing` | bool | false | Anti-aliasing for smoother edges |
| `use_lighting_modulation` | bool | true | Adapt edge strength to scene brightness |
| `use_adaptive_threshold` | bool | false | Auto-adjust sensitivity by local contrast |

## Performance Tips

### For Real-Time Games
- **Turn OFF:** `use_high_quality_sampling`, `use_saturation_edges`, `use_hue_edges`
- **Keep ON:** `use_color_edges`, `use_luminance_edges` only
- **Set:** `dither_scale = 8.0` (if using dithering)

### For Pixel Art
- **Turn OFF:** `use_multi_sampling`, `use_edge_smoothing`
- **Set:** `edge_thickness = 1.0`
- **Use:** Simple presets only

### For Mobile Devices
```gdscript
# Mobile-optimized preset
var mobile_settings = {
    "use_color_edges": true,
    "use_luminance_edges": false,
    "use_multi_sampling": false,
    "use_high_quality_sampling": false,
    "use_dithered_edges": false,
    "use_edge_smoothing": false,
    "edge_strength": 1.0
}
```

### Performance Impact Guide
- 🟢 **Low Impact:** Basic color/luminance detection
- 🟡 **Medium Impact:** Multi-sampling, dithering, animation
- 🔴 **High Impact:** High-quality sampling, saturation/hue detection, adaptive threshold

##  Troubleshooting

### No edges visible / Black screen
**Check:**
- Set `screen_size` in GDScript: `material.set_shader_parameter("screen_size", get_viewport().size)`
- ColorRect covers the full viewport area
- `edge_strength` > 0
- At least one edge type is enabled

### Edges too thick/thin
**Solution:**
- Adjust `edge_thickness` (1.0 = 1 pixel)
- For pixel art: always use `edge_thickness = 1.0`
- Check `use_edge_dilation` setting

### Edges too sensitive/not sensitive enough
**Solution:**
- Lower threshold values = more edges detected
- Typical good values: `color_threshold = 0.08-0.15`
- Try enabling `use_adaptive_threshold`

### Performance issues
**Solution:**
- Follow [Performance Tips](#-performance-tips)
- Disable unused edge detection types
- Turn off high-quality sampling

### Blurry/soft edges
**Solution:**
- Turn OFF `use_edge_smoothing`
- Turn OFF `use_multi_sampling` for pixel art
- Set `edge_thickness = 1.0`

### Shader compilation errors
**Check:**
- Using Godot 4.x (not 3.x)
- Shader applied to 2D/3D node (ColorRect/TextureRect)
- No typos in parameter names when setting from GDScript

## Contributing

We welcome contributions! Here's how you can help:

### Bug Reports
- Open an [Issue](../../issues) with:
  - Godot version
  - Screenshot/description of the problem
  - Parameter settings used

### Feature Requests
- Check existing [Issues](../../issues) first
- Describe your use case and expected behavior

### Code Contributions
1. Fork the repository
2. Create a feature branch
3. Test in Godot 4.x
4. Submit a Pull Request with clear description

### Showcase
Share your creations! Post screenshots or videos in [Discussions](../../discussions) to inspire others.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Free for commercial and personal use, modification allowed, attribution greatly appreciated but not required.**

---

## Credits

Created with love for pixel-art and the Godot community by ONE OF HAM.

**Special thanks to:**
- Godot Engine developers for the amazing engine
- Community shader developers for inspiration
- Beta testers and contributors

---

***If this shader helped your project, consider giving it a star!***
*Made with Godot 4.x | Tested on Windows, Linux, and Mobile*
