using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ParticleEffectCS : MonoBehaviour
{
    public ComputeShader computeShader;
    public Material material;

    int kernelIndex;

    ComputeBuffer particleBuffer;
    const int particleCount = 20000;
    // Start is called before the first frame update
    void Start()
    {
        //ComputeBuffer
        // struct中一共7个float, size=28
        particleBuffer = new ComputeBuffer(particleCount, sizeof(float) * 7, ComputeBufferType.Default);
        ParticleData[] particleDatas = new ParticleData[particleCount];
        particleBuffer.SetData(particleDatas);
        kernelIndex = computeShader.FindKernel("UpdateParticle");
    }

    // Update is called once per frame
    void Update()
    {
        computeShader.SetBuffer(kernelIndex, "particleBuffer", particleBuffer);
        computeShader.SetFloat("Time", Time.time);
        computeShader.Dispatch(kernelIndex, particleCount / 1000, 1, 1);
        material.SetBuffer("_particleDataBuffer", particleBuffer);      //传递ComputeBuffer到我们的shader当中
    }

    // 该方法里我们可以自定义绘制几何
    private void OnRenderObject()
    {
        material.SetPass(0);

        // 我们可以用该方法绘制几何，第一个参数是拓扑结构，第二个参数数顶点数
        Graphics.DrawProceduralNow(MeshTopology.Points, particleCount);
    }

    private void OnDestroy()
    {
        particleBuffer.Release();
        particleBuffer = null;
    }
}
