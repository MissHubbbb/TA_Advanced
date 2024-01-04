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

    [MenuItem("Tools/平滑法线工具1")]
    public static void ShowWindow()
    {
        EditorWindow.GetWindow(typeof(NormalSmoothTool));
    }

    private void OnGUI()
    {
        GUILayout.Space(5);
        GUILayout.Label("1、请在Scene中选择需要平滑法线的物体", EditorStyles.boldLabel);
        
        GUILayout.Space(10);
        GUILayout.Label("2、请选择需要写入平滑后的物体空间法线数据的目标", EditorStyles.boldLabel);
        wt = (WRITETYPE)EditorGUILayout.EnumPopup("写入目标", wt);

        GUILayout.Space(10);
        switch(wt)
        {
            case WRITETYPE.Tangent:     //执行写入到顶点切线
                GUILayout.Label("    将会把平滑后的法线写入到顶点切线中", EditorStyles.boldLabel);
                break;
            case WRITETYPE.VertexColor: //执行写入到顶点颜色
                GUILayout.Label("    将会把平滑后的法线写入到顶点颜色的RGB中，A保持不变", EditorStyles.boldLabel);
                break;
        }

        //执行平滑
        if(GUILayout.Button("3. 平滑法线(预览效果) "))
        {
            SmoothNormalPrev(wt);
        }

        GUILayout.Label("之后可能会报Null Reference错误，");
        GUILayout.Label("需要导出Mesh并在MeshFilter中覆盖，这样才能永久保存");
        GUILayout.Space(10);
        GUILayout.Label("  会将mesh保存到Assets/NormalSmoothTools/下", EditorStyles.boldLabel);
        GUILayout.Space(5);
        // customMesh = EditorGUILayout.BeginToggleGroup ("Optional Settings", customMesh);
        // EditorGUILayout.EndToggleGroup ();
        if (GUILayout.Button("4、导出Mesh"))
        {
            SelectMesh();
        }
    }

    //Mesh选择器 修改并预览
    //在这将顶点法线平滑后写入切线中，原因是切线不需要经过特殊处理。
    //如果遇到需要使用原始切线的情况，就将平均发现转换到切线空间后，在保存在顶点颜色或者UV上    
    public void SmoothNormalPrev(WRITETYPE wt)
   {
        if(Selection.activeGameObject == null){
            Debug.Log("请选择物体");
            return;
        }

        //遍历两种Mesh 调用平滑法线方法
        //MeshFilter决定使用哪一个Mesh。sharedMesh就像引用传递，mesh就像值传递
        MeshFilter[] meshFilters = Selection.activeGameObject.GetComponentsInChildren<MeshFilter>();
        foreach(var meshFilter in meshFilters)
        {
            Mesh mesh = meshFilter.sharedMesh;
            Vector3[] averageNormals = AverageNormal(mesh);
            WriteToMesh(mesh, averageNormals);
        }

        //SkinnedMeshRenderer蒙皮网格过滤器
        //SkinnedMesh 技术的精华在于蒙皮，所谓的皮并不是模型的贴图，而是 Mesh 本身，蒙皮是指将 Mesh 中的顶点附着（绑定）在骨骼之上。
        SkinnedMeshRenderer[] skinnedMeshRenders = Selection.activeGameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach(var skinMeshRender in skinnedMeshRenders)
        {
            Mesh mesh = skinMeshRender.sharedMesh;
            Vector3[] averageNormals = AverageNormal(mesh);
            WriteToMesh(mesh, averageNormals);
        }
   }

   //将法线写进mesh数据结构中的切线中
   private Vector3[] AverageNormal(Mesh mesh)
   {
        //将每个顶点及其法线写入到字典中
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

        //从字典中读取每个顶点的法线
        Vector3[] averageNormals = new Vector3[mesh.vertexCount];
        for(int j = 0; j < mesh.vertexCount; j++)
        {
            averageNormals[j] = averageNormalHash[mesh.vertices[j]];
        }
        
        return averageNormals;
   }

    #region CreateTangentMesh obsolute
    // //在当前路径创建切线模型(MeshFilter类型)
    // private static void CreateTangentMesh(Mesh rMesh, MeshFilter rMeshFilter)
    // {
    //     string[] path = AssetDatabase.GetAssetPath(rMeshFilter).Split("/");
    //     string createPath = "";
    //     for(int i = 0; i < path.Length - 1; i++)
    //     {
    //         createPath += path[i] + "/";
    //     }
    //     string newMeshPath = createPath + rMeshFilter.name + "_Tangent.mesh";
    //     Debug.Log("存储模型位置：" + newMeshPath);
    //     AssetDatabase.CreateAsset(rMesh, newMeshPath);
    // }

    // //在当前路径创建切线模型(SkinnedMeshRenderer类型)
    // private static void CreateTangentMesh(Mesh rMesh, SkinnedMeshRenderer rSkinMeshRenders)
    // {
    //     string[] path = AssetDatabase.GetAssetPath(rSkinMeshRenders).Split("/");
    //     string createPath = "";
    //     for(int i = 0; i < path.Length - 1; i++)
    //     {
    //         createPath += path[i] + "/";
    //     }
    //     string newMeshPath = createPath + rSkinMeshRenders.name + "_Tangent.mesh";
    //     Debug.Log("存储模型位置：" + newMeshPath);
    //     AssetDatabase.CreateAsset(rMesh, newMeshPath);
    //}   
    #endregion

    public void WriteToMesh(Mesh mesh, Vector3[] averageNormals)
    {
        switch(wt)
        {
            case WRITETYPE.Tangent: //执行写入到 顶点切线
                Vector4[] tangents = new Vector4[mesh.vertexCount];
                for (var j = 0; j < mesh.vertexCount; j++)
                {
                    tangents[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, 0);
                }
                mesh.tangents = tangents;
                break;

            case WRITETYPE.VertexColor: // 写入到顶点色
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
            Debug.Log("请选择物体");
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
                Debug.Log("将法线数据写入到切线位置中");
                Vector4[] tangents = new Vector4[mesh2.vertexCount];
                for(int j = 0; j< mesh2.vertexCount; j++)
                {
                    tangents[j] = new Vector4(averageNormals[j].x, averageNormals[j].y, averageNormals[j].z, 0);
                }
                mesh2.tangents = tangents;
                break;

            case WRITETYPE.VertexColor:
                Debug.Log("将法线数据写入到顶点色位置中");
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

        //创建文件夹路径
        string DeletePath = Application.dataPath + "/NormalSmoothTools";
        Debug.Log(DeletePath);

        //判断文件夹路径是否存在
        if(!Directory.Exists(DeletePath))
        {
            //不存在就创建
            Directory.CreateDirectory(DeletePath);
        }
        //刷新目录
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
