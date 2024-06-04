Shader "Simulating Fluids/Density2D"
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
            #pragma target 4.5

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // ----------------------------------------------------------------------------
            // 写成RWStructuredBuffer读不到数据？？？！！！
            StructuredBuffer<float2> u_positions;
            const uint u_num_particles;
            float u_smoothing_radius;
            float u_max_density;
            float u_target_density;
            float4 u_negative_color;
            float4 u_positive_color;
            float4 u_zero_color;
            // ----------------------------------------------------------------------------

            float calc_influence(const float v_radius, const float v_distance)
            {
                if (v_distance < v_radius)
                {
                    const float factor = 1.0;
                    const float value = v_radius - v_distance;
                    return value * value * value * factor;
                }
                return 0;
            }
            
            float calc_density(const float2 v_sample_point)
            {
                float density = 0.0;

                for (uint i = 0; i < u_num_particles; ++i)
                {
                    const float mass = 1.0;
                    const float dst = length(u_positions[i] - v_sample_point);
                    const float influence = calc_influence(u_smoothing_radius, dst);
                    density += mass * influence;
                }

                return density;
            }

            struct attributes
            {
                float3 position_os: POSITION;
            };

            struct varyings
            {
                float4 position_hcs: SV_POSITION;
                float3 position_ws: TEXCOORD0;
            };

            varyings vert(const attributes IN)
            {
                varyings OUT;
                OUT.position_ws = TransformObjectToWorld(IN.position_os);
                OUT.position_hcs = TransformObjectToHClip(IN.position_os);
                return OUT;
            }

            float4 frag(const varyings IN): SV_Target
            {
                const float density = calc_density(IN.position_ws.xy);
                const float factor = (density - u_target_density) / u_max_density;
                if (factor > 0.0) return lerp(u_zero_color, u_positive_color, factor);
                if (factor < 0.0) return lerp(u_zero_color, u_negative_color, -factor);
                return u_zero_color;
            }
            ENDHLSL
        }
    }
}