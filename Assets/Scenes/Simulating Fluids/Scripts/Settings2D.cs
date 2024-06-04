using System;
using UnityEngine;

namespace Scenes.Simulating_Fluids.Scripts
{
    [Serializable]
    public class Settings2D
    {
        // core settings
        public float timeScale;
        public int numParticles;
        public float gravity;
        public float collisionDamping;
        public Vector2 boundsSize;
        public float smoothingRadius;
        public float targetDensity;
        public float pressureMultiplier;
        
        // other settings
        public float maxSpeed;
        public float maxDensity;
    }
}