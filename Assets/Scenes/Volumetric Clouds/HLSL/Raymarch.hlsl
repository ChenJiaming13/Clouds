void ray_march_v1_float(float3 ray_origin, const float3 ray_direction, const float num_steps, const float step_size,
                        const float density_scale,
                        float4 sphere, out float result)
{
    float density = 0.0f;
    for (int i = 0; i < num_steps; ++i)
    {
        ray_origin += ray_direction * step_size;
        const float sphere_dist = distance(ray_origin, sphere.xyz);
        if (sphere_dist < sphere.w)
        {
            density += 0.1f;
        }
    }
    result = density * density_scale;
}

void ray_march_v2_float(float3 ray_origin, const float3 ray_direction, const float num_steps, const float step_size,
                        const float density_scale,
                        Texture3D volume_tex, const SamplerState volume_sampler, const float3 offset, out float result)
{
    float density = 0.0;
    for (int i = 0; i < num_steps; ++i)
    {
        ray_origin += ray_direction * step_size;
        const float sampled_density = volume_tex.Sample(volume_sampler, ray_origin + offset).r;
        density += sampled_density;
    }
    result = density * density_scale;
}

void ray_march_v3_float(float3 ray_origin, float3 ray_direction, float num_steps, float step_size, float density_scale,
                        Texture3D volume_tex, SamplerState volume_sampler, float3 offset, float light_num_steps,
                        float light_step_size, float3 light_direction, float light_absorb, float darkness_threshold,
                        float transmittance, out float3 result)
{
    float density = 0.0;
    float light_accumulation = 0.0;
    float final_light = 0.0;
    for (int i = 0; i < num_steps; ++i)
    {
        ray_origin += ray_direction * step_size;
        float3 sample_pos = ray_origin + offset;
        float sampled_density = volume_tex.Sample(volume_sampler, sample_pos).r;
        density += sampled_density * density_scale;
        float3 light_ray_origin = sample_pos;
        
        for (int j = 0; j < light_num_steps; ++j)
        {
            light_ray_origin += -light_direction * light_step_size;
            float light_density = volume_tex.Sample(volume_sampler, light_ray_origin).r;
            light_accumulation += light_density;
        }

        float light_transmission = exp(-light_accumulation);
        float shadow = darkness_threshold + light_transmission * (1.0 - darkness_threshold);
        final_light += density * transmittance * shadow;
        transmittance *= exp(-density*light_absorb);
    }
    float transmission = exp(-density);
    result = float3(final_light, transmission, transmittance);
}
