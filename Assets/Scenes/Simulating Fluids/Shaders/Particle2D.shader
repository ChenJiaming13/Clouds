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

            // ----------------------------------------------------------------------------
            // todo: not compatible cbuffer unity per material
            float u_scale;
            float u_max_speed;

            StructuredBuffer<float2> u_positions;
			StructuredBuffer<float2> u_velocities;

            Texture2D u_color_map;
			SamplerState linear_clamp_sampler;
            // ----------------------------------------------------------------------------
            
            struct attributes
            {
                float3 position_os: POSITION;
                float2 uv: TEXCOORD0;
                uint instance_id: SV_InstanceID;
            };

            struct varyings
            {
                float4 position_hcs: SV_POSITION;
                float2 uv: TEXCOORD0;
                float3 color: TEXCOORD1;
            };
            
            varyings vert(const attributes IN)
            {
                varyings OUT;
                const float speed = length(u_velocities[IN.instance_id]);
                float normalized_speed = saturate(speed / u_max_speed);
                float3 center_ws = float3(u_positions[IN.instance_id], 0.0);
                center_ws += TransformObjectToWorld(IN.position_os * u_scale);
                OUT.position_hcs = TransformWorldToHClip(center_ws);
                OUT.uv = IN.uv;
                OUT.color = u_color_map.SampleLevel(linear_clamp_sampler, float2(normalized_speed, 0.5), 0).xyz;
                return OUT;
            }

            float4 frag(varyings IN) : SV_Target
            {
                const float2 center_offset = (IN.uv.xy - 0.5) * 2; // [-1,1]^2
                const float sqr_dst = dot(center_offset, center_offset); // squared distance to origin
                // 玄妙：画一个圆
                const float delta = fwidth(sqrt(sqr_dst));
				float alpha = 1 - smoothstep(1 - delta, 1 + delta, sqr_dst);

				float3 color = IN.color;
				return float4(color, alpha);
            }
            
            ENDHLSL
        }
    }
}
