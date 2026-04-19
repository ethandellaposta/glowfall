shader_type canvas_item;
// Pixel Polish Shader - Advanced pixel enhancement and artifact removal

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform bool pixel_perfection = true;
uniform bool artifact_removal = true;
uniform bool contrast_enhancement = true;
uniform float analysis_strength = 1.0;
uniform float smoothing_factor = 0.8;

uniform vec2 correction_position = vec2(0.0);
uniform vec4 correction_color = vec4(1.0);
uniform bool apply_correction = false;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec4 original_color = texture(screen_texture, uv);
    
    // Pixel perfection mode - perfect pixel alignment
    if (pixel_perfection) {
        vec2 pixel_size = 1.0 / vec2(textureSize(screen_texture, 0));
        vec2 pixelated_uv = floor(uv / pixel_size) * pixel_size;
        original_color = texture(screen_texture, pixelated_uv);
    }
    
    // Artifact removal - smooth out imperfections
    if (artifact_removal) {
        vec2 texel_size = 1.0 / vec2(textureSize(screen_texture, 0));
        
        // Sample neighboring pixels for smoothing
        vec4 neighbors = vec4(0.0);
        neighbors += texture(screen_texture, uv + vec2(-texel_size.x, 0.0));
        neighbors += texture(screen_texture, uv + vec2(texel_size.x, 0.0));
        neighbors += texture(screen_texture, uv + vec2(0.0, -texel_size.y));
        neighbors += texture(screen_texture, uv + vec2(0.0, texel_size.y));
        neighbors /= 4.0;
        
        // Blend with smoothing factor
        original_color = mix(original_color, neighbors, smoothing_factor);
    }
    
    // Contrast enhancement
    if (contrast_enhancement) {
        vec3 adjusted = original_color.rgb - 0.5;
        adjusted *= 1.2;  // Contrast boost
        adjusted += 0.5;
        adjusted += 0.05;  // Brightness boost
        original_color.rgb = clamp(adjusted, 0.0, 1.0);
    }
    
    // Apply pixel correction if needed
    if (apply_correction) {
        vec2 pixel_size = 1.0 / vec2(textureSize(screen_texture, 0));
        float correction_radius = 3.0 * pixel_size.x;
        
        float distance = distance(uv, correction_position * pixel_size);
        if (distance < correction_radius) {
            float influence = 1.0 - (distance / correction_radius);
            original_color = mix(original_color, correction_color, influence * analysis_strength);
        }
    }
    
    // Final quality enhancement
    vec3 final_color = original_color.rgb;
    
    // Subtle sharpening
    vec2 sharpen_texel = 1.0 / vec2(textureSize(screen_texture, 0));
    vec4 center = texture(screen_texture, uv);
    vec4 up = texture(screen_texture, uv + vec2(0.0, -sharpen_texel.y));
    vec4 down = texture(screen_texture, uv + vec2(0.0, sharpen_texel.y));
    vec4 left = texture(screen_texture, uv + vec2(-sharpen_texel.x, 0.0));
    vec4 right = texture(screen_texture, uv + vec2(sharpen_texel.x, 0.0));
    
    vec4 sharpened = center * 5.0 - up - down - left - right;
    final_color = mix(final_color, sharpened.rgb, 0.1);
    
    COLOR = vec4(final_color, original_color.a);
}
