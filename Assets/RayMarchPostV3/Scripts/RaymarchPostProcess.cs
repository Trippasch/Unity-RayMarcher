using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.UI;

[ExecuteInEditMode]

[Serializable]
public sealed class ShaderParameter : ParameterOverride<Shader> { }
[Serializable]
public sealed class ComputeShaderParameter : ParameterOverride<ComputeShader> { }
[Serializable]
public sealed class CubemapParameter : ParameterOverride<Cubemap> { }
[Serializable]
public sealed class GradientParameter : ParameterOverride<Gradient> { }

[Serializable]
[PostProcess(typeof(RaymarchPostProcessRenderer), PostProcessEvent.BeforeStack, "Custom/RaymarchPostProcess")]
public sealed class RaymarchPostProcess : PostProcessEffectSettings
{
    [Header("Setup")]
    public IntParameter maxIterations = new IntParameter { value = 64 };
    public FloatParameter maxDistance = new FloatParameter { value = 100f };
    public FloatParameter minDistance = new FloatParameter { value = 0.01f };

    [Header("Light")]
    public ColorParameter lightCol = new ColorParameter { };
    public FloatParameter lightIntensity = new FloatParameter { };

    [Header("Shadow")]
    [Range(0f, 4f)]
    public FloatParameter shadowIntensity = new FloatParameter { };
    public Vector2Parameter shadowDistance = new Vector2Parameter { };
    [Range(1f, 128f)]
    public FloatParameter shadowPenumbra = new FloatParameter { };

    [Header("Ambient Occlusion")]
    [Range(0.01f, 10.0f)]
    public FloatParameter aoStepSize = new FloatParameter { };
    [Range(0f, 1f)]
    public FloatParameter aoIntensity = new FloatParameter { };
    [Range(1, 5)]
    public IntParameter aoIterations = new IntParameter { };

    [Header("Reflection")]
    [Range(0, 10)]
    public IntParameter reflectionCount = new IntParameter { };
    [Range(0f, 1f)]
    public FloatParameter reflectionIntensity = new FloatParameter { };
    [Range(0f, 1f)]
    public FloatParameter envReflIntensity = new FloatParameter { };
    public CubemapParameter reflectionCube = new CubemapParameter { };

    [Header("Color")]
    public ColorParameter groundColor = new ColorParameter { };
    public GradientParameter sphereGradient = new GradientParameter { };
    public GradientParameter boxGradient = new GradientParameter { };
    public GradientParameter mandelGradient = new GradientParameter { };
    [Range(0f, 4f)]
    public FloatParameter colorIntensity = new FloatParameter { };
    [Range(0f, 2f)]
    public FloatParameter colorLerpTime = new FloatParameter { };
    public BoolParameter repeatable = new BoolParameter { };

    [Header("Distance Field")]
    public Vector4Parameter sphere = new Vector4Parameter { };
    public Vector4Parameter sphere1 = new Vector4Parameter { };
    public Vector4Parameter sphere2 = new Vector4Parameter { };
    public Vector4Parameter sphere3 = new Vector4Parameter { };
    public FloatParameter sphereSmooth = new FloatParameter { };
    public FloatParameter sphereIntersectSmooth = new FloatParameter { };
    public Vector4Parameter box = new Vector4Parameter { };
    public FloatParameter boxRound = new FloatParameter { };
    public FloatParameter boxSphereSmooth = new FloatParameter { };
    public Vector4Parameter torus = new Vector4Parameter { };
    public FloatParameter degreeRotate = new FloatParameter { };
    public FloatParameter dis = new FloatParameter { };
    public FloatParameter twist = new FloatParameter { };
    public FloatParameter onion = new FloatParameter { };
    
    [Header("Modulor")]
    public BoolParameter isModulor = new BoolParameter { };
    public Vector3Parameter modInterval = new Vector3Parameter { };

    [Header("Mandelbulb")]
    [Range(0f, 12f)]
    public FloatParameter power = new FloatParameter { };
    [Range(0f, 20f)]
    public IntParameter iterations = new IntParameter { };
    public Vector4Parameter mandelbulb = new Vector4Parameter { };

    [Header("Mandelbox")]
    public BoolParameter isMandelbox = new BoolParameter { };
    public FloatParameter scaleBox = new FloatParameter { };
    public FloatParameter foldingLimit = new FloatParameter { };
    public FloatParameter fixedRadius2 = new FloatParameter { };
    public FloatParameter minRadius2 = new FloatParameter { };
    public IntParameter iterationsBox = new IntParameter { };
    [Range(0f, 0.1f)]
    public FloatParameter boxBreathe = new FloatParameter { };
    public Vector4Parameter mandelbox = new Vector4Parameter { };

    [Header("Compute Shader")]
    public ComputeShaderParameter sdfcompute = new ComputeShaderParameter { };
    public TextureParameter skyboxTexture = new TextureParameter { };

    public Vector4[] sphereColorVector = new Vector4[8];
    public Vector4[] boxColorVector = new Vector4[8];
    public Vector4[] mandelColorVector = new Vector4[8];
    public int colorIndexS = 0;
    public int colorIndexE = 1;
    public float t = 0f;
    public float myTime = 0f;

    public DepthTextureMode GetCameraFlags()
    {
        return DepthTextureMode.Depth; // DepthTextureMode.DepthNormals;
    }
}

public sealed class RaymarchPostProcessRenderer : PostProcessEffectRenderer<RaymarchPostProcess>
{
    Transform directionalLight;
    Transform pointLight;

    private int kernelid;
    private RenderTexture tempRT;
    private int isMod = 0;

    public override void Init()
    {
        base.Init();

        GameObject light = GameObject.FindGameObjectWithTag("MainLight");
        GameObject plight = GameObject.FindGameObjectWithTag("PointLight");

        if (light)
            directionalLight = light.transform;

        if (plight)
            pointLight = plight.transform;

        // kernelid = settings.sdfcompute.value.FindKernel("CSMain");
    }

    public override void Render(PostProcessRenderContext context)
    {
        Camera _cam = context.camera;

        if (settings.sphereGradient.value != null && settings.boxGradient.value != null && settings.mandelGradient.value != null)
        {
            for (int i = 0; i < 8; i++)
            {
                settings.sphereColorVector[i] = settings.sphereGradient.value.Evaluate((1f / 8) * i);
                settings.boxColorVector[i] = settings.boxGradient.value.Evaluate((1f / 8) * i);
                settings.mandelColorVector[i] = settings.mandelGradient.value.Evaluate((1f / 8) * i);
            }
        }

        // -------Compute Shader-------
        // if (tempRT == null || tempRT.width != Screen.width || tempRT.height != Screen.height)
        // {
        //     if (tempRT != null)
        //     {
        //         tempRT.Release();
        //     }
        //     tempRT = new RenderTexture(context.width, context.height, 0);
        //     tempRT.enableRandomWrite = true;
        //     tempRT.Create();
        //     // context.command.Blit(context.source, tempRT);
        // }

        // settings.sdfcompute.value.SetTexture(kernelid, "Result", tempRT);
        // int threadGroupsX = Mathf.CeilToInt(Screen.width / 8.0f);
        // int threadGroupsY = Mathf.CeilToInt(Screen.height / 8.0f);

        // settings.sdfcompute.value.SetMatrix("_CameraToWorld", _cam.cameraToWorldMatrix);
        // settings.sdfcompute.value.SetMatrix("_CameraInverseProjection", _cam.projectionMatrix.inverse);
        // settings.sdfcompute.value.SetMatrix("_CamFrustum", FrustumCorners(_cam));
        // settings.sdfcompute.value.SetVector("_CamWorldSpace", _cam.transform.position);

        // if (settings.skyboxTexture.value != null)
        // {
        //     settings.sdfcompute.value.SetTexture(kernelid, "_SkyboxTexture", settings.skyboxTexture);
        // }

        // // Light
        // settings.sdfcompute.value.SetFloat("_LightIntensity", settings.lightIntensity);

        // ----------------------------

        // Setup
        var sheet = context.propertySheets.Get(Shader.Find("Raymarch/RaymarchPostV3"));
        if (sheet.properties == null)
        {
            return;
        }
        sheet.properties.SetMatrix("_CamFrustum", FrustumCorners(_cam));
        sheet.properties.SetMatrix("_CamToWorld", _cam.cameraToWorldMatrix);
        sheet.properties.SetVector("_CamWorldSpace", _cam.transform.position);
        sheet.properties.SetInt("_MaxIterations", settings.maxIterations);
        sheet.properties.SetFloat("_MaxDistance", settings.maxDistance);
        sheet.properties.SetFloat("_MinDistance", settings.minDistance);
        // Light
        sheet.properties.SetFloat("_LightIntensity", settings.lightIntensity);
        sheet.properties.SetColor("_LightCol", settings.lightCol);
        // Shadow
        sheet.properties.SetFloat("_ShadowIntensity", settings.shadowIntensity);
        sheet.properties.SetVector("_ShadowDistance", settings.shadowDistance);
        sheet.properties.SetFloat("_ShadowPenumbra", settings.shadowPenumbra);
        // Ambient Occlusion
        sheet.properties.SetFloat("_AOStepSize", settings.aoStepSize);
        sheet.properties.SetFloat("_AOIntensity", settings.aoIntensity);
        sheet.properties.SetInt("_AOIterations", settings.aoIterations);
        // Reflection
        sheet.properties.SetInt("_ReflectionCount", settings.reflectionCount);
        sheet.properties.SetFloat("_ReflectionIntensity", settings.reflectionIntensity);
        sheet.properties.SetFloat("_EnvReflIntensity", settings.envReflIntensity);
        if (settings.reflectionCube.value != null)
        {
            sheet.properties.SetTexture("_ReflectionCube", settings.reflectionCube);
        }
        // Color
        sheet.properties.SetColor("_GroundColor", settings.groundColor);
        sheet.properties.SetVectorArray("_SphereColor", settings.sphereColorVector);
        sheet.properties.SetVectorArray("_BoxColor", settings.boxColorVector);
        sheet.properties.SetVectorArray("_MandelColor", settings.mandelColorVector);
        sheet.properties.SetFloat("_ColorIntensity", settings.colorIntensity);
        sheet.properties.SetInt("_ColorIndexS", settings.colorIndexS);
        sheet.properties.SetInt("_ColorIndexE", settings.colorIndexE);
        // Time
        sheet.properties.SetFloat("_T", settings.t);
        sheet.properties.SetFloat("_MyTime", settings.myTime);
        // Distance Field
        sheet.properties.SetVector("_Sphere", settings.sphere);
        sheet.properties.SetVector("_Sphere1", settings.sphere1);
        sheet.properties.SetVector("_Sphere2", settings.sphere2);
        sheet.properties.SetVector("_Sphere3", settings.sphere2);
        sheet.properties.SetFloat("_SphereSmooth", settings.sphereSmooth);
        sheet.properties.SetFloat("_SphereIntersectSmooth", settings.sphereIntersectSmooth);
        sheet.properties.SetVector("_Box", settings.box);
        sheet.properties.SetFloat("_BoxRound", settings.boxRound);
        sheet.properties.SetFloat("_BoxSphereSmooth", settings.boxSphereSmooth);
        sheet.properties.SetVector("_Torus", settings.torus);
        if (settings.isModulor)
        {
            isMod = 1;
            sheet.properties.SetInt("_IsModulor", isMod);
            sheet.properties.SetVector("_ModInterval", settings.modInterval);
        }
        else
        {
            isMod = 0;
            sheet.properties.SetInt("_IsModulor", isMod);
        }
        sheet.properties.SetFloat("_DegreeRotate", settings.degreeRotate);
        sheet.properties.SetFloat("_Dis", settings.dis);
        sheet.properties.SetFloat("_Twist", settings.twist);
        sheet.properties.SetFloat("_Onion", settings.onion);
        // Mandelbulb
        sheet.properties.SetFloat("_Power", settings.power);
        sheet.properties.SetInt("_Iterations", settings.iterations);
        sheet.properties.SetVector("_Mandelbulb", settings.mandelbulb);
        // Mandelbox
        if (settings.isMandelbox)
        {
            sheet.properties.SetFloat("_ScaleBox", settings.scaleBox);
            sheet.properties.SetFloat("_FoldingLimit", settings.foldingLimit);
            sheet.properties.SetFloat("_FixedRadius2", settings.fixedRadius2);
            sheet.properties.SetFloat("_MinRadius2", settings.minRadius2);
            sheet.properties.SetInt("_IterationsBox", settings.iterationsBox);
            sheet.properties.SetFloat("_BoxBreathe", settings.boxBreathe);
            sheet.properties.SetVector("_Mandelbox", settings.mandelbox);
        }

        if (directionalLight)
        {
            Vector3 positionD = directionalLight.forward;
            sheet.properties.SetVector("_LightDir", new Vector4(positionD.x, positionD.y, positionD.z, 1));
            // settings.sdfcompute.value.SetVector("_LightDir", new Vector4(position.x, position.y, position.z, 1));
        }
        
        if (pointLight)
        {
            Vector3 positionP = pointLight.position;
            sheet.properties.SetVector("_PointLightDir", new Vector4(positionP.x, positionP.y, positionP.z, 1));
        }

        settings.myTime = sheet.properties.GetFloat("_MyTime");

        // context.command.DispatchCompute(settings.sdfcompute, kernelid, threadGroupsX, threadGroupsY, 1);
        // context.command.BlitFullscreenTriangle(tempRT, context.destination);
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 1);
    }

    private Matrix4x4 FrustumCorners(Camera cam)
    {
        Transform camtr = cam.transform;

        Vector3[] frustumCorners = new Vector3[4];
        cam.CalculateFrustumCorners(new Rect(0, 0, 1, 1),
        cam.farClipPlane, cam.stereoActiveEye, frustumCorners);

        Vector3 bottomLeft = camtr.TransformVector(frustumCorners[1]);
        Vector3 topLeft = camtr.TransformVector(frustumCorners[0]);
        Vector3 bottomRight = camtr.TransformVector(frustumCorners[2]);

        Matrix4x4 frustumVectorsArray = Matrix4x4.identity;
        frustumVectorsArray.SetRow(0, bottomLeft);
        frustumVectorsArray.SetRow(1, bottomLeft + (bottomRight - bottomLeft) * 2);
        frustumVectorsArray.SetRow(2, bottomLeft + (topLeft - bottomLeft) * 2);

        return frustumVectorsArray;
    }
}

