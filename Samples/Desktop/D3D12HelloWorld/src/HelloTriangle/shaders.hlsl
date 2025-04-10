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

// Function to convert HSV color to RGB
// H: Hue (0-1), S: Saturation (0-1), V: Value (0-1)
float3 hsv2rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

// Function for custom gradient based on user specification
float3 getGradientColor(float t)
{
    // Define color stops (RGB 0-1) and their positions (0-1) - Removed blackish stop
    const int NUM_STOPS = 5; // Now 5 stops
    float3 colors[NUM_STOPS] = {
        float3(0.0f, 0.027f, 0.392f),  // Dark Blue (0, 7, 100)
        float3(0.125f, 0.420f, 0.796f), // Blue      (32, 107, 203)
        float3(0.929f, 1.0f, 1.0f),    // White     (237, 255, 255)
        float3(1.0f, 0.667f, 0.0f),    // Orange    (255, 170, 0)
        float3(0.0f, 0.027f, 0.392f)   // Dark Blue (wrap)
    };
    // Adjusted stops to remove the gap for blackish
    float stops[NUM_STOPS] = { 0.0f, 0.16f, 0.42f, 0.6425f, 1.0f }; 

    // Find the segment t falls into and lerp
    for (int i = 0; i < NUM_STOPS - 1; ++i)
    {
        if (t >= stops[i] && t <= stops[i+1])
        {
            // Normalize t to the range [0, 1] within this segment
            float local_t = (t - stops[i]) / (stops[i+1] - stops[i]);
            // Handle potential division by zero if stops are identical
            if (stops[i+1] <= stops[i]) return colors[i]; 
            return lerp(colors[i], colors[i+1], local_t);
        }
    }

    // Fallback (if t is exactly 1.0 or slightly outside due to precision)
    return colors[NUM_STOPS - 1]; // Returns the wrap color (Dark Blue)
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

        // Check if escaped (magnitude squared > 8.0 - matching potential formula derivation)
        if (dot(z, z) > 8.0)
        {
            iterations = i;
            break;
        }
    }

    // Color based on iteration count
    float3 color = float3(0.0, 0.0, 0.0); // Final color starts black

    if (dot(z, z) > 8.0) // Check if it escaped
    {
        // Smooth iteration calculation based on Wikipedia suggestion (log2(log2 |z|^2))
        double dz_sq = dot(z, z);
        // Note: HLSL log2 operates on float, cast double value carefully.
        float smooth_iter = (float)iterations + 1.0f - log2(log2((float)dz_sq));
        
        // Map smooth iteration to t (0-1 cycle)
        float t = frac(smooth_iter / 30.0f); // Adjust scale (e.g., 30.0f) for desired frequency/density

        // Get color from custom gradient
        color = getGradientColor(t);
    }
    
    return float4(color, 1.0f);
}
