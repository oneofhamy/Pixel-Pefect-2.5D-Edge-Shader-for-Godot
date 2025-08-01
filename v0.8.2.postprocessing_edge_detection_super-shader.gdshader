// ============================================================================
// PROFESSIONAL EDGE DETECTION SHADER v0.8.2
// ============================================================================
// A comprehensive post-processing shader for 2D edge detection with advanced
// sampling, multiple render modes, and intelligent adaptation features.
// 
// Perfect for: Stylized games, comic effects, technical visualization,
// architectural visualization, and artistic post-processing.
//
// Created through incremental development with full Godot compatibility.
// ============================================================================

shader_type canvas_item;

// ============================================================================
// CORE TEXTURE INPUT
// ============================================================================

/**
 * The rendered scene that will be processed for edge detection.
 * This is automatically provided by Godot's rendering pipeline.
 * NOTE: You must set screen_size from GDScript to match your viewport resolution!
 */
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

/**
 * Screen resolution in pixels. MUST be set from GDScript!
 * Example: material.set_shader_param("screen_size", get_viewport().size)
 * This is crucial for proper edge thickness calculation.
 */
uniform vec2 screen_size = vec2(512.0, 512.0);

/**
 * Use a mask texture to assign neon tube colors per region.
 * ON: Use the colors specified in mask_texture for edge coloring.
 * OFF: Use the global edge_color as before.
 */
uniform bool use_mask_texture = false;

/**
 * Mask/ID texture for region-specific tube colors.
 * Each region of your mask uses R, G, or B channel to signal the tube color index.
 * Supply this from your GDScript as a regular texture.
 */
uniform sampler2D mask_texture;

// ============================================================================
// EDGE DETECTION METHODS - Choose which types of edges to detect
// ============================================================================

/**
 * COLOR EDGE DETECTION (RGB Differences)
 * Detects edges based on color changes between neighboring pixels.
 * Best for: General purpose edge detection, colored objects, textures
 * Performance: Medium
 */
uniform bool use_color_edges = true;

/**
 * LUMINANCE EDGE DETECTION (Brightness Changes)  
 * Detects edges based on brightness/lightness differences.
 * Best for: Black & white effects, lighting transitions, shadows
 * Performance: Fast (single channel comparison)
 */
uniform bool use_luminance_edges = true;

/**
 * SATURATION EDGE DETECTION (Color Intensity Changes)
 * Detects edges where color intensity/vividness changes.
 * Best for: Artistic effects, separating colorful from dull areas
 * Performance: Medium (requires color space conversion)
 */
uniform bool use_saturation_edges = false;

/**
 * HUE EDGE DETECTION (Color Hue Changes)
 * Detects edges where the actual color hue shifts (red->blue, etc).
 * Best for: Psychedelic effects, color-based object separation
 * Performance: Slow (complex color space math with hue wrapping)
 */
uniform bool use_hue_edges = false;

// ============================================================================
// VISUAL APPEARANCE - Control how edges look
// ============================================================================

/**
 * Base color for detected edges.
 * Examples: Black (0,0,0) for ink lines, White (1,1,1) for highlights,
 * Bright colors for stylized effects.
 */
uniform vec3 edge_color = vec3(0.0, 0.0, 0.0);

/**
 * Overall strength/intensity of the edge effect.
 * 0.0 = No edges visible, 1.0 = Normal strength, 2.0 = Very strong edges
 * Higher values make edges more prominent and opaque.
 */
uniform float edge_strength = 1.0;

/**
 * Thickness of detected edges in pixels.
 * 0.5 = Very thin/sharp edges, 1.0 = Normal thickness, 5.0 = Very thick edges
 * This affects the sampling distance used for edge detection.
 */
uniform float edge_thickness = 1.0;

// ============================================================================
// EDGE DETECTION SENSITIVITY - Fine-tune what counts as an "edge"
// ============================================================================

/**
 * COLOR THRESHOLD: How different colors must be to create an edge.
 * Lower = More sensitive (detects subtle color changes)
 * Higher = Less sensitive (only detects major color differences)
 * Range: 0.01 (very sensitive) to 1.0 (very insensitive)
 * Good starting value: 0.15
 */
uniform float color_threshold = 0.15;

/**
 * LUMINANCE THRESHOLD: How different brightness must be to create an edge.
 * Lower = Detects subtle lighting changes
 * Higher = Only detects major light/shadow boundaries  
 * Range: 0.01 to 1.0, Good starting value: 0.1
 */
uniform float luminance_threshold = 0.1;

/**
 * SATURATION THRESHOLD: How different color intensity must be.
 * Lower = Detects subtle vivid/dull transitions
 * Higher = Only detects major saturation changes
 * Range: 0.01 to 1.0, Good starting value: 0.2
 */
uniform float saturation_threshold = 0.2;

/**
 * HUE THRESHOLD: How different color hues must be.
 * Lower = Detects subtle color shifts (blue->blue-green)
 * Higher = Only detects major hue changes (blue->red)
 * Range: 0.01 to 1.0, Good starting value: 0.1
 */
uniform float hue_threshold = 0.1;

// ============================================================================
// ADVANCED SAMPLING - Improve edge quality with better sampling
// ============================================================================

/**
 * MULTI-SAMPLING: Use 8+ samples instead of basic 4-sample cross pattern.
 * ON: Higher quality, smoother edges, better diagonal detection
 * OFF: Faster performance, simpler sampling
 * Recommendation: Keep ON unless performance is critical
 */
uniform bool use_multi_sampling = true;

/**
 * CIRCULAR SAMPLING: Use circular pattern instead of cross+diagonal.
 * ON: More uniform sampling in all directions
 * OFF: Standard cross+diagonal pattern (slightly faster)
 * Best for: Organic shapes, curved edges
 */
uniform bool use_circular_sampling = false;

/**
 * HIGH QUALITY SAMPLING: Use 12 samples instead of 8.
 * ON: Highest quality edge detection, best results
 * OFF: Standard 8-sample quality (faster)
 * Warning: Significant performance cost, use for final renders
 */
uniform bool use_high_quality_sampling = false;

/**
 * WIDE SAMPLING: Use 1.5x larger sampling radius.
 * ON: Better at detecting thick edges and soft transitions
 * OFF: Standard sampling radius
 * Best for: Blurry images, soft shadows, thick painted lines
 */
uniform bool use_wide_sampling = false;

// ============================================================================
// RENDER MODES - How edges are combined with the original image
// ============================================================================

/**
 * EDGE-ONLY MODE: Show only detected edges on transparent background.
 * ON: Pure edge lines, transparent elsewhere (perfect for overlays)
 * OFF: Edges blended with original image
 * Use cases: UI overlays, technical drawings, line art extraction
 */
uniform bool edge_only_mode = false;

/**
 * SHARPENING MODE: Add edges to original image to enhance detail.
 * ON: Original image + edge enhancement (sharpening effect)  
 * OFF: Normal edge blending
 * Use cases: Photo enhancement, detail emphasis, clarity improvement
 */
uniform bool sharpening_mode = false;

/**
 * SHARPENING STRENGTH: How strongly edges enhance the original.
 * Only used when sharpening_mode is ON.
 * 0.0 = No sharpening, 0.5 = Moderate, 2.0 = Very strong
 */
uniform float sharpening_strength = 0.5;

// ============================================================================
// EDGE ENHANCEMENT - Additional processing for better results
// ============================================================================

/**
 * EDGE SMOOTHING: Blend edges with neighbors for anti-aliasing.
 * ON: Smoother, less jagged edges (slight blur)
 * OFF: Sharp, pixelated edges
 * Best for: Final presentation, print output, smooth visual style
 */
uniform bool use_edge_smoothing = false;

/**
 * EDGE DILATION: Expand edges to make them bolder and thicker.
 * ON: Thicker, more prominent edges
 * OFF: Standard edge thickness
 * Best for: Comic book effects, bold artistic styles
 */
uniform bool use_edge_dilation = false;

/**
 * DILATION RADIUS: How far to expand edges (when dilation is ON).
 * 1.0 = Small expansion, 3.0 = Large expansion
 * Higher values create much thicker edge lines
 */
uniform float dilation_radius = 1.5;

// ============================================================================
// STYLIZATION EFFECTS - Artistic and retro effects
// ============================================================================

/**
 * DITHERED EDGES: Add retro/pixel-art style dithering to edge strength.
 * ON: Pixelated, retro computer graphics look
 * OFF: Smooth edge gradients
 * Perfect for: Pixel art, retro games, comic book effects
 */
uniform bool use_dithered_edges = false;

/**
 * ADVANCED DITHERING: Use complex patterns instead of simple checkerboard.
 * ON: Multiple overlapping patterns with noise
 * OFF: Simple checkerboard dithering
 * Only used when use_dithered_edges is ON
 */
uniform bool use_advanced_dither = false;

/**
 * DITHER SCALE: Size of dithering pattern.
 * 1.0 = Very fine pattern, 8.0 = Large chunky pattern
 * Lower values = more detailed dithering, Higher = more pixelated
 */
uniform float dither_scale = 4.0;

/**
 * DITHER STRENGTH: How strongly dithering affects edge visibility.
 * 0.1 = Subtle effect, 1.0 = Strong pixelation
 * Controls the contrast between dithered pixels
 */
uniform float dither_strength = 0.5;

// ============================================================================
// ANIMATION SYSTEM - Dynamic, moving edge effects
// ============================================================================

/**
 * ANIMATED EDGES: Make edges pulse and glow over time.
 * ON: Edges animate between edge_color and animation_color
 * OFF: Static edge color
 * Perfect for: UI highlights, magical effects, attention-grabbing elements
 */
uniform bool animate_edges = false;

/**
 * ANIMATION SPEED: How fast edges pulse/animate.
 * 0.1 = Very slow pulse, 5.0 = Very fast strobe
 * Uses sine wave animation based on TIME
 */
uniform float animation_speed = 1.0;

/**
 * ANIMATION COLOR: Secondary color for animated pulsing.
 * Edges will animate between edge_color and this color.
 * Example: Black->Orange for fire effect, Blue->White for electric effect
 */
uniform vec3 animation_color = vec3(1.0, 0.5, 0.0);

// ============================================================================
// INTELLIGENT ADAPTATION - Advanced automatic adjustments
// ============================================================================

/**
 * LIGHTING MODULATION: Adjust edge strength based on scene brightness.
 * ON: Stronger edges in bright areas, weaker in dark areas
 * OFF: Uniform edge strength everywhere
 * Best for: Realistic lighting integration, photographic effects
 */
uniform bool use_lighting_modulation = true;

/**
 * LIGHTING MODULATION STRENGTH: How strongly lighting affects edges.
 * 0.0 = No effect, 2.0 = Very strong lighting influence
 * Higher values make the lighting adaptation more dramatic
 */
uniform float lighting_modulation_strength = 1.0;

/**
 * ADAPTIVE THRESHOLD: Automatically adjust sensitivity based on local contrast.
 * ON: More sensitive in low-contrast areas, less in high-contrast
 * OFF: Fixed threshold values everywhere
 * Best for: Varied lighting conditions, mixed scene types
 */
uniform bool use_adaptive_threshold = false;

// ============================================================================
// INTERNAL FUNCTIONS - You don't need to modify these
// ============================================================================

vec2 get_texel_size() {
    return edge_thickness / screen_size;
}

bool is_valid_uv(vec2 uv) {
    return uv.x >= 0.0 && uv.x <= 1.0 && uv.y >= 0.0 && uv.y <= 1.0;
}

vec3 sample_color_safe(vec2 uv) {
    if (!is_valid_uv(uv)) {
        return vec3(0.0);
    }
    return texture(screen_texture, uv).rgb;
}

float get_luminance(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

float get_saturation(vec3 color) {
    float max_val = max(max(color.r, color.g), color.b);
    float min_val = min(min(color.r, color.g), color.b);
    return max_val - min_val;
}

float get_hue(vec3 color) {
    float max_val = max(max(color.r, color.g), color.b);
    float min_val = min(min(color.r, color.g), color.b);
    float delta = max_val - min_val;
    
    if (abs(delta) < 0.0001) return 0.0;
    
    float hue = 0.0;
    if (abs(max_val - color.r) < 0.0001) {
        hue = mod((color.g - color.b) / delta, 6.0);
    } else if (abs(max_val - color.g) < 0.0001) {
        hue = (color.b - color.r) / delta + 2.0;
    } else {
        hue = (color.r - color.g) / delta + 4.0;
    }
    
    return hue / 6.0;
}

// === ADAPTIVE THRESHOLDING ===
float get_adaptive_threshold(vec2 uv, float base_threshold) {
    if (!use_adaptive_threshold) return base_threshold;
    
    // Calculate local contrast
    vec2 texel_size = get_texel_size();
    vec3 center = sample_color_safe(uv);
    
    vec3 samples[4];
    samples[0] = sample_color_safe(uv + vec2(-texel_size.x * 2.0, 0.0));
    samples[1] = sample_color_safe(uv + vec2(texel_size.x * 2.0, 0.0));
    samples[2] = sample_color_safe(uv + vec2(0.0, -texel_size.y * 2.0));
    samples[3] = sample_color_safe(uv + vec2(0.0, texel_size.y * 2.0));
    
    float local_contrast = 0.0;
    for (int i = 0; i < 4; i++) {
        vec3 diff = abs(center - samples[i]);
        local_contrast += dot(diff, vec3(0.299, 0.587, 0.114));
    }
    local_contrast /= 4.0;
    
    // Adapt threshold based on local contrast
    float adaptation_factor = 1.0 + local_contrast * 2.0;
    return base_threshold * adaptation_factor;
}

// === EDGE DETECTION CORE ===
float detect_color_edges(vec2 uv) {
    if (!use_color_edges) return 0.0;
    
    vec2 base_texel_size = get_texel_size();
    vec2 texel_size = use_wide_sampling ? base_texel_size * 1.5 : base_texel_size;
    vec3 center = sample_color_safe(uv);

    if (use_multi_sampling) {
        // Determine sample count and create offsets
        int sample_count = use_high_quality_sampling ? 12 : 8;
        
        float max_diff = 0.0;
        
        if (use_circular_sampling) {
            // Circular pattern with variable quality
            for (int i = 0; i < 12; i++) {
                if (i >= sample_count) break;
                
                float angle = float(i) * 6.28318 / float(sample_count);
                vec2 offset = vec2(cos(angle), sin(angle)) * texel_size;
                
                vec3 sample_color = sample_color_safe(uv + offset);
                vec3 color_diff = abs(center - sample_color);
                float weighted_diff = dot(color_diff, vec3(0.299, 0.587, 0.114));
                max_diff = max(max_diff, weighted_diff);
            }
        } else {
            // Cross + diagonal pattern with extra samples for high quality
            vec2 offsets[12];
            
            // Basic 8 samples
            offsets[0] = vec2(-texel_size.x, 0.0);
            offsets[1] = vec2(texel_size.x, 0.0);
            offsets[2] = vec2(0.0, -texel_size.y);
            offsets[3] = vec2(0.0, texel_size.y);
            offsets[4] = vec2(-texel_size.x, -texel_size.y);
            offsets[5] = vec2(texel_size.x, -texel_size.y);
            offsets[6] = vec2(-texel_size.x, texel_size.y);
            offsets[7] = vec2(texel_size.x, texel_size.y);
            
            // Additional 4 samples for high quality
            offsets[8] = vec2(-texel_size.x * 2.0, 0.0);
            offsets[9] = vec2(texel_size.x * 2.0, 0.0);
            offsets[10] = vec2(0.0, -texel_size.y * 2.0);
            offsets[11] = vec2(0.0, texel_size.y * 2.0);
            
            for (int i = 0; i < 12; i++) {
                if (i >= sample_count) break;
                
                vec3 sample_color = sample_color_safe(uv + offsets[i]);
                vec3 color_diff = abs(center - sample_color);
                float weighted_diff = dot(color_diff, vec3(0.299, 0.587, 0.114));
                max_diff = max(max_diff, weighted_diff);
            }
        }
        
        return smoothstep(color_threshold * 0.5, get_adaptive_threshold(uv, color_threshold), max_diff);
    } else {
        // Simple 4-sample cross pattern
        vec3 left = sample_color_safe(uv + vec2(-texel_size.x, 0.0));
        vec3 right = sample_color_safe(uv + vec2(texel_size.x, 0.0));
        vec3 up = sample_color_safe(uv + vec2(0.0, -texel_size.y));
        vec3 down = sample_color_safe(uv + vec2(0.0, texel_size.y));
        
        vec3 color_diff_h = abs(center - left) + abs(center - right);
        vec3 color_diff_v = abs(center - up) + abs(center - down);
        float color_diff = dot(color_diff_h + color_diff_v, vec3(0.299, 0.587, 0.114));
        
        return smoothstep(color_threshold * 0.5, get_adaptive_threshold(uv, color_threshold), color_diff);
    }
}

float detect_luminance_edges(vec2 uv) {
    if (!use_luminance_edges) return 0.0;
    
    vec2 base_texel_size = get_texel_size();
    vec2 texel_size = use_wide_sampling ? base_texel_size * 1.5 : base_texel_size;
    float center_lum = get_luminance(sample_color_safe(uv));

    if (use_multi_sampling) {
        int sample_count = use_high_quality_sampling ? 12 : 8;
        float max_diff = 0.0;
        
        if (use_circular_sampling) {
            for (int i = 0; i < 12; i++) {
                if (i >= sample_count) break;
                
                float angle = float(i) * 6.28318 / float(sample_count);
                vec2 offset = vec2(cos(angle), sin(angle)) * texel_size;
                
                float sample_lum = get_luminance(sample_color_safe(uv + offset));
                max_diff = max(max_diff, abs(center_lum - sample_lum));
            }
        } else {
            vec2 offsets[12];
            offsets[0] = vec2(-texel_size.x, 0.0);
            offsets[1] = vec2(texel_size.x, 0.0);
            offsets[2] = vec2(0.0, -texel_size.y);
            offsets[3] = vec2(0.0, texel_size.y);
            offsets[4] = vec2(-texel_size.x, -texel_size.y);
            offsets[5] = vec2(texel_size.x, -texel_size.y);
            offsets[6] = vec2(-texel_size.x, texel_size.y);
            offsets[7] = vec2(texel_size.x, texel_size.y);
            offsets[8] = vec2(-texel_size.x * 2.0, 0.0);
            offsets[9] = vec2(texel_size.x * 2.0, 0.0);
            offsets[10] = vec2(0.0, -texel_size.y * 2.0);
            offsets[11] = vec2(0.0, texel_size.y * 2.0);
            
            for (int i = 0; i < 12; i++) {
                if (i >= sample_count) break;
                
                float sample_lum = get_luminance(sample_color_safe(uv + offsets[i]));
                max_diff = max(max_diff, abs(center_lum - sample_lum));
            }
        }
        
        return smoothstep(luminance_threshold * 0.5, get_adaptive_threshold(uv, luminance_threshold), max_diff);
    } else {
        // Simple 4-sample cross pattern
        float left_lum = get_luminance(sample_color_safe(uv + vec2(-texel_size.x, 0.0)));
        float right_lum = get_luminance(sample_color_safe(uv + vec2(texel_size.x, 0.0)));
        float up_lum = get_luminance(sample_color_safe(uv + vec2(0.0, -texel_size.y)));
        float down_lum = get_luminance(sample_color_safe(uv + vec2(0.0, texel_size.y)));
        
        float lum_diff = abs(center_lum - left_lum) + abs(center_lum - right_lum) + 
                        abs(center_lum - up_lum) + abs(center_lum - down_lum);
        
        return smoothstep(luminance_threshold * 0.5, get_adaptive_threshold(uv, luminance_threshold), lum_diff);
    }
}

float detect_saturation_edges(vec2 uv) {
    if (!use_saturation_edges) return 0.0;
    
    vec2 base_texel_size = get_texel_size();
    vec2 texel_size = use_wide_sampling ? base_texel_size * 1.5 : base_texel_size;
    float center_sat = get_saturation(sample_color_safe(uv));
    
    if (use_multi_sampling) {
        int sample_count = use_high_quality_sampling ? 12 : 8;
        float max_diff = 0.0;
        
        if (use_circular_sampling) {
            for (int i = 0; i < 12; i++) {
                if (i >= sample_count) break;
                
                float angle = float(i) * 6.28318 / float(sample_count);
                vec2 offset = vec2(cos(angle), sin(angle)) * texel_size;
                
                float sample_sat = get_saturation(sample_color_safe(uv + offset));
                max_diff = max(max_diff, abs(center_sat - sample_sat));
            }
        } else {
            vec2 offsets[12];
            offsets[0] = vec2(-texel_size.x, 0.0);
            offsets[1] = vec2(texel_size.x, 0.0);
            offsets[2] = vec2(0.0, -texel_size.y);
            offsets[3] = vec2(0.0, texel_size.y);
            offsets[4] = vec2(-texel_size.x, -texel_size.y);
            offsets[5] = vec2(texel_size.x, -texel_size.y);
            offsets[6] = vec2(-texel_size.x, texel_size.y);
            offsets[7] = vec2(texel_size.x, texel_size.y);
            offsets[8] = vec2(-texel_size.x * 2.0, 0.0);
            offsets[9] = vec2(texel_size.x * 2.0, 0.0);
            offsets[10] = vec2(0.0, -texel_size.y * 2.0);
            offsets[11] = vec2(0.0, texel_size.y * 2.0);
            
            for (int i = 0; i < 12; i++) {
                if (i >= sample_count) break;
                
                float sample_sat = get_saturation(sample_color_safe(uv + offsets[i]));
                max_diff = max(max_diff, abs(center_sat - sample_sat));
            }
        }
        
        return smoothstep(saturation_threshold * 0.5, get_adaptive_threshold(uv, saturation_threshold), max_diff);
    } else {
        // Simple 4-sample cross pattern
        float left_sat = get_saturation(sample_color_safe(uv + vec2(-texel_size.x, 0.0)));
        float right_sat = get_saturation(sample_color_safe(uv + vec2(texel_size.x, 0.0)));
        float up_sat = get_saturation(sample_color_safe(uv + vec2(0.0, -texel_size.y)));
        float down_sat = get_saturation(sample_color_safe(uv + vec2(0.0, texel_size.y)));
        
        float sat_diff = abs(center_sat - left_sat) + abs(center_sat - right_sat) + 
                        abs(center_sat - up_sat) + abs(center_sat - down_sat);
        
        return smoothstep(saturation_threshold * 0.5, get_adaptive_threshold(uv, saturation_threshold), sat_diff);
    }
}

float detect_hue_edges(vec2 uv) {
    if (!use_hue_edges) return 0.0;
    
    vec2 base_texel_size = get_texel_size();
    vec2 texel_size = use_wide_sampling ? base_texel_size * 1.5 : base_texel_size;
    float center_hue = get_hue(sample_color_safe(uv));
    
    if (use_multi_sampling) {
        int sample_count = use_high_quality_sampling ? 12 : 8;
        float max_diff = 0.0;
        
        if (use_circular_sampling) {
            for (int i = 0; i < 12; i++) {
                if (i >= sample_count) break;
                
                float angle = float(i) * 6.28318 / float(sample_count);
                vec2 offset = vec2(cos(angle), sin(angle)) * texel_size;
                
                float sample_hue = get_hue(sample_color_safe(uv + offset));
                // Handle hue wrapping (0 and 1 are the same hue)
                float hue_diff = abs(center_hue - sample_hue);
                hue_diff = min(hue_diff, 1.0 - hue_diff);
                max_diff = max(max_diff, hue_diff);
            }
        } else {
            vec2 offsets[12];
            offsets[0] = vec2(-texel_size.x, 0.0);
            offsets[1] = vec2(texel_size.x, 0.0);
            offsets[2] = vec2(0.0, -texel_size.y);
            offsets[3] = vec2(0.0, texel_size.y);
            offsets[4] = vec2(-texel_size.x, -texel_size.y);
            offsets[5] = vec2(texel_size.x, -texel_size.y);
            offsets[6] = vec2(-texel_size.x, texel_size.y);
            offsets[7] = vec2(texel_size.x, texel_size.y);
            offsets[8] = vec2(-texel_size.x * 2.0, 0.0);
            offsets[9] = vec2(texel_size.x * 2.0, 0.0);
            offsets[10] = vec2(0.0, -texel_size.y * 2.0);
            offsets[11] = vec2(0.0, texel_size.y * 2.0);
            
            for (int i = 0; i < 12; i++) {
                if (i >= sample_count) break;
                
                float sample_hue = get_hue(sample_color_safe(uv + offsets[i]));
                float hue_diff = abs(center_hue - sample_hue);
                hue_diff = min(hue_diff, 1.0 - hue_diff);
                max_diff = max(max_diff, hue_diff);
            }
        }
        
        return smoothstep(hue_threshold * 0.5, get_adaptive_threshold(uv, hue_threshold), max_diff);
    } else {
        // Simple 4-sample cross pattern
        float left_hue = get_hue(sample_color_safe(uv + vec2(-texel_size.x, 0.0)));
        float right_hue = get_hue(sample_color_safe(uv + vec2(texel_size.x, 0.0)));
        float up_hue = get_hue(sample_color_safe(uv + vec2(0.0, -texel_size.y)));
        float down_hue = get_hue(sample_color_safe(uv + vec2(0.0, texel_size.y)));
        
        // Handle hue wrapping for all comparisons
        float left_diff = abs(center_hue - left_hue);
        left_diff = min(left_diff, 1.0 - left_diff);
        
        float right_diff = abs(center_hue - right_hue);
        right_diff = min(right_diff, 1.0 - right_diff);
        
        float up_diff = abs(center_hue - up_hue);
        up_diff = min(up_diff, 1.0 - up_diff);
        
        float down_diff = abs(center_hue - down_hue);
        down_diff = min(down_diff, 1.0 - down_diff);
        
        float hue_diff = left_diff + right_diff + up_diff + down_diff;
        return smoothstep(hue_threshold * 0.5, get_adaptive_threshold(uv, hue_threshold), hue_diff);
    }
}

// === NEON TUBE COLOR PALETTE ===
/**
 * Returns a preset neon color for each tube index.
 * 0: Electric Blue      1: Hot Pink          2: Lemon Yellow
 * 3: Lime Green         4: Orange            5: Deep Red
 * 6: Pure White         7: Aqua Cyan         8: Violet Purple
 * 9: Mint Green        10: Tangerine         11: Magenta
 *12: Sky Blue          13: Ruby Red          14: Ultra Violet
 * (Expand as needed)
 */

vec3 neon_palette(int idx) {
    if (idx == 0)  return vec3(0.0, 0.9, 1.0);     // Electric Blue
    if (idx == 1)  return vec3(1.0, 0.27, 0.95);   // Hot Pink
    if (idx == 2)  return vec3(1.0, 1.0, 0.3);     // Lemon Yellow
    if (idx == 3)  return vec3(0.3, 1.0, 0.32);    // Lime Green
    if (idx == 4)  return vec3(1.0, 0.55, 0.1);    // Orange
    if (idx == 5)  return vec3(1.0, 0.12, 0.13);   // Deep Red
    if (idx == 6)  return vec3(1.0, 1.0, 1.0);     // Pure White
    if (idx == 7)  return vec3(0.08, 1.0, 0.85);   // Aqua Cyan
    if (idx == 8)  return vec3(0.63, 0.25, 1.0);   // Violet Purple
    if (idx == 9)  return vec3(0.6, 1.0, 0.7);     // Mint Green
    if (idx == 10) return vec3(1.0, 0.75, 0.1);    // Tangerine
    if (idx == 11) return vec3(1.0, 0.14, 0.82);   // Magenta
    if (idx == 12) return vec3(0.35, 0.67, 1.0);   // Sky Blue
    if (idx == 13) return vec3(0.95, 0.1, 0.25);   // Ruby Red
    if (idx == 14) return vec3(0.64, 0.0, 1.0);    // Ultra Violet

    // Add more if needed!
    return vec3(1.0, 1.0, 1.0); // Fallback: Pure White
}



// === EDGE COMBINATION ===
float detect_all_edges(vec2 uv) {
    float color_edge = detect_color_edges(uv);
    float luminance_edge = detect_luminance_edges(uv);
    float saturation_edge = detect_saturation_edges(uv);
    float hue_edge = detect_hue_edges(uv);
    
    return max(max(color_edge, luminance_edge), max(saturation_edge, hue_edge));
}

// === EDGE DILATION ===
float dilate_edges(vec2 uv, float base_edge_factor) {
    if (!use_edge_dilation || base_edge_factor <= 0.0) return base_edge_factor;
    
    vec2 texel_size = get_texel_size() * dilation_radius;
    float max_edge = base_edge_factor;
    
    // Fixed 8-sample pattern for dilation
    vec2 offsets[8];
    offsets[0] = vec2(-texel_size.x, 0.0);
    offsets[1] = vec2(texel_size.x, 0.0);
    offsets[2] = vec2(0.0, -texel_size.y);
    offsets[3] = vec2(0.0, texel_size.y);
    offsets[4] = vec2(-texel_size.x, -texel_size.y);
    offsets[5] = vec2(texel_size.x, -texel_size.y);
    offsets[6] = vec2(-texel_size.x, texel_size.y);
    offsets[7] = vec2(texel_size.x, texel_size.y);
    
    for (int i = 0; i < 8; i++) {
        vec2 sample_uv = uv + offsets[i];
        
        if (is_valid_uv(sample_uv)) {
            float neighbor_edge = detect_all_edges(sample_uv);
            max_edge = max(max_edge, neighbor_edge * 0.7);
        }
    }
    
    return max_edge;
}

// === EDGE SMOOTHING ===
float smooth_edges(float edge_factor, vec2 uv) {
    if (!use_edge_smoothing || edge_factor <= 0.0) return edge_factor;
    
    vec2 texel_size = get_texel_size() * 0.5;
    float total_weight = edge_factor;
    float total_factor = edge_factor;
    
    // Sample 4 neighboring pixels and blend
    vec2 neighbors[4];
    neighbors[0] = vec2(-texel_size.x, 0.0);
    neighbors[1] = vec2(texel_size.x, 0.0);
    neighbors[2] = vec2(0.0, -texel_size.y);
    neighbors[3] = vec2(0.0, texel_size.y);
    
    for (int i = 0; i < 4; i++) {
        vec2 sample_uv = uv + neighbors[i];
        if (is_valid_uv(sample_uv)) {
            float neighbor_edge = detect_all_edges(sample_uv);
            float weight = 0.25;
            total_factor += neighbor_edge * weight;
            total_weight += weight;
        }
    }
    
    return total_factor / total_weight;
}

// === ENHANCED DITHERING ===
float apply_simple_dithering(float edge_factor, vec2 screen_uv) {
    if (!use_dithered_edges) return edge_factor;
    
    vec2 dither_uv = screen_uv * screen_size / dither_scale;
    float dither_value = 0.0;
    
    if (use_advanced_dither) {
        // Advanced multi-pattern dithering
        float checker_x = mod(floor(dither_uv.x), 2.0);
        float checker_y = mod(floor(dither_uv.y), 2.0);
        
        // Base checkerboard
        float checker = abs(checker_x - checker_y);
        
        // Add diagonal stripes
        float diagonal = mod(floor(dither_uv.x + dither_uv.y), 2.0);
        
        // Add noise pattern
        float noise = fract(sin(dot(dither_uv, vec2(12.9898, 78.233))) * 43758.5453);
        
        // Combine patterns
        dither_value = mix(checker, diagonal, 0.3);
        dither_value = mix(dither_value, noise, 0.2);
        dither_value += sin(dither_uv.x * 2.0) * sin(dither_uv.y * 2.0) * 0.1;
        
    } else {
        // Simple checkerboard-based dithering pattern
        float checker_x = mod(floor(dither_uv.x), 2.0);
        float checker_y = mod(floor(dither_uv.y), 2.0);
        
        // Create alternating pattern
        dither_value = abs(checker_x - checker_y);
        
        // Add some variation with sine waves
        dither_value += sin(dither_uv.x * 3.14159) * sin(dither_uv.y * 3.14159) * 0.25;
    }
    
    // Normalize and apply
    dither_value = (dither_value - 0.5) * dither_strength;
    float dithered_factor = edge_factor + dither_value;
    
    return clamp(dithered_factor, 0.0, 1.0);
}

// === LIGHTING MODULATION ===
float calculate_lighting_modulation(vec2 uv) {
    if (!use_lighting_modulation) return 1.0;
    
    vec3 color = sample_color_safe(uv);
    float luminance = get_luminance(color);
    
    float modulation = mix(1.0 + lighting_modulation_strength * 0.5, 
                          1.0 - lighting_modulation_strength * 0.3, 
                          luminance);
    return max(0.1, modulation);
}

// === ANIMATION ===
/**
 * Get the edge color for each pixel.
 * - If use_mask_texture is ON, samples mask_texture to pick color by region.
 * - If animate_edges is ON, blends between tube color and animation_color.
 * - Otherwise, uses neon_palette or global edge_color.
 */
vec3 get_final_edge_color(vec2 uv, vec3 original_color) {
    vec3 base_color = edge_color;

    if (use_mask_texture) {
        // Sample the mask at this pixel
        vec3 idc = texture(mask_texture, uv).rgb;
        int idx = 0;
        if (idc.r > 0.5)      idx = 1;
        else if (idc.g > 0.5) idx = 2;
        else if (idc.b > 0.5) idx = 3;
        // Else idx = 0 (default blue)
        base_color = neon_palette(idx);
    }

    if (animate_edges) {
        float pulse = sin(TIME * animation_speed) * 0.5 + 0.5;
        return mix(base_color, animation_color, pulse);
    } else {
        return base_color;
    }
}


// ============================================================================
// MAIN FRAGMENT FUNCTION - This is where everything comes together
// ============================================================================
void fragment() {
    vec2 uv = SCREEN_UV;
    vec3 original_color = sample_color_safe(uv);
    
    // Step 1: Detect edges using all enabled methods
    float edge_factor = detect_all_edges(uv);
    
    // Step 2: Apply edge smoothing if enabled (anti-aliasing)
    if (use_edge_smoothing) {
        edge_factor = smooth_edges(edge_factor, uv);
    }
    
    // Step 3: Apply edge dilation if enabled (bold/thick edges)
    edge_factor = dilate_edges(uv, edge_factor);
    
    // Step 4: Apply lighting modulation (adapt to scene brightness)
    float lighting_mod = calculate_lighting_modulation(uv);
    edge_factor *= lighting_mod;
    
    // Step 5: Apply overall edge strength
    edge_factor *= edge_strength;
    
    // Step 6: Apply dithering if enabled (retro/pixel effects)
    edge_factor = apply_simple_dithering(edge_factor, uv);
    
    // Step 7: Clamp final edge strength
    edge_factor = clamp(edge_factor, 0.0, 1.0);
    
    // Step 8: Get final edge color (potentially animated)
	vec3 final_edge_color = get_final_edge_color(uv, original_color);
    
    // Step 9: Apply render mode and output final result
    if (edge_only_mode) {
        // Edge-only mode: Show only edges with transparent background
        COLOR = vec4(final_edge_color, edge_factor);
    } else if (sharpening_mode) {
        // Sharpening mode: Add edges to original image for enhancement
        vec3 sharpened_color = original_color + (final_edge_color * edge_factor * sharpening_strength);
        COLOR = vec4(sharpened_color, 1.0);
    } else {
        // Normal blend mode: Mix edges with original image
        vec3 final_color = mix(original_color, final_edge_color, edge_factor);
        COLOR = vec4(final_color, 1.0);
    }
}

// ============================================================================
// QUICK START GUIDE FOR NEW USERS
// ============================================================================
/*

BASIC SETUP:
1. Apply this shader to a ColorRect or TextureRect
2. In GDScript, set: material.set_shader_param("screen_size", get_viewport().size)
3. Enable "use_color_edges" and "use_luminance_edges"
4. Adjust "edge_strength" and "color_threshold" to taste


// ---------------- PIXEL ART EDGE PRESET ----------------
uniform bool use_color_edges = true;          // Color boundaries
uniform bool use_luminance_edges = false;     // (OFF for most pixel art, but enable if using much shading)
uniform bool use_saturation_edges = false;
uniform bool use_hue_edges = false;

uniform vec3 edge_color = vec3(0.0, 0.0, 0.0); // Pure black for classic outlines
uniform float edge_strength = 2.0;             // Extra strong lines for readability
uniform float edge_thickness = 1.0;            // 1.0 for 1-pixel edges (true pixel scale)
uniform float color_threshold = 0.08;          // *Lowered* to pick up all pixel transitions
uniform float luminance_threshold = 0.08;      // Only matters if luminance edges enabled
uniform bool use_multi_sampling = false;       // Turn OFF for perfect grid, no anti-alias
uniform bool use_circular_sampling = false;    // Grid-based, not round
uniform bool use_high_quality_sampling = false;// OFF: Only 4 neighbors checked
uniform bool use_wide_sampling = false;        // OFF: No bleeding into diagonals
uniform bool edge_only_mode = false;           // See only outlines if true (set true for debug)
uniform bool sharpening_mode = false;          // Use only if you want extra sharp
uniform bool use_edge_smoothing = false;       // NO smoothing for pixel art
uniform bool use_edge_dilation = false;        // Use if you want thicker edges (rare for pixel art)
uniform bool use_dithered_edges = false;       // OFF unless you want retro dotty effect
uniform float dither_scale = 4.0;
uniform float dither_strength = 0.2;
uniform bool animate_edges = false;
uniform float animation_speed = 1.0;
uniform vec3 animation_color = vec3(1.0, 0.5, 0.0);
uniform bool use_lighting_modulation = false;  // OFF: Edges ignore lighting (good for sprites)
uniform float lighting_modulation_strength = 1.0;
uniform bool use_adaptive_threshold = false;   // OFF for grid games


OTHER COMMON PRESETS:

COMIC BOOK STYLE:
- use_color_edges = true
- use_luminance_edges = true  
- edge_color = (0, 0, 0) [black]
- edge_strength = 1.5
- use_edge_dilation = true
- use_dithered_edges = true

TECHNICAL DRAWING:
- use_luminance_edges = true (only)
- edge_color = (0, 0, 0) [black]
- edge_only_mode = true
- use_high_quality_sampling = true

GLOWING EFFECT:
- animate_edges = true
- edge_color = (0, 0.2, 1) [blue]
- animation_color = (1, 1, 1) [white]
- animation_speed = 2.0

PHOTO ENHANCEMENT:
- sharpening_mode = true
- use_lighting_modulation = true
- use_adaptive_threshold = true
- sharpening_strength = 0.3

PERFORMANCE TIPS:
- Disable unused edge types (saturation/hue are slowest)
- Turn off high_quality_sampling for real-time use
- Use edge_only_mode for UI overlays
- Lower dither_scale for less processing

*/

// ------------------------------------------------------------------------
// NEON MULTICOLOR EDGES GUIDE:
// ------------------------------------------------------------------------
// To assign custom tube colors, create a mask/ID texture where:
//   - Red channel (R > 0.5) = Tube Color 1 (Pink)
//   - Green channel (G > 0.5) = Tube Color 2 (Yellow)
//   - Blue channel (B > 0.5) = Tube Color 3 (Green)
//   - Black (all channels < 0.5) = Tube Color 0 (Blue, default)
//
// To add more colors, extend neon_palette() and add more index checks.
//
// Assign your mask texture to the material's "mask_texture" property.
// Set "use_mask_texture" to true.
// That's it!
// ------------------------------------------------------------------------
