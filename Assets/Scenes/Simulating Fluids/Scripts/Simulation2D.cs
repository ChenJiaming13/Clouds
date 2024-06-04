using Unity.Mathematics;
using UnityEngine;

namespace Scenes.Simulating_Fluids.Scripts
{
    public class Simulation2D : MonoBehaviour
    {
        public bool enableSimulation;
        public Settings2D settings;
        public ComputeBuffer positionBuffer { get; private set; }
        public ComputeBuffer velocityBuffer { get; private set; }
        public ComputeBuffer densityBuffer { get; private set; }
        public ParticleSpawner particleSpawner;
        public DisplayParticle2D displayParticle2D;
        public DisplayDensity2D displayDensity2D;
        public ComputeShader computeShader;
        
        private static int _kernelIdxCalcDensity;
        private static int _kernelIdxApplyForce;
        private static int _kernelIdxUpdatePosition;
        private static readonly int PositionsID = Shader.PropertyToID("u_positions");
        private static readonly int VelocitiesID = Shader.PropertyToID("u_velocities");
        private static readonly int DensitiesID = Shader.PropertyToID("u_densities");
        private static readonly int NumParticlesID = Shader.PropertyToID("u_num_particles");
        private static readonly int GravityID = Shader.PropertyToID("u_gravity");
        private static readonly int DeltaTimeID = Shader.PropertyToID("u_delta_time");
        private static readonly int BoundsSizeID = Shader.PropertyToID("u_bounds_size");
        private static readonly int CollisionDampingID = Shader.PropertyToID("u_collision_damping");
        private static readonly int SmoothingRadiusID = Shader.PropertyToID("u_smoothing_radius");
        private static readonly int TargetDensityID = Shader.PropertyToID("u_target_density");
        private static readonly int PressureMultiplierID = Shader.PropertyToID("u_pressure_multiplier");

        private void Start()
        {
            // init compute buffer
            var spawnData = particleSpawner.GenerateData(settings.numParticles);
            positionBuffer = CreateStructuredBuffer<float2>(settings.numParticles);
            velocityBuffer = CreateStructuredBuffer<float2>(settings.numParticles);
            densityBuffer = CreateStructuredBuffer<float>(settings.numParticles);
            positionBuffer.SetData(spawnData.Positions);
            velocityBuffer.SetData(spawnData.Velocities);

            // bind compute buffer to kernel
            _kernelIdxCalcDensity = computeShader.FindKernel("kernel_calc_density");
            _kernelIdxApplyForce = computeShader.FindKernel("kernel_apply_force");
            _kernelIdxUpdatePosition = computeShader.FindKernel("kernel_update_position");
            // Debug.Log(_kernelIdxCalcDensity + "," + _kernelIdxApplyForce + "," + _kernelIdxUpdatePosition);
            
            SetBuffer(PositionsID, positionBuffer, 
                _kernelIdxCalcDensity, _kernelIdxApplyForce, _kernelIdxUpdatePosition);
            SetBuffer(VelocitiesID, velocityBuffer,
                _kernelIdxCalcDensity, _kernelIdxApplyForce, _kernelIdxUpdatePosition);
            SetBuffer(DensitiesID, densityBuffer,
                _kernelIdxCalcDensity, _kernelIdxApplyForce, _kernelIdxUpdatePosition);
            
            // set uniform
            computeShader.SetInt(NumParticlesID, settings.numParticles);
            
            // Debug.Log(computeShader.IsSupported(_kernelIdxCalcDensity));
            // Debug.Log(computeShader.IsSupported(_kernelIdxApplyForce));
            // Debug.Log(computeShader.IsSupported(_kernelIdxUpdatePosition));
            
            displayParticle2D.Init(this);
            displayDensity2D.Init(this);
        }

        private void Update()
        {
            if (Input.GetMouseButtonDown(0)) enableSimulation = !enableSimulation;
            if (enableSimulation) UpdateSim();
        }

        private void UpdateSim()
        {
            // set uniform
            computeShader.SetFloat(GravityID, settings.gravity);
            computeShader.SetFloat(DeltaTimeID, Time.deltaTime * settings.timeScale);
            computeShader.SetVector(BoundsSizeID, settings.boundsSize);
            computeShader.SetFloat(CollisionDampingID, settings.collisionDamping);
            computeShader.SetFloat(SmoothingRadiusID, settings.smoothingRadius);
            computeShader.SetFloat(TargetDensityID, settings.targetDensity);
            computeShader.SetFloat(PressureMultiplierID, settings.pressureMultiplier);
            Dispatch(_kernelIdxCalcDensity);
            Dispatch(_kernelIdxApplyForce);
            Dispatch(_kernelIdxUpdatePosition);
        }

        private void SetBuffer(int vNameID, ComputeBuffer vBuffer, params int[] vKernelIndices)
        {
            foreach (var kernelIndex in vKernelIndices)
            {
                computeShader.SetBuffer(kernelIndex, vNameID, vBuffer);
            }
        }

        private void Dispatch(int vKernelIdx)
        {
            computeShader.GetKernelThreadGroupSizes(vKernelIdx, out var x, out _, out _);
            var numGroupsX = Mathf.CeilToInt(settings.numParticles / (float)x);
            // var numGroupsY = Mathf.CeilToInt(m_NumParticles / (float)y);
            const int numGroupsY = 1;
            // var numGroupsZ = Mathf.CeilToInt(m_NumParticles / (float)z);
            const int numGroupsZ = 1;
            // group数量开太大会导致unity直接崩溃
            computeShader.Dispatch(vKernelIdx, numGroupsX, numGroupsY, numGroupsZ);
        }

        private static ComputeBuffer CreateStructuredBuffer<T>(int vCount)
        {
            var stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(T));
            return new ComputeBuffer(vCount, stride);
        }

        private void OnDestroy()
        {
            positionBuffer.Release();
            velocityBuffer.Release();
            densityBuffer.Release();
        }

        private void OnDrawGizmos()
        {
            Gizmos.color = new Color(0, 1, 0, 0.4f);
            Gizmos.DrawWireCube(Vector2.zero, settings.boundsSize);
        }
    }
}