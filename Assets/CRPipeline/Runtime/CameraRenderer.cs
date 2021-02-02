using UnityEngine;
using UnityEngine.Rendering;

namespace CRP
{
    public class CameraRenderer
    {
        private ScriptableRenderContext _context;
        private Camera _camera;

        public void Render(ScriptableRenderContext context, Camera camera)
        {
            _context = context;
            _camera = camera;

            SetupCameraProperties();
            DrawVisibleGeometry();
            Submit();
        }

        private void SetupCameraProperties()
        {
            _context.SetupCameraProperties(_camera);
        }

        private void DrawVisibleGeometry()
        {
            _context.DrawSkybox(_camera);
        }

        private void Submit()
        {
            _context.Submit();
        }
    }
}