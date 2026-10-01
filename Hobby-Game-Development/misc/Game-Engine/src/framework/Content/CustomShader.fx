// CustomShader.fx

sampler2D TextureSampler : register(s0);

// Distortion parameters
float DistortX; // e.g., 0.05
float DistortY; // e.g., 0.05
float Time; // time in seconds
int DistortMode;

// Wave parameters
float WaveFreq; // e.g., 20
float WaveSpeed; // e.g., 3

// Scroll parameters
float ScrollX; // pixels per second or normalized speed
float ScrollY;

// Color & Transparency
int ColorMode;
float4 Color; // RGBA (1,1,1,1 = no change)

// Outline
float OutlineThickness;

// Noise intensity
float NoiseAmount; // e.g., 0.05

// border 
float4 Border;

// ------------------------------
// Helpers
// ------------------------------
float rand(float2 co)
{
    return frac(sin(dot(co.xy, float2(12.9898, 78.233))) * 43758.5453);
}

// ------------------------------
// Effects
// ------------------------------

// Distortion + scroll
float2 ApplyDistortionScroll(float2 uv)
{
    if (DistortMode == 1)
    {
        float waveX = sin(uv.y * WaveFreq + Time * WaveSpeed) * DistortX + Time * ScrollX;
        float waveY = cos(uv.x * WaveFreq + Time * WaveSpeed) * DistortY + Time * ScrollY;
        return uv + float2(waveX, waveY);
    }
    
    if (DistortMode == 2)
    {
        float waveX = sin(uv.y * WaveFreq + Time * WaveSpeed) * DistortX + frac(Time * ScrollX);
        float waveY = cos(uv.x * WaveFreq + Time * WaveSpeed) * DistortY + frac(Time * ScrollY);
        return frac(uv + float2(waveX, waveY));
    }
    
    return uv;

}

// Tint
float4 ApplyTint(float4 color)
{
    return color * Color;
}

// Noise
float4 ApplyNoise(float4 color, float2 uv)
{
    if (NoiseAmount > 0)
    {
        float n = rand(uv + Time);
        color.rgb += (n - 0.5) * NoiseAmount;
    }
    return color;
}

// Outline
float4 ApplyOutline(float4 color, float2 uv)
{
    if (color.a > 0.1)
    {
        if (OutlineThickness > 0)
        {
            return float4(0, 0, 0, 0);
        }
        else
        {
            return color;
        }
    }

    float4 neighbor =
        tex2D(TextureSampler, uv + float2(OutlineThickness, 0)) +
        tex2D(TextureSampler, uv + float2(-OutlineThickness, 0)) +
        tex2D(TextureSampler, uv + float2(0, OutlineThickness)) +
        tex2D(TextureSampler, uv + float2(0, -OutlineThickness));

    if (neighbor.a > 0.1)
        return Color;

    return color;
}

// Outline
float4 ApplyColorScale(float4 color)
{
    float intensity = dot(color.rgb, Color.rgb);
    color.rgb = intensity.xxx;
    return color * Color;
}

float4 ApplyGrayScale(float4 color)
{
    float intensity = dot(color.rgb, Color.rgb);
    color.rgb = intensity.xxx;
    return color;
}

// ------------------------------
// Main
// ------------------------------
float4 main(float2 uv : TEXCOORD0) : COLOR0
{
    // Discard pixels near edges
    if (uv.x < Border.x || uv.x > 1.0 - Border.y || uv.y < Border.z || uv.y > 1.0 - Border.w)
    {
        return float4(0, 0, 0, 0); // Transparent (or background color)
    }
    
    float2 distortedUV = ApplyDistortionScroll(uv);
    float4 baseColor = tex2D(TextureSampler, distortedUV);
    if (ColorMode == 1)
    {
        baseColor = ApplyTint(baseColor);
    }
    else if(ColorMode == 2)
    {
        baseColor = ApplyColorScale(baseColor);
    }
    else if (ColorMode == 3)
    {
        baseColor = ApplyGrayScale(baseColor);
    }
    
    baseColor = ApplyNoise(baseColor, distortedUV);
    baseColor = ApplyOutline(baseColor, distortedUV);
    
    return baseColor;
}

technique Technique1
{
    pass Pass1
    {
        PixelShader = compile ps_3_0 main();
    }
}