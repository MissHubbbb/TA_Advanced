using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PrefilterCubemap : MonoBehaviour
{
    // 这个CS是计算irradiance的预滤波cubemap贴图的
    public ComputeShader genIrradianceMapShader;
    public ComputeShader BRDFLUTCS;
    public Material material;
    public Cubemap envCM;
    Cubemap irradianceCM;
    Cubemap prefilteredCM;
    Texture2D brdfTex;
    
    void Start()
    {
        PrefilterDiffuseCubemap(envCM, out irradianceCM);
        material.SetTexture("_IrradianceMap", irradianceCM);

        PrePrefilterSpecularCubemap(envCM, out prefilteredCM);
        material.SetTexture("_IBLPrefilteredMap", prefilteredCM);

        BakeBRDFLut(out brdfTex);
        material.SetTexture("_IBLBrdf", brdfTex);
    }

    // 生成irradiance map
    void PrefilterDiffuseCubemap(Cubemap envCubemap, out Cubemap outputCubemap){
        int size = 128;
        outputCubemap = new Cubemap(size, TextureFormat.RGBAFloat, false);

        // ComputeBuffer
        ComputeBuffer resultBuffer = new ComputeBuffer(size * size, sizeof(float) * 4);
        Color[] tempColors = new Color[size * size];
        for(int face = 0; face < 6; face++){
            genIrradianceMapShader.SetTexture(0, "_Cubemap", envCubemap);
            genIrradianceMapShader.SetInt("_Face", face);
            genIrradianceMapShader.SetInt("_Resolution", size);
            genIrradianceMapShader.SetBuffer(0, "_Result", resultBuffer);

            genIrradianceMapShader.Dispatch(0, size / 8, size / 8, 1);

            resultBuffer.GetData(tempColors);
            outputCubemap.SetPixels(tempColors, (CubemapFace)face);
        }
        resultBuffer.Release();
        outputCubemap.Apply();
    }

    // 生成预滤波的环境贴图(基于粗糙度)
    void PrePrefilterSpecularCubemap(Cubemap cubemap, out Cubemap outputCubemap)
    {
        int bakeSize = 128;
        outputCubemap = new Cubemap(bakeSize, TextureFormat.RGBAFloat, true);
        outputCubemap.filterMode = FilterMode.Trilinear;
        int maxMip = outputCubemap.mipmapCount;
        Debug.Log("maxMip: " + maxMip);

        int sampleCubemapSize = cubemap.width;

        for (int mip = 0; mip < maxMip; mip++)
        {
            int size = bakeSize;
            size = size >> mip;

            int size2 = size * size;
            Color[] tempColors = new Color[size2];
            float roughness = (float)mip / (float)(maxMip - 1);
            ComputeBuffer resultBuffer = new ComputeBuffer(size2, sizeof(float) * 4);
            for (int face = 0; face < 6; face++)
            {
                genIrradianceMapShader.SetTexture(1, "_Cubemap", cubemap);
                genIrradianceMapShader.SetInt("_Face", face);
                genIrradianceMapShader.SetInt("_Resolution", size);
                genIrradianceMapShader.SetFloat("_SampleCubemapSize", sampleCubemapSize);
                genIrradianceMapShader.SetFloat("_FilterMipRoughness", roughness);
                genIrradianceMapShader.SetBuffer(1, "_Result", resultBuffer);

                genIrradianceMapShader.Dispatch(1, size / 1, size / 1, 1);
                resultBuffer.GetData(tempColors);
                outputCubemap.SetPixels(tempColors, (CubemapFace)face, mip);
            }
            resultBuffer.Release();
        }
        outputCubemap.Apply(false);
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
