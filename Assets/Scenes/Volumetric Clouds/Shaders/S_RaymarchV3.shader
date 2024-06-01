Shader "Volumetric Clouds/RaymarchV3"
{
    Properties
    {
        _VolumeTex("Volume Tex", 3D) = "white" {}
        _NumSteps("Num Steps", Float) = 64.0
        _StepSize("Step Size", Float) = 0.02
        _DensityScale("Density Scale", Range(0.0, 1.0)) = 0.02
        _Offset("Offset", Vector) = (0.5, 0.5, 0.5)
        _LightNumSteps("Light Num Steps", Float) = 16
        _LightStepSize("Light Step Size", Float) = 0.02
        _LightAbsorb("Light Absorb", Float) = 0
        _DarknessThreshold("Darkness Threshold", Float) = 0
        _Transmittance("Transmittance", Float) = 0
        _ShadowColor("Shadow Color", Color) = (0, 0, 0, 1)
        _Color("Color", Color) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Transparent"
            "RenderType" = "Transparent"
        }

        Pass
        {
            Tags
            {
                "LightMode" = "SRPDefaultUnlit"
            }
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Assets/Scenes/Volumetric Clouds/HLSL/Raymarch.hlsl"

            struct attributes
            {
                float3 positionOS: POSITION;
            };

            struct varyings
            {
                float4 positionHCS: SV_POSITION;
                float3 positionOS: TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _VolumeTex_ST;
                float _NumSteps;
                float _StepSize;
                float _DensityScale;
                float3 _Offset;
                float _LightNumSteps;
                float _LightStepSize;
                float _LightAbsorb;
                float _DarknessThreshold;
                float _Transmittance;
                float4 _ShadowColor;
                float4 _Color;
            CBUFFER_END

            Texture3D _VolumeTex;
            SamplerState sampler_VolumeTex;

            varyings vert(attributes IN)
            {
                varyings OUT;
                OUT.positionOS = IN.positionOS;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                return OUT;
            }

            float4 frag(varyings IN) : SV_Target
            {
                float3 cameraPosOS = TransformWorldToObject(GetCameraPositionWS());
                float3 rayDirection = normalize(IN.positionOS - cameraPosOS);
                float lightDir = normalize(_MainLightPosition.xyz);
                float3 result;
                ray_march_v3_float(IN.positionOS, rayDirection, _NumSteps, _StepSize, _DensityScale, _VolumeTex,
                                   sampler_VolumeTex, _Offset, _LightNumSteps, _LightStepSize, lightDir,_LightAbsorb, _DarknessThreshold, _Transmittance, result);
                float3 color = lerp(_ShadowColor, _Color, result.r).xyz;
                return float4(color, 1.0 - result.g);
            }
            ENDHLSL
        }
    }
}