using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BRDFLutCal : MonoBehaviour
{
    public ComputeShader BRDFLUTCS;
    public Material material;
    Texture2D texture;

    // Start is called before the first frame update
    void Start()
    {
        BakeBRDFLut(out texture);
        material.mainTexture = texture;
    }

    // Update is called once per frame
    void Update()
    {
        
    }

    void BakeBRDFLut(out Texture2D tex)
    {
        int resolution = 512;
        int resolution2 = resolution * resolution;

        tex = new Texture2D(resolution, resolution, TextureFormat.RGBA32, false, false);
        tex.wrapMode = TextureWrapMode.Clamp;
        tex.filterMode = FilterMode.Point;

        Color[] tempColors = new Color[resolution2];

        ComputeBuffer resultBuffer = new ComputeBuffer(resolution2, sizeof(float) * 4);

        BRDFLUTCS.SetBuffer(0, "_Result", resultBuffer);
        BRDFLUTCS.SetInt("_Resolution", resolution);
        BRDFLUTCS.Dispatch(0, resolution / 8, resolution / 8, 1);

        resultBuffer.GetData(tempColors);
        tex.SetPixels(tempColors, 0);

        //resultBuffer.Release();
        tex.Apply();
    }
}
