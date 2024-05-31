using UnityEngine;

namespace Scenes.Simulating_Fluids.Scripts
{
    public class ParticleDisplay2D : MonoBehaviour
    {
        public Mesh mesh;
        public Shader shader;
        public float particleScale;
        public float maxSpeed;
        public Gradient colorGradient;
        public int gradientResolution;
        
        private Texture2D m_ColorMap;
        private Material m_Material;
        private Bounds m_Bounds;
        private ComputeBuffer m_ArgsBuffer;
        private bool m_NeedsUpdate;
        
        private static readonly int PositionsID = Shader.PropertyToID("_Positions");
        private static readonly int VelocitiesID = Shader.PropertyToID("_Velocities");
        private static readonly int ScaleID = Shader.PropertyToID("_Scale");
        private static readonly int SpeedID = Shader.PropertyToID("_MaxSpeed");
        private static readonly int ColorMapID = Shader.PropertyToID("_ColorMap");

        public void Init(Simulation2D vSimulation2D)
        {
            m_Material = new Material(shader);
            m_Material.SetBuffer(PositionsID, vSimulation2D.positionBuffer);
            m_Material.SetBuffer(VelocitiesID, vSimulation2D.velocityBuffer);
            m_ArgsBuffer = CreateArgsBuffer(mesh, vSimulation2D.positionBuffer.count);
            m_Bounds = new Bounds(Vector3.zero, Vector3.one * 10000);
        }

        private void LateUpdate()
        {
            if (m_NeedsUpdate)
            {
                m_NeedsUpdate = false;
                TransformGradientToTexture2D(ref m_ColorMap, gradientResolution, colorGradient);
                m_Material.SetTexture(ColorMapID, m_ColorMap);
                m_Material.SetFloat(ScaleID, particleScale);
                m_Material.SetFloat(SpeedID, maxSpeed);
            }
            Graphics.DrawMeshInstancedIndirect(mesh, 0, m_Material, m_Bounds, m_ArgsBuffer);
        }

        private void OnValidate()
        {
            m_NeedsUpdate = true;
        }

        private void OnDestroy()
        {
            m_ArgsBuffer.Release();
        }

        private static ComputeBuffer CreateArgsBuffer(Mesh vMesh, int vNumInstances)
        {
            const int subMeshIndex = 0;
            var args = new uint[5];
            args[0] = vMesh.GetIndexCount(subMeshIndex);
            args[1] = (uint)vNumInstances;
            args[2] = vMesh.GetIndexStart(subMeshIndex);
            args[3] = vMesh.GetBaseVertex(subMeshIndex);
            args[4] = 0; // offset

            var argsBuffer = new ComputeBuffer(1, 5 * sizeof(uint), ComputeBufferType.IndirectArguments);
            argsBuffer.SetData(args);
            return argsBuffer;
        }
        
        private static void TransformGradientToTexture2D(ref Texture2D vTexture, int vWidth, Gradient vGradient, FilterMode vFilterMode = FilterMode.Bilinear)
        {
            if (vTexture == null)
            {
                vTexture = new Texture2D(vWidth, 1);
            }
            else if (vTexture.width != vWidth)
            {
                vTexture.Reinitialize(vWidth, 1);
            }
            if (vGradient == null)
            {
                vGradient = new Gradient();
                vGradient.SetKeys(
                    new[] { new GradientColorKey(Color.black, 0), new GradientColorKey(Color.black, 1) },
                    new[] { new GradientAlphaKey(1, 0), new GradientAlphaKey(1, 1) }
                );
            }
            vTexture.wrapMode = TextureWrapMode.Clamp;
            vTexture.filterMode = vFilterMode;

            var cols = new Color[vWidth];
            for (var i = 0; i < cols.Length; i++)
            {
                var t = i / (cols.Length - 1f);
                cols[i] = vGradient.Evaluate(t);
            }
            vTexture.SetPixels(cols);
            vTexture.Apply();
        }
    }
}