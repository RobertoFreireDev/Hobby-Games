// CRT.fx
sampler2D TextureSampler : register(s0);

// --- Basic settings ---
float2 Resolution;

// --- Vignette ---
float Inner; 
float Outer;

// helper: saturate for ps_3_0
float saturate_f(float x)
{
    return clamp(x, 0.0, 1.0);
}

float4 main(float2 uv : TEXCOORD0) : COLOR0
{
    float VignettePower = 1.25;

    // --- Curvature ---
    float CurveStrength = 0.03; // barrel distortion

    // --- Chromatic Aberration ---
    float CAAmount = 0.0001; // RGB channel offset

    // --- Scanlines ---
    float ScanFreq = 1.5; // base frequency (multiplied by Resolution.y / 480)
    float ScanIntensityMin = 0.85;
    float ScanIntensityMax = 1.05;

    // --- Contrast & Gain ---
    float Contrast = 1.02;
    float Gain = 1.02;

    // --- Phosphor / Soft Bloom ---
    float PhosphorMix = 0.02; // neighbor blending

    // --- Color Grade / Warmth ---
    float3 Grade = float3(1.02, 1.01, 0.98);

    // --- Final gamma / S-curve ---
    float3 Gamma = float3(0.98, 0.98, 0.98);

    
    float2 px = uv * Resolution;
    float aspect = Resolution.x / Resolution.y;

    // --- Curvature ---
    float2 center = uv - 0.5;
    float2 c = float2(center.x * aspect, center.y);
    float r2 = dot(c, c);
    float2 uv_curved = uv + center * (r2 * CurveStrength);
    uv_curved = saturate(uv_curved);

    // --- Chromatic Aberration ---
    float2 caOffset = center * CAAmount * (1.0 + r2 * 2.0);
    float4 colR = tex2D(TextureSampler, uv_curved + caOffset);
    float4 colG = tex2D(TextureSampler, uv_curved);
    float4 colB = tex2D(TextureSampler, uv_curved - caOffset);
    float3 col = float3(colR.r, colG.g, colB.b);

    // --- Scanlines ---
    float scanFreqAdj = ScanFreq * (Resolution.y / 480.0);
    float scan = 0.5 + 0.5 * sin(px.y * scanFreqAdj * 3.14159);
    float scanIntensity = lerp(ScanIntensityMin, ScanIntensityMax, scan);
    col *= scanIntensity;

    // --- Contrast & Gain ---
    col = (col - 0.5) * Contrast + 0.5;
    col *= Gain;

    // --- Vignette ---
    float2 v = center;
    v.x *= aspect;
    float dist = length(v);
    float vignette = saturate_f(1.0 - smoothstep(Inner, Outer, dist));
    vignette = pow(vignette, VignettePower);
    col *= vignette;

    // --- Phosphor / Soft Bloom ---
    float2 pxUV = 1.0 / Resolution;
    float3 neighbor = tex2D(TextureSampler, uv_curved + float2(pxUV.x, 0)).rgb
                    + tex2D(TextureSampler, uv_curved - float2(pxUV.x, 0)).rgb
                    + tex2D(TextureSampler, uv_curved + float2(0, pxUV.y)).rgb
                    + tex2D(TextureSampler, uv_curved - float2(0, pxUV.y)).rgb;
    neighbor *= 0.25;
    col = lerp(col, neighbor, PhosphorMix);

    // --- Color Grade ---
    col *= Grade;

    // --- Final gamma / s-curve ---
    col = saturate(col);
    col = pow(col, Gamma);

    return float4(col, 1.0);
}

technique Technique1
{
    pass Pass1
    {
        PixelShader = compile ps_3_0 main();
    }
}