shader_type canvas_item;

// Screen effects shader for post-processing effects
uniform float chromatic_aberration : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.3;
uniform float film_grain_strength : hint_range(0.0, 1.0) = 0.1;
uniform float time : hint_range(0.0, 100.0) = 0.0;
uniform float pixel_size : hint_range(1.0, 8.0) = 1.0;

// Random function for film grain
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;
    vec2 texel_size = 1.0 / texture_size(TEXTURE);
    
    // Apply pixelation
    vec2 pixelated_uv = floor(uv * texture_size(TEXTURE) / pixel_size) * pixel_size * texel_size;
    
    vec4 color = texture(TEXTURE, pixelated_uv);
    
    // Chromatic aberration effect
    if (chromatic_aberration > 0.0) {
        float aberration_offset = chromatic_aberration * 0.002;
        vec4 color_r = texture(TEXTURE, pixelated_uv + vec2(aberration_offset, 0.0));
        vec4 color_b = texture(TEXTURE, pixelated_uv - vec2(aberration_offset, 0.0));
        
        color.r = color_r.r;
        color.b = color_b.b;
    }
    
    // Vignette effect
    if (vignette_strength > 0.0) {
        vec2 center = vec2(0.5, 0.5);
        float dist = distance(uv, center);
        float vignette = 1.0 - smoothstep(0.3, 0.8, dist) * vignette_strength;
        color.rgb *= vignette;
    }
    
    // Film grain effect
    if (film_grain_strength > 0.0) {
        float grain = random(vec2(uv.x * time, uv.y * time)) * 2.0 - 1.0;
        grain *= film_grain_strength;
        color.rgb += grain;
    }
    
    COLOR = color;
}
