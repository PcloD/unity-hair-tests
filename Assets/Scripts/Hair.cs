using UnityEngine;

[ExecuteInEditMode]
public class Hair : MonoBehaviour {
    private static int MAXIMUM_INSTANCE_COUNT = 1023;
    public Mesh mesh;
    public Material material;
    public float hairLength = 0.04f;
    public float hairWidth = 0.02f;
    private int instanceCount;
    private Matrix4x4[] buffer;


    // Use this for initialization
    void Start () {
        MeshFilter meshRenderer = GetComponent<MeshFilter>();
        Mesh surfaceMesh = meshRenderer.sharedMesh;

        Vector3[] surfaceVertices = surfaceMesh.vertices;
        //Vector3[] surfaceVerticesNormals = surfaceMesh.normals;
        instanceCount = surfaceMesh.vertexCount < MAXIMUM_INSTANCE_COUNT ? surfaceMesh.vertexCount : MAXIMUM_INSTANCE_COUNT;

        buffer = new Matrix4x4[instanceCount]; 

        for (int index = 0; index <instanceCount; index++) {
            Vector3 pos = surfaceVertices[index];
            Quaternion rotation = Quaternion.identity;
            Vector3 scale = new Vector3(hairWidth, hairLength, hairWidth);

            Matrix4x4 objectMatrix = gameObject.transform.localToWorldMatrix;
            objectMatrix *= Matrix4x4.Translate(gameObject.transform.localPosition);

            Matrix4x4 theMatrix = Matrix4x4.TRS(pos, rotation, scale);
            objectMatrix *= theMatrix;
            buffer[index] = objectMatrix;
        }
	}
	
	// Update is called once per frame
	void Update () {
        Graphics.DrawMeshInstanced(mesh, 0, material, buffer, instanceCount);
	}
}
