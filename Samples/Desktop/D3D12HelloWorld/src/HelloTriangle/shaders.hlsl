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
    float2 c = float2(
        input.uv.x * 3.0 - 2.0,
        input.uv.y * 2.0 - 1.0
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
