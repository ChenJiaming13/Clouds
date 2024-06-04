using UnityEngine;

namespace Scenes.Simulating_Fluids.Scripts
{
    public class DisplayDensity2D : MonoBehaviour
    {
        public GameObject displayQuad;
        public Shader shader;
        public Color negativeColor;
        public Color positiveColor;
        public Color zeroColor;
        
        private Material m_Material;
        private Settings2D m_Settings;
        
        private static readonly int PositionsID = Shader.PropertyToID("u_positions");
        private static readonly int NumParticlesID = Shader.PropertyToID("u_num_particles");
        private static readonly int SmoothingRadiusID = Shader.PropertyToID("u_smoothing_radius");
        private static readonly int MaxDensityID = Shader.PropertyToID("u_max_density");
        private static readonly int TargetDensityID = Shader.PropertyToID("u_target_density");
        private static readonly int PositiveColorID = Shader.PropertyToID("u_positive_color");
        private static readonly int NegativeColorID = Shader.PropertyToID("u_negative_color");
        private static readonly int ZeroColorID = Shader.PropertyToID("u_zero_color");

        public void Init(Simulation2D vSim)
        {
            m_Settings = vSim.settings;
            m_Material = new Material(shader);
            m_Material.SetBuffer(PositionsID, vSim.positionBuffer);
            m_Material.SetInt(NumParticlesID, m_Settings.numParticles);
            
            displayQuad.transform.localScale =
                new Vector3(m_Settings.boundsSize.x, m_Settings.boundsSize.y, 1.0f);
            displayQuad.GetComponent<MeshRenderer>().material = m_Material;
        }

        private void Update()
        {
            m_Material.SetFloat(SmoothingRadiusID, m_Settings.smoothingRadius);
            m_Material.SetFloat(MaxDensityID, m_Settings.maxDensity);
            m_Material.SetFloat(TargetDensityID, m_Settings.targetDensity);
            m_Material.SetVector(PositiveColorID, positiveColor);
            m_Material.SetVector(NegativeColorID, negativeColor);
            m_Material.SetVector(ZeroColorID, zeroColor);
        }
    }
}