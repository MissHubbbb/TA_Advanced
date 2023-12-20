using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public struct ParticleData{
    public Vector3 pos;     //等价于float3
    public Color color;      //等价于float4
}

public class CSTest : MonoBehaviour
{
    public ComputeShader computeShader;
    public Material material;

    int kernelIndex;

    ComputeBuffer particleBuffer;
    int particleCount;

    // Start is called before the first frame update
    void Start()
    {
        //Render Texture
        RenderTexture mRenderTex = new RenderTexture(256, 256, 16);
        mRenderTex.enableRandomWrite = true;
        mRenderTex.Create();

        material.mainTexture = mRenderTex;
        kernelIndex = computeShader.FindKernel("CSMain");
        computeShader.SetTexture(kernelIndex, "Result", mRenderTex);

        computeShader.Dispatch(kernelIndex, 256 / 8, 256 / 8, 1);

        
    }

    // Update is called once per frame
    void Update()
    {        
        
    }
}
