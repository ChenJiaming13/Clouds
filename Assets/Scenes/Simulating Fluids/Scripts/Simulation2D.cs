using Unity.Mathematics;
using UnityEngine;

namespace Scenes.Simulating_Fluids.Scripts
{
    public class Simulation2D : MonoBehaviour
    {
        public ComputeBuffer positionBuffer { get; private set; }
        public ComputeBuffer velocityBuffer { get; private set; }

        public ParticleSpawner particleSpawner;
        public ParticleDisplay2D particleDisplay2D;
        
        private void Start()
        {
            var spawnData = particleSpawner.GenerateData();
            var numParticles = spawnData.Positions.Length;
            positionBuffer = CreateStructuredBuffer<float2>(numParticles);
            velocityBuffer = CreateStructuredBuffer<float2>(numParticles);
            positionBuffer.SetData(spawnData.Positions);
            velocityBuffer.SetData(spawnData.Velocities);
            
            particleDisplay2D.Init(this);
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
        }
    }
}