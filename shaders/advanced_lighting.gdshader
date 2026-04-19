shader_type canvas_item;

// Advanced lighting shader for 2D pixel art with dynamic shadows and glow
uniform vec4 modulate_color : source_color = vec4(1.0);
uniform float light_intensity : hint_range(0.0, 5.0) = 1.0;
uniform vec4 light_color : source_color = vec4(1.0, 1.0, 0.8, 1.0);
uniform float shadow_strength : hint_range(0.0, 2.0) = 0.5;
uniform float glow_radius : hint_range(0.0, 100.0) = 20.0;
uniform float pixel_size : hint_range(1.0, 16.0) = 1.0;

void fragment() {
    vec2 uv = UV;
    vec4 tex_color = texture(TEXTURE, uv);
    
    if (tex_color.a < 0.01) {
        discard;
    }
    
    // Calculate distance from center for glow effect
    vec2 center = vec2(0.5, 0.5);
    float dist = distance(uv, center);
    
    // Apply dynamic lighting
    float light_factor = 1.0;
    
    // Simulate directional light
    vec3 light_dir = normalize(vec3(0.3, -0.7, 0.5));
    float light_dot = max(0.0, light_dir.z);
    light_factor = 0.6 + 0.4 * light_dot;
    
    // Add glow effect
    if (glow_radius > 0.0) {
        float glow_factor = 1.0 - smoothstep(0.0, glow_radius / 100.0, dist);
        light_factor += glow_factor * light_intensity * 0.3;
    }
    
    // Apply shadows (simplified 2D shadow mapping)
    if (shadow_strength > 0.0) {
        vec2 shadow_uv = uv + vec2(0.02, 0.02) * pixel_size;
        vec4 shadow_sample = texture(TEXTURE, shadow_uv);
        float shadow_factor = 1.0 - shadow_strength * (1.0 - shadow_sample.a) * 0.3;
        light_factor *= shadow_factor;
    }
    
    // Apply lighting to color
    vec3 final_color = tex_color.rgb * light_color.rgb * light_factor;
    
    // Add subtle rim lighting
    vec2 texel_size = 1.0 / texture_size(TEXTURE);
    float rim = 0.0;
    
    // Sample neighboring texels for rim detection
    vec4 sample_n = texture(TEXTURE, uv + vec2(0.0, -texel_size.y));
    vec4 sample_s = texture(TEXTURE, uv + vec2(0.0, texel_size.y));
    vec4 sample_e = texture(TEXTURE, uv + vec2(texel_size.x, 0.0));
    vec4 sample_w = texture(TEXTURE, uv + vec2(-texel_size.x, 0.0));
    
    float max_neighbor = max(max(sample_n.a, sample_s.a), max(sample_e.a, sample_w.a));
    rim = max_neighbor - tex_color.a;
    
    if (rim > 0.1) {
        final_color += light_color.rgb * rim * 0.5;
    }
    
    COLOR = vec4(final_color, tex_color.a) * modulate_color;
}
