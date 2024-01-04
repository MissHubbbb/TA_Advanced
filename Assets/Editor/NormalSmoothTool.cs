using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEngine;

public enum WRITETYPE
{
    VertexColor = 0,
    Tangent = 1,
}

public class NormalSmoothTool : EditorWindow
{
    public WRITETYPE wt;

    [MenuItem("Tools/ƽ�����߹���1")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(NormalSmoothTool));
    }

    private void OnGUI()
    {
        GUILayout.Space(5);
        GUILayout.Label("1������Scene��ѡ����Ҫƽ�����ߵ�����", EditorStyles.boldLabel);
        
        GUILayout.Space(10);
        GUILayout.Label("2����ѡ����Ҫд��ƽ���������ռ䷨�����ݵ�Ŀ��", EditorStyles.boldLabel);
        wt = (WRITETYPE)EditorGUILayout.EnumPopup("д��Ŀ��", wt);

        GUILayout.Space(10);
        switch(wt)
        {
            case WRITETYPE.Tangent:     //ִ��д�뵽��������
                GUILayout.Label("    �����ƽ����ķ���д�뵽����������", EditorStyles.boldLabel);
                break;
            case WRITETYPE.VertexColor: //ִ��д�뵽������ɫ
                GUILayout.Label("    �����ƽ����ķ���д�뵽������ɫ��RGB�У�A���ֲ���", EditorStyles.boldLabel);
                break;
        }

        //ִ��ƽ��
        if(GUILayout.Button("3. ƽ������(Ԥ��Ч��) "))
        {
            SmoothNormalPrev(wt);
        }

        GUILayout.Label("֮����ܻᱨNull Reference����");
        GUILayout.Label("��Ҫ����Mesh����MeshFilter�и��ǣ������������ñ���");
        GUILayout.Space(10);
        GUILayout.Label("  �Ὣmesh���浽Assets/NormalSmoothTools/��", EditorStyles.boldLabel);
        GUILayout.Space(5);
        // customMesh = EditorGUILayout.BeginToggleGroup ("Optional Settings", customMesh);
        // EditorGUILayout.EndToggleGroup ();
        if (GUILayout.Button("4������Mesh"))
        {
            SelectMesh();
        }
    }

    //Meshѡ���� �޸Ĳ�Ԥ��
    //���⽫���㷨��ƽ����д�������У�ԭ�������߲���Ҫ�������⴦��
    //���������Ҫʹ��ԭʼ���ߵ�������ͽ�ƽ������ת�������߿ռ���ڱ����ڶ�����ɫ����UV��    
    public void SmoothNormalPrev(WRITETYPE wt)
   {
        if(Selection.activeGameObject == null){
            Debug.Log("��ѡ������");
            return;
        }

        //��������Mesh ����ƽ�����߷���
        //MeshFilter����ʹ����һ��Mesh��sharedMesh�������ô��ݣ�mesh����ֵ����
        MeshFilter[] meshFilters = Selection.activeGameObject.GetComponentsInChildren<MeshFilter>();
        foreach(var meshFilter in meshFilters)
        {
            Mesh mesh = meshFilter.sharedMesh;
            Vector3[] averageNormals = AverageNormal(mesh);
            WriteToMesh(mesh, averageNormals);
        }

        //SkinnedMeshRenderer��Ƥ���������
        //SkinnedMesh �����ľ���������Ƥ����ν��Ƥ������ģ�͵���ͼ������ Mesh ������Ƥ��ָ�� Mesh �еĶ��㸽�ţ��󶨣��ڹ���֮�ϡ�
        SkinnedMeshRenderer[] skinnedMeshRenders = Selection.activeGameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach(var skinMeshRender in skinnedMeshRenders)
        {
            Mesh mesh = skinMeshRender.sharedMesh;
            Vector3[] averageNormals = AverageNormal(mesh);
            WriteToMesh(mesh, averageNormals);
        }
   }

   //������д��mesh���ݽṹ�е�������
   private Vector3[] AverageNormal(Mesh mesh)
   {
        //��ÿ�����㼰�䷨��д�뵽�ֵ���
        Dictionary<Vector3, Vector3> averageNormalHash = new Dictionary<Vector3, Vector3>();
        for(int j = 0; j < mesh.vertexCount; j++)
        {
            if(!averageNormalHash.ContainsKey(mesh.vertices[j])){
                averageNormalHash.Add(mesh.vertices[j], mesh.normals[j]);
            }
            else
            {
                averageNormalHash[mesh.vertices[j]] = (averageNormalHash[mesh.vertices[j]] + mesh.normals[j]).normalized;
            }
        }

        //���ֵ��ж�ȡÿ������ķ���
        Vector3[] averageNormals = new Vector3[mesh.vertexCount];
        for(int j = 0; j < mesh.vertexCount; j++)
        {
            averageNormals[j] = averageNormalHash[mesh.vertices[j]];
        }
        
        return averageNormals;
   }

    #region CreateTangentMesh obsolute
    // //�ڵ�ǰ·����������ģ��(MeshFilter����)
    // private static void CreateTangentMesh(Mesh rMesh, MeshFilter rMeshFilter)
    // {
    //     string[] path = AssetDatabase.GetAssetPath(rMeshFilter).Split("/");
    //     string createPath = "";
    //     for(int i = 0; i < path.Length - 1; i++)
    //     {
    //         createPath += path[i] + "/";
    //     }
    //     string newMeshPath = createPath + rMeshFilter.name + "_Tangent.mesh";
    //     Debug.Log("�洢ģ��λ�ã�" + newMeshPath);
    //     AssetDatabase.CreateAsset(rMesh, newMeshPath);
    // }

    // //�ڵ�ǰ·����������ģ��(SkinnedMeshRenderer����)
    // private static void CreateTangentMesh(Mesh rMesh, SkinnedMeshRenderer rSkinMeshRenders)
    // {
    //     string[] path = AssetDatabase.GetAssetPath(rSkinMeshRenders).Split("/");
    //     string createPath = "";
    //     for(int i = 0; i < path.Length - 1; i++)
    //     {
    //         createPath += path[i] + "/";
    //     }
    //     string newMeshPath = createPath + rSkinMeshRenders.name + "_Tangent.mesh";
    //     Debug.Log("�洢ģ��λ�ã�" + newMeshPath);
    //     AssetDatabase.CreateAsset(rMesh, newMeshPath);
    //}   
    #endregion

    public void WriteToMesh(Mesh mesh, Vector3[] averageNormals)
    {
        switch(wt)
        {
            case WRITETYPE.Tangent: //ִ��д�뵽 ��������
                Vector4[] tangents = new Vector4[mesh.vertexCount];
                for (var j = 0; j < mesh.vertexCount; j++)
                {
                    tangents[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, 0);
                }
                mesh.tangents = tangents;
                break;

            case WRITETYPE.VertexColor: // д�뵽����ɫ
                Color[] _colors = new Color[mesh.vertexCount];
                Color[] _colors2 = new Color[mesh.vertexCount];
                _colors2 = mesh.colors;
                for(int j = 0; j < mesh.vertexCount; j++)
                {
                    _colors[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, _colors2[j].a);
                }
                mesh.colors = _colors;
                break;
        }
    }

    public void SelectMesh()
    {
        if(Selection.activeGameObject == null)
        {
            Debug.Log("��ѡ������");
            return;
        }

        MeshFilter[] meshFilters = Selection.activeGameObject.GetComponentsInChildren<MeshFilter>();
        SkinnedMeshRenderer[] skinnedMeshRenderers = Selection.activeGameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (var meshFilter in meshFilters)
        {
            Mesh mesh = meshFilter.sharedMesh;
            Vector3[] averageNormals = AverageNormal(mesh);
            ExportMesh(mesh, averageNormals);
        }

        foreach (var skinnedMeshRenderer in skinnedMeshRenderers)
        {
            Mesh mesh = skinnedMeshRenderer.sharedMesh;
            Vector3[] averageNormals = AverageNormal(mesh);
            ExportMesh(mesh, averageNormals);
        }
    }

    public void ExportMesh(Mesh mesh, Vector3[] averageNormals)
    {
        Mesh mesh2 = new Mesh();
        Copy(mesh2, mesh);
        switch(wt)
        {
            case WRITETYPE.Tangent:
                Debug.Log("����������д�뵽����λ����");
                Vector4[] tangents = new Vector4[mesh2.vertexCount];
                for(int j = 0; j< mesh2.vertexCount; j++)
                {
                    tangents[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, 0);
                }
                mesh2.tangents = tangents;
                break;

            case WRITETYPE.VertexColor:
                Debug.Log("����������д�뵽����ɫλ����");
                Color[] _colors = new Color[mesh2.vertexCount];
                Color[] _colors2 = new Color[mesh2.vertexCount];
                _colors2 = mesh2.colors;
                for (int j = 0; j < mesh2.vertexCount; j++)
                {
                    _colors[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, _colors2[j].a);
                }
                mesh2.colors = _colors;
                break;
        }

        //�����ļ���·��
        string DeletePath = Application.dataPath + "/NormalSmoothTools";
        Debug.Log(DeletePath);

        //�ж��ļ���·���Ƿ����
        if(!Directory.Exists(DeletePath))
        {
            //�����ھʹ���
            Directory.CreateDirectory(DeletePath);
        }
        //ˢ��Ŀ¼
        AssetDatabase.Refresh();

        mesh2.name = mesh2.name + "_NormalSM";
        Debug.Log(mesh2.vertexCount);
        AssetDatabase.CreateAsset(mesh2, "Assets/NormalSmoothTools/" + mesh2.name + ".asset");
    }

    public void Copy(Mesh dest, Mesh src)
    {
        dest.Clear();
        dest.vertices = src.vertices;

        List<Vector4> uvs = new List<Vector4>();

        src.GetUVs(0, uvs); dest.SetUVs(0, uvs);
        src.GetUVs(1, uvs); dest.SetUVs(1, uvs);
        src.GetUVs(2, uvs); dest.SetUVs(2, uvs);
        src.GetUVs(3, uvs); dest.SetUVs(3, uvs);

        dest.normals = src.normals;
        dest.tangents = src.tangents;
        dest.boneWeights = src.boneWeights;
        dest.colors = src.colors;
        dest.colors32 = src.colors32;
        dest.bindposes = src.bindposes;

        dest.subMeshCount = src.subMeshCount;

        for(int i = 0; i < src.subMeshCount; i++)
        {
            dest.SetIndices(src.GetIndices(i), src.GetTopology(i), i);
        }

        dest.name = src.name;
    }
}
