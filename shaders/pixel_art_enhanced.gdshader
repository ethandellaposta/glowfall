shader_type canvas_item;

// Enhanced pixel art shader with smooth scaling and visual effects
uniform vec4 modulate_color : source_color = vec4(1.0);
uniform float pixel_size : hint_range(1.0, 16.0) = 1.0;
uniform float smoothness : hint_range(0.0, 1.0) = 0.1;
uniform float glow_intensity : hint_range(0.0, 2.0) = 0.0;
uniform float outline_thickness : hint_range(0.0, 2.0) = 0.0;
uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    // Get the base texture coordinate
    vec2 uv = UV;
    
    // Apply pixelation with smooth scaling
    vec2 pixelated_uv = floor(uv * pixel_size) / pixel_size;
    
    // Sample the texture with pixelated coordinates
    vec4 tex_color = texture(TEXTURE, pixelated_uv);
    
    // Apply smoothness for anti-aliasing
    if (smoothness > 0.0) {
        vec2 texel_size = 1.0 / texture_size(TEXTURE) * pixel_size;
        vec4 color_n = texture(TEXTURE, pixelated_uv + vec2(0.0, -texel_size.y));
        vec4 color_s = texture(TEXTURE, pixelated_uv + vec2(0.0, texel_size.y));
        vec4 color_e = texture(TEXTURE, pixelated_uv + vec2(texel_size.x, 0.0));
        vec4 color_w = texture(TEXTURE, pixelated_uv + vec2(-texel_size.x, 0.0));
        
        float alpha_diff = max(max(max(abs(tex_color.a - color_n.a), abs(tex_color.a - color_s.a)),
                                  max(abs(tex_color.a - color_e.a), abs(tex_color.a - color_w.a))), 0.01);
        
        float smooth_factor = min(smoothness / alpha_diff, 1.0);
        tex_color = mix(tex_color, texture(TEXTURE, UV), smooth_factor);
    }
    
    // Apply outline effect
    if (outline_thickness > 0.0 && tex_color.a > 0.1) {
        vec2 texel_size = 1.0 / texture_size(TEXTURE) * pixel_size;
        float outline_alpha = 0.0;
        
        for (float x = -outline_thickness; x <= outline_thickness; x += 1.0) {
            for (float y = -outline_thickness; y <= outline_thickness; y += 1.0) {
                if (x != 0.0 || y != 0.0) {
                    vec2 offset = vec2(x, y) * texel_size;
                    vec4 sample = texture(TEXTURE, pixelated_uv + offset);
                    outline_alpha = max(outline_alpha, sample.a);
                }
            }
        }
        
        if (outline_alpha > 0.1 && tex_color.a < 0.5) {
            tex_color = mix(outline_color, tex_color, tex_color.a);
            tex_color.a = max(tex_color.a, outline_alpha * 0.8);
        }
    }
    
    // Apply glow effect
    if (glow_intensity > 0.0 && tex_color.a > 0.1) {
        vec2 texel_size = 1.0 / texture_size(TEXTURE) * pixel_size;
        float glow = 0.0;
        
        for (float x = -2.0; x <= 2.0; x += 1.0) {
            for (float y = -2.0; y <= 2.0; y += 1.0) {
                if (x != 0.0 || y != 0.0) {
                    vec2 offset = vec2(x, y) * texel_size;
                    vec4 sample = texture(TEXTURE, pixelated_uv + offset);
                    glow += sample.a;
                }
            }
        }
        
        glow = glow / 24.0 * glow_intensity;
        tex_color.rgb += tex_color.rgb * glow;
    }
    
    // Apply final modulation
    COLOR = tex_color * modulate_color;
}
