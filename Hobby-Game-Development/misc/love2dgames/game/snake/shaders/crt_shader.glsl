vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Sample the texture
    vec4 texColor = Texel(texture, texture_coords);

    // Apply row pattern horizontally (darken 2, skip 2)
    float horizontalPattern = mod(floor(screen_coords.x / 2.0), 4.0) < 2.0 ? 0.7 : 1.0;

    // Apply row pattern vertically (darken 2, skip 2)
    float verticalPattern = mod(floor(screen_coords.y / 2.0), 4.0) < 2.0 ? 0.7 : 1.0;

    // Combine both horizontal and vertical patterns
    texColor.rgb *= horizontalPattern * verticalPattern;

    return texColor * color;
}