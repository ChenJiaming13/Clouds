Shader "Simulating Fluids/Particle2D"
{
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
            #pragma target 4.5 // https://docs.unity.cn/cn/2021.3/ScriptReference/ComputeBuffer.html

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            
            struct Attributes
            {
                float3 positionOS: POSITION;
                float2 uv: TEXCOORD0;
                uint instanceID: SV_InstanceID;
            };

            struct Varyings
            {
                float4 positionHCS: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 color: TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)
                float _Scale;
                float _MaxSpeed;
            CBUFFER_END

            StructuredBuffer<float2> _Positions;
			StructuredBuffer<float2> _Velocities;

            Texture2D _ColorMap;
			SamplerState linear_clamp_sampler;
            
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float speed = length(_Velocities[IN.instanceID]);
                float normalizedSpeed = saturate(speed / _MaxSpeed);
                float3 centerWS = float3(_Positions[IN.instanceID], 0.0);
                centerWS += TransformObjectToWorld(IN.positionOS * _Scale);
                OUT.positionHCS = TransformWorldToHClip(centerWS);
                OUT.uv = IN.uv;
                OUT.color = _ColorMap.SampleLevel(linear_clamp_sampler, float2(normalizedSpeed, 0.5), 0);
                return OUT;
            }

            float4 frag(Varyings IN) : SV_Target
            {
                float2 centerOffset = (IN.uv.xy - 0.5) * 2; // [-1,1]^2
				float sqrDst = dot(centerOffset, centerOffset); // squared distance to origin
                // 玄妙：画一个圆
                float delta = fwidth(sqrt(sqrDst));
				float alpha = 1 - smoothstep(1 - delta, 1 + delta, sqrDst);

				float3 color = IN.color;
				return float4(color, alpha);
            }
            
            ENDHLSL
        }
    }
}
