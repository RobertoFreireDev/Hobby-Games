sampler2D TextureSampler : register(s0);
sampler2D NormalMapSampler : register(s1);

float3 LightDirection = float3(0.0f, 0.0f, 1.0f);
float3 LightColor = float3(1.0f, 1.0f, 1.0f);

struct PixelInput
{
    float2 TexCoord : TEXCOORD0;
};

float4 MainPS(PixelInput input) : COLOR
{
    // Sample the main texture color
    float4 color = tex2D(TextureSampler, input.TexCoord);

    // Sample the normal map
    float3 normal = tex2D(NormalMapSampler, input.TexCoord).rgb;
    normal = normalize(normal * 2.0 - 1.0); // Convert to [-1, 1] range

    // Calculate the light intensity
    float lightIntensity = max(dot(normal, LightDirection), 0.0);

    // Apply the light color and intensity to the sprite color
    float3 finalColor = color.rgb * LightColor * lightIntensity;

    return float4(finalColor, color.a);
}

technique Basic
{
    pass Pass1
    {
        PixelShader = compile ps_3_0 MainPS();
    }
}
