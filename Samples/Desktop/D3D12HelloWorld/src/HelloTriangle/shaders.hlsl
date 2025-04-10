//*********************************************************
//
// Copyright (c) Microsoft. All rights reserved.
// This code is licensed under the MIT License (MIT).
// THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
// IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
// PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
//
//*********************************************************

cbuffer SceneConstantBuffer : register(b0)
{
    double offsetX; // Double precision
    double offsetY;
    double scale;
    double padding;
};

struct PSInput
{
    float4 position : SV_POSITION;
    float2 uv : TEXCOORD0;
};

PSInput VSMain(float4 position : POSITION)
{
    PSInput result;

    result.position = position;
    result.uv = position.xy * 0.5 + 0.5;

    return result;
}

float4 PSMain(PSInput input) : SV_TARGET
{
    // Extract view parameters from constant buffer
    double2 viewOffset = double2(offsetX, offsetY); // Use double precision vector
    double viewScale = scale; // Use double precision

    // Map UV coordinates (0 to 1) to complex plane coordinates using view parameters
    // Using double precision for calculations
    double aspectRatio = 1.0; // Assuming square aspect ratio mapping for now.
    double baseWidth = 3.0;
    double baseHeight = 2.0; // Adjust based on the initial complex plane view

    // Use double precision for complex coordinate c
    double2 c = double2(
        (input.uv.x - 0.5) * baseWidth / viewScale + viewOffset.x,
        (input.uv.y - 0.5) * baseHeight / viewScale + viewOffset.y
    );

    // Mandelbrot iteration using double precision
    double2 z = double2(0.0, 0.0); // Use double precision vector
    int max_iterations = 100; // Max iterations can remain int
    int iterations = 0;

    for (int i = 0; i < max_iterations; ++i)
    {
        // Use double precision for zx, zy and calculations
        double zx = z.x * z.x - z.y * z.y + c.x;
        double zy = 2.0 * z.x * z.y + c.y;
        z = double2(zx, zy);

        // Check if escaped (magnitude squared > 4.0 - use double comparison)
        if (dot(z, z) > 4.0)
        {
            iterations = i;
            break;
        }
    }

    // Color based on iteration count
    float3 color = float3(0.0, 0.0, 0.0); // Final color can remain float3

    if (dot(z, z) > 4.0) // Check if it escaped
    {
        // Smooth iteration count calculation using double precision where needed
        double dz_sq = dot(z,z);
        // Use log/log2 that operate on doubles if available, otherwise convert back to float carefully
        // Note: HLSL log/log2 might implicitly use float. Explicit casts might be needed if precision issues persist.
        float smooth_iter = (float)iterations + 1.0f - (float)(log2(log2(dz_sq)) / 2.0);

        // Simple cyclical color mapping based on smooth iteration count
        float t = smooth_iter / 16.0f; // Use float for color interpolation
        color.r = 0.5f + 0.5f * cos(3.14159f * 2.0f * t + 0.0f);
        color.g = 0.5f + 0.5f * cos(3.14159f * 2.0f * t + 2.0f * 3.14159f / 3.0f);
        color.b = 0.5f + 0.5f * cos(3.14159f * 2.0f * t + 4.0f * 3.14159f / 3.0f);
    }
    
    return float4(color, 1.0f);
}
