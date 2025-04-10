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
        iterations = i;
    }

    float color = (float)iterations / (float)max_iterations;
    
    if (iterations == max_iterations - 1)
    {
        color = 0.0;
    }
    
    return float4(color, color, color, 1.0f);
}
