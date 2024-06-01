Shader "Volumetric Clouds/RaymarchV2"
{
    Properties
    {
        _VolumeTex("Volume Tex", 3D) = "white" {}
        _NumSteps("Num Steps", Float) = 64.0
        _StepSize("Step Size", Float) = 0.02
        _DensityScale("Density Scale", Range(0.0, 1.0)) = 0.02
        _Offset("Offset", Vector) = (0.5, 0.5, 0.5)
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
                float density;
                ray_march_v2_float(IN.positionOS, rayDirection, _NumSteps, _StepSize, _DensityScale, _VolumeTex,
                                   sampler_VolumeTex, _Offset, density);
                return float4(1, 1, 1, density);
            }
            ENDHLSL
        }
    }
}