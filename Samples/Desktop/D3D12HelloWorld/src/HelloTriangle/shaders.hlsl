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
    float4 offset; // xy = offset, z = scale
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
    float2 viewOffset = offset.xy;
    float viewScale = offset.z;

    // Map UV coordinates (0 to 1) to complex plane coordinates using view parameters
    // Adjust the base range and apply offset and scale
    float aspectRatio = 1.0; // Assuming square aspect ratio mapping for now. We might need to pass screen dimensions later.
    float baseWidth = 3.0;
    float baseHeight = 2.0; // Adjust based on the initial complex plane view

    float2 c = float2(
        (input.uv.x - 0.5) * baseWidth / viewScale + viewOffset.x,
        (input.uv.y - 0.5) * baseHeight / viewScale + viewOffset.y
    );

    float2 z = float2(0.0, 0.0);
    int max_iterations = 100;
    int iterations = 0;

    for (int i = 0; i < max_iterations; ++i)
    {
        float zx = z.x * z.x - z.y * z.y + c.x;
        float zy = 2.0 * z.x * z.y + c.y;
        z = float2(zx, zy);

        if (dot(z, z) > 4.0)
        {
            iterations = i;
            break;
        }
    }

    // Color based on iteration count
    float3 color = float3(0.0, 0.0, 0.0); // Default to black (inside set)

    if (dot(z, z) > 4.0) // Check if it escaped
    {
        // Smooth iteration count calculation
        // iterations = i + 1 - log2(log2(length(z))) 
        // Using dot(z,z) = length(z)^2 avoids sqrt()
        // iterations = i + 1 - log2(log2(sqrt(dot(z,z))))
        // iterations = i + 1 - log2(0.5 * log2(dot(z,z)))
        float smooth_iter = (float)iterations + 1.0 - log2(log2(dot(z, z))) / 2.0;

        // Simple cyclical color mapping based on smooth iteration count
        float t = smooth_iter / 16.0f; // Adjust denominator for color frequency
        color.r = 0.5f + 0.5f * cos(3.14159f * 2.0f * t + 0.0f);
        color.g = 0.5f + 0.5f * cos(3.14159f * 2.0f * t + 2.0f * 3.14159f / 3.0f);
        color.b = 0.5f + 0.5f * cos(3.14159f * 2.0f * t + 4.0f * 3.14159f / 3.0f);
    }
    
    return float4(color, 1.0f);
}
