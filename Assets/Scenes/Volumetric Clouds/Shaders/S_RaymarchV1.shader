Shader "Volumetric Clouds/RaymarchV1"
{
    Properties
    {
        _NumSteps("Num Steps", Float) = 64
        _StepSize("Step Size", Float) = 0.02
        _DensityScale("Density Scale", Range(0.0, 1.0)) = 0.5
        _Sphere("Sphere", Vector) = (0, 0, 0, 0.34)
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
                float3 positionOS : POSITION;
            };

            struct varyings
            {
                float4 positionHCS: SV_POSITION;
                float3 positionOS: TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float _NumSteps;
                float _StepSize;
                float _DensityScale;
                float4 _Sphere;
            CBUFFER_END

            varyings vert(attributes IN)
            {
                varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
                OUT.positionOS = IN.positionOS;
                return OUT;
            }

            float4 frag(varyings IN) : SV_Target
            {
                const float3 rayOrigin = TransformWorldToObject(GetCameraPositionWS());
                float3 rayDirection = normalize(IN.positionOS - rayOrigin);
                float density;
                ray_march_v1_float(IN.positionOS, rayDirection, _NumSteps, _StepSize, _DensityScale, _Sphere,
                 density);
                return float4(1, 1, 1, density);
            }
            ENDHLSL
        }
    }
}