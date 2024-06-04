using Unity.Mathematics;
using UnityEngine;

namespace Scenes.Simulating_Fluids.Scripts
{
    public class ParticleSpawner : MonoBehaviour
    {
        public Vector2 initialVelocity;
        public Vector2 spawnCenter;
        public Vector2 spawnSize;
        public float jitterStr;
        public bool showSpawnBoundsGizmos;

        public ParticleSpawnData GenerateData(int vParticleCount)
        {
            var data = new ParticleSpawnData(vParticleCount);
            var random = new Unity.Mathematics.Random(42);

            var numX = Mathf.CeilToInt(
                Mathf.Sqrt(spawnSize.x / spawnSize.y * vParticleCount + (spawnSize.x - spawnSize.y) *
                    (spawnSize.x - spawnSize.y) / (4 * spawnSize.y * spawnSize.y)) -
                (spawnSize.x - spawnSize.y) / (2 * spawnSize.y));
            var numY = Mathf.CeilToInt(vParticleCount / (float)numX);
            var i = 0;

            for (var y = 0; y < numY; y++)
            {
                for (var x = 0; x < numX; x++)
                {
                    if (i >= vParticleCount) break;

                    var tx = numX <= 1 ? 0.5f : x / (numX - 1f);
                    var ty = numY <= 1 ? 0.5f : y / (numY - 1f);

                    var angle = (float)random.NextDouble() * 3.14f * 2;
                    var dir = new Vector2(Mathf.Cos(angle), Mathf.Sin(angle));
                    var jitter = dir * jitterStr * ((float)random.NextDouble() - 0.5f);
                    data.Positions[i] = new Vector2((tx - 0.5f) * spawnSize.x, (ty - 0.5f) * spawnSize.y) + jitter +
                                        spawnCenter;
                    data.Velocities[i] = initialVelocity;
                    i++;
                }
            }

            return data;
        }

        private void OnDrawGizmos()
        {
            if (!showSpawnBoundsGizmos || Application.isPlaying) return;
            Gizmos.color = new Color(1, 1, 0, 0.5f);
            Gizmos.DrawWireCube(spawnCenter, Vector2.one * spawnSize);
        }

        public struct ParticleSpawnData
        {
            public readonly float2[] Positions;
            public readonly float2[] Velocities;

            public ParticleSpawnData(int vNum)
            {
                Positions = new float2[vNum];
                Velocities = new float2[vNum];
            }
        }
    }
}