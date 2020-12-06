Shader "Raymarch/RaymarchPostV3"
{

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            // Tags {
            //     "LightMode" = "ForwardBase"
            // }

            HLSLPROGRAM

            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            //#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
            //#include "HLSLSupport.cginc"
            #include "UnityCG.cginc"
            #include "DistanceFunctions.cginc"

            // Setup
            //TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
            uniform sampler2D _MainTex;
            uniform sampler2D_float _CameraDepthTexture, sampler_CameraDepthTexture;
            half4 _MainTex_ST;
            uniform float4 _CamWorldSpace;
            uniform float4x4 _CamFrustum,  _CamToWorld;
            uniform int _MaxIterations;
            uniform float _MaxDistance;
            uniform float _MinDistance;
            // Light
            uniform float3 _LightDir, _LightCol;
            uniform float _LightIntensity;
            float4 _Tint;
            // Color
            uniform fixed4 _GroundColor;
            uniform fixed4 _SphereColor[8];
            uniform float _ColorIntensity;
            uniform fixed4 _BoxColor[8];
            uniform fixed4 _MandelColor[8];
            uniform int _ColorIndexS; // start color to interpolate
            uniform int _ColorIndexE; // end color of interpolation
            // Time
            uniform float _T; // time speed for color interpolation
            uniform float _MyTime;
            // Shadow
            uniform float2 _ShadowDistance;
            uniform float _ShadowIntensity, _ShadowPenumbra;
            // Ambient Occlussion
            uniform float _AOStepSize, _AOIntensity;
            uniform int _AOIterations;
            // Reflection
            uniform int _ReflectionCount;
            uniform float _ReflectionIntensity, _EnvReflIntensity;
            uniform samplerCUBE _ReflectionCube;
            // Distance Field
            uniform float4 _Sphere;
            uniform float4 _Sphere1;
            uniform float4 _Sphere2;
            uniform float4 _Sphere3;
            uniform float _SphereSmooth, _SphereIntersectSmooth;
            uniform float4 _Box;
            uniform float _BoxRound, _BoxSphereSmooth;
            uniform float4 _Torus;
            uniform int _IsModulor;
            uniform float3 _ModInterval;
            uniform float _DegreeRotate;
            uniform float _Dis;
            uniform float _Twist;
            uniform float _Onion;
            // Mandelbulb
            uniform float _Power;
            uniform int _Iterations;
            uniform float4 _Mandelbulb;
            // Mandelbox
            uniform float _ScaleBox;
            uniform float _FoldingLimit;
            uniform float _FixedRadius2;
            uniform float _MinRadius2;
            uniform int _IterationsBox;
            uniform float _BoxBreathe;
            uniform float4 _Mandelbox;

            uniform float glow = 0;

            uniform float4 _MainTex_TexelSize;

            struct AttributesDefault
            {
                float3 vertex : POSITION;
                half2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
             float4 vertex : SV_POSITION;
             float2 texcoord : TEXCOORD0;
             float2 texcoordStereo : TEXCOORD1;
             float4 ray : TEXCOORD2;
            };

            // Vertex manipulation
            float2 TransformTriangleVertexToUV(float2 vertex)
            {
                float2 uv = (vertex + 1.0) * 0.5;
                return uv;
            }

            v2f vert(AttributesDefault v  )
            {
                v2f o;
                v.vertex.z = 0.1;
                o.vertex = float4(v.vertex.xy, 0.0, 1.0);
                o.texcoord = TransformTriangleVertexToUV(v.vertex.xy);
                o.texcoordStereo = TransformStereoScreenSpaceTex(o.texcoord, 1.0);
 
                int index = (o.texcoord.x / 2) + o.texcoord.y;
                o.ray = _CamFrustum[index];
 
                return o;
            }

            float3 rotateY(float3 v, float degree)
            {
                float rad = 0.0174532925 * degree; // convert degree to rad
                float cosY = cos(rad);
                float sinY = sin(rad);
                return float3(cosY * v.x - sinY * v.z, v.y, sinY * v.x + cosY * v.z);
            }

            float3 rotateX(float3 v, float degree)
            {
                float rad = 0.0174532925 * degree; // convert degree to rad
                float cosX = cos(rad);
                float sinX = sin(rad);
                return float3(v.x, cosX * v.y - sinX * v.z, sinX * v.y + cosX * v.z);
            }

            float3 bounceY(float3 v, float degree)
            {
                float rad = 0.0174532925 * degree; // convert degree to rad
                float cosY = cos(rad);
                float sinY = sin(rad);
                return float3(v.x, sinY * 4 + v.y - 1, v.z);
            }

            float3 bounceX(float3 v, float degree)
            {
                float rad = 0.0174532925 * degree; // convert degree to rad
                float cosX = cos(rad);
                float sinX = sin(rad);
                return float3(sin(rad + (3 * 3.14) * 0.5) * 5 + v.x, v.y, v.z);
            }

            float3 bounceX3(float3 v, float degree)
            {
                float rad = 0.0174532925 * degree; // convert degree to rad
                float cosX = cos(rad);
                float sinX = sin(rad);
                return float3(sin(rad + (3.14) * 0.5) * 5 + v.x, v.y, v.z);
            }

            float2 pattern(float2 p)
            {
                p = frac(p);
                float r = 0.123;
                float v = 0.0, g = 0.0;
                r = frac(r * 9184.928);
                float cp, d;
                
                d = p.x;
                g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 1000.0);
                d = p.y;
                g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 1000.0);
                d = p.x - 1.0;
                g += pow(clamp(3.0 - abs(d), 0.0, 1.0), 1000.0);
                d = p.y - 1.0;
                g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 10000.0);

                const int ITER = 12;
                for(int i = 0; i < ITER; i ++)
                {
                    cp = 0.5 + (r - 0.5) * 0.9;
                    d = p.x - cp;
                    g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 200.0);
                    if(d > 0.0) {
                        r = frac(r * 4829.013);
                        p.x = (p.x - cp) / (1.0 - cp);
                        v += 1.0;
                    }
                    else {
                        r = frac(r * 1239.528);
                        p.x = p.x / cp;
                    }
                    p = p.yx;
                }
                v /= float(ITER);
                return float2(g, v);
            }

            float4 boxSphere(float3 p)
            {
                float4 sphere = float4(lerp(_SphereColor[_ColorIndexS].rgb, _SphereColor[_ColorIndexE].rgb, _T), sdSphere(rotateY(p, _DegreeRotate * _Time), _Sphere.xyz, _Sphere.w));
                float4 box = float4(lerp(_BoxColor[_ColorIndexS].rgb, _BoxColor[_ColorIndexE].rgb, _T), opDisplace(sdRoundBox(rotateY(p, _DegreeRotate * _Time), _Box.xyz, _Box.www, _BoxRound), p, _Dis));
                float4 combine1 = opSS(sphere, box, _BoxSphereSmooth);
                float4 sphere1 = float4(lerp(_SphereColor[_ColorIndexS].rgb, _SphereColor[_ColorIndexE].rgb, _T), sdSphere(bounceY(p, _DegreeRotate * _Time), _Sphere1.xyz, _Sphere1.w));
                float4 combine2 = opUS(sphere1, combine1, _SphereSmooth);
                return combine2;
            }

            float4 distanceField(float3 p, inout float trap) {

                if (_IsModulor)
                {
                    // For Infinite planes and axis
                    float modX = pMod1(p.x, _ModInterval.x);
                    float modY = pMod1(p.y, _ModInterval.y);
                    float modZ = pMod1(p.z, _ModInterval.z);
                }
                
                float4 ground = float4(_GroundColor.rgb, sdPlane(p, float4(0, 1, 0, 0)));
                float4 torus = float4(lerp(_SphereColor[_ColorIndexS].rgb, _SphereColor[_ColorIndexE].rgb, _T), sdTorus(p, _Torus.xyz, float2(_Torus.w, _Torus.w / 5.0)));
                float4 boxSphere1 = boxSphere(p);
                float4 sphere2 = float4(lerp(_SphereColor[_ColorIndexS].rgb, _SphereColor[_ColorIndexE].rgb, _T), sdSphere(bounceX3(rotateY(p, _DegreeRotate * _Time), _DegreeRotate * _Time), _Sphere2.xyz, _Sphere2.w));
                float4 sphere3 = float4(lerp(_SphereColor[_ColorIndexS].rgb, _SphereColor[_ColorIndexE].rgb, _T), sdSphere(bounceX(rotateY(p, _DegreeRotate * _Time), _DegreeRotate * _Time), _Sphere3.xyz, _Sphere3.w));
                float4 combineSpheres = opUS(sphere2, sphere3, _SphereSmooth);
                float4 combine = opUS(boxSphere1, combineSpheres, _SphereSmooth);
                float4 combine1 = opUS(combine, torus, _SphereSmooth);
                
                // float4 mandelbulb = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), mandelbulbSDF(rotateX(rotateY(p, _DegreeRotate * _Time), _DegreeRotate * _Time), trap, _Mandelbulb, _Power, _Iterations, glow));
                float4 mandelbox = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), mandelboxSDF((p * _Mandelbox.w) - _Mandelbox.xyz, _ScaleBox, _IterationsBox, _FixedRadius2, _MinRadius2, _FoldingLimit, trap, glow, _BoxBreathe, _MyTime));
                float4 hartver = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), hartverdrahtet(p));
                float4 kaleido = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), kaleidoscopic_IFS(p));
                float4 kleinian = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), pseudo_kleinian(p));
                float4 knightyan = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), pseudo_knightyan(p));
                float4 tglad = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), tglad_formula(p));

                // return opU(ground, min(combine1, 1.0));
                return min(mandelbox, 1.0);
            }

            float3 getNormal(float3 p)
            {
                float trap;
                const float2 offset = float2(0.001, 0.0);
                
                float3 n = float3(
                    distanceField(p + offset.xyy, trap).w - distanceField(p - offset.xyy, trap).w,
                    distanceField(p + offset.yxy, trap).w - distanceField(p - offset.yxy, trap).w,
                    distanceField(p + offset.yyx, trap).w - distanceField(p - offset.yyx, trap).w);

                return normalize(n);
            }

            float hardShadow(float3 ro, float3 rd, float mint, float maxt)
            {
                float trap;
                for (float t = mint; t < maxt;)
                {
                    float h = distanceField(ro + rd * t, trap).w;
                    if (h < 0.001)
                    {
                        return 0.0;
                    }
                    t += h;
                }
                return 1.0;
            }

            float softShadow(float3 ro, float3 rd, float mint, float maxt, float k, float3 n)
            {
                float trap;
                float result = 1.0;
                for (float t = mint; t < maxt;)
                {
                    float h = distanceField(ro + rd * t, trap).w;
                    if (h < 0.001)
                    {
                        return 0.0;
                    }
                    result = min(result, k * h / t);
                    t += h;
                }
                return result * clamp(dot(n, rd), 0, 1);
            }
            
            float ambientOcclusion(float3 p, float3 n)
            {
                float trap;
                float step = _AOStepSize;
                float ao = 0.0;
                float dist;
                for (int i = 1; i <= _AOIterations; i++)
                {
                    dist = step * i;
                    ao += max(0.0, (dist - distanceField(p + n * dist, trap).w) / dist);

                }
                return 1.0 - clamp(ao * _AOIntensity, 0.0, 1.0);
            }

            float3 shading(float3 p, float3 n, fixed3 c, float trap)
            {
                float3 result;
                // Directional Light
                float3 light = (_LightCol * clamp(dot(normalize(-_LightDir - p), n), 0.0, 1.0) * 0.5 + 0.5) * _LightIntensity;
                // Ambient Light
                light += 2.5 * _LightCol * (0.05 + 0.3 * _LightIntensity);
                // Shadows
                float shadow = softShadow(p, -_LightDir, _ShadowDistance.x, _ShadowDistance.y, _ShadowPenumbra, n) * 0.5 + 0.5;
                shadow = max(0.0, pow(shadow, _ShadowIntensity));
                // Ambient Occlusion
                float ao = ambientOcclusion(p, n);
                // Diffuse Color
                // float3 color = c.rgb * _ColorIntensity;
                // float3 color = c.rgb * _ColorIntensity * glow * 0.2;

                // Color fractal Mandelbulb
                // color = float3(0.01, 0.01, 0.01);
                // color = lerp( color, float3(0.10,0.20,0.30), clamp(trap.y,0.0,1.0) );
                // color = lerp( color, float3(0.02,0.10,0.30), clamp(trap.z*trap.z,0.0,1.0) );
                // color = lerp( color, _GroundColor, clamp(pow(trap.w,6.0),0.0,1.0) );
                // color *= 0.5;

                // Color fractal Mandelbox
                // color = lerp(color, _GroundColor, clamp(trap.x*trap.x, 0.0, 1.0));
                // color = lerp(color, _GroundColor, clamp(trap.y*trap.y, 0.0, 1.0));
                // color = lerp(color, 0.1*_GroundColor, clamp(trap.z*trap.z, 0.0, 1.0));
                // color *= 0.5;

                // Calculate glowline
                float glowline = 0.0;
                float3 p3 = p;
                p3 *= 2.0;
                glowline += max((modc(length(p3) - _Time.y*3, 15.0) - 12.0)*0.7, 0.0);
                float2 p2 = pattern(p3.xz*0.5);
                if(p2.x<1.3) { glowline = 0.0; }
                glowline += max(1.0-abs(dot(-UNITY_MATRIX_V[2].xyz, n)) - 0.4, 0.0) * 1.0;
                float3 emmission = float3(0.7, 0.7, 1.0) * glowline * 0.6;

                float3 color = _ColorIntensity;
                float ct=(abs(frac(trap*1.0)-0.5)*2.0)*0.35+0.65;
                float ct2=abs(frac(trap*.071)-0.5)*2.0;
                color*=lerp(fixed3(0.8,0.7,0.4)*ct,fixed3(0.7,0.15,0.2)*ct,ct2);

                result = light * shadow * color * ao;
                return result;
            }

            bool rayMarching(float3 ro, float3 rd, float depth, float _MaxDistance, int _MaxIterations, inout float3 p, inout fixed3 dColor, out float resColor)
            {
                bool hit;
                float t = 0.01; // distance travelled along the ray direction

                float trap = 10.0;

                for (int i = 0; i < _MaxIterations; i++)
                {
                    if (t > _MaxDistance || t >= depth)
                    {
                        //Environment
                        hit = false;
                        break;
                    }
                    p = ro + rd * t; // World space position of sample
                    // check for a hit in distancefield
                    float4 d = distanceField(p, trap);
                    if (abs(d.w) <= _MinDistance) // we have hit something!
                    {
                        dColor = d.rgb;
                        hit = true;
                        resColor = trap;
                        break;
                    }
                    t += d.w;
                }
                return hit;
            }

            float4 frag(v2f i) : SV_Target
            {
                i.texcoord.y = 1 - i.texcoord.y;
                float4 col = tex2D(_MainTex, i.texcoord);
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(i.texcoord));
                depth = Linear01Depth(depth);
                depth *= length(i.ray);

                float3 rayOrigin = _CamWorldSpace;
                float3 rayDirection = normalize(i.ray);
                fixed4 res;
                float3 hitPos = 0;
                fixed3 dColor;
                float trap;

                bool hit = rayMarching(rayOrigin, rayDirection, depth, _MaxDistance, _MaxIterations, hitPos, dColor, trap);
                if (hit) // hit
                {
                    res = fixed4(0, 0, 0, 1);
                    //shading!
                    float3 n = getNormal(hitPos);
                    float3 s = shading(hitPos, n, dColor, trap);
                    res = fixed4(s, 1);

                    uint mipLevel = 2;
                    float invMipLevel = .5f;

                    // Reflections
                    for (int i = 0; i < _ReflectionCount; i++)
                    {
                        // reflected ray
                        rayDirection = normalize(reflect(rayDirection, n));
                        rayOrigin = hitPos + (rayDirection * 0.01);
                        hit = rayMarching(rayOrigin, rayDirection, _MaxDistance * invMipLevel, _MaxDistance * invMipLevel, _MaxIterations / mipLevel, hitPos, dColor, trap);
                        if (hit) // reflected ray hit
                        {
                            //shading!
                            float3 n = getNormal(hitPos);
                            float3 s = shading(hitPos, n, dColor, trap);
                            res += fixed4(s * _ReflectionIntensity, 0) * invMipLevel;
                        }
                        else // reflected ray missed
                        {
                            break;
                        }
                        mipLevel *= 2;
                        invMipLevel *= 0.5;
                    }
                    // draw the env reflexion even if the last reflexion cast was a hit
                    if (_ReflectionCount > 0)
                    {
                        // environment reflection
                        res += fixed4(texCUBE(_ReflectionCube, rayDirection).rgb * _EnvReflIntensity, 0);
                    }
                }
                else // miss
                {
                    res = fixed4(0, 0, 0, 0);
                }
                
                // returns whichever is closer to the camera
                return fixed4(col * (1.0 - res.w) + res.xyz * res.w, 1.0);
            }

            ENDHLSL
        }

        Pass
        {
            // Tags {
            //     "LightMode" = "ForwardAdd"
            // }

            // Blend One Zero

            HLSLPROGRAM

            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            //#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
            //#include "HLSLSupport.cginc"
            #include "UnityCG.cginc"
            #include "DistanceFunctions.cginc"

            // Setup
            //TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
            uniform sampler2D _MainTex;
            uniform sampler2D_float _CameraDepthTexture, sampler_CameraDepthTexture;
            half4 _MainTex_ST;
            uniform float4 _CamWorldSpace;
            uniform float4x4 _CamFrustum,  _CamToWorld;
            uniform int _MaxIterations;
            uniform float _MaxDistance;
            uniform float _MinDistance;
            // Light
            uniform float3 _PointLightDir, _LightCol;
            uniform float _LightIntensity;
            float4 _Tint;
            // Color
            uniform fixed4 _GroundColor;
            uniform fixed4 _SphereColor[8];
            uniform float _ColorIntensity;
            uniform fixed4 _BoxColor[8];
            uniform fixed4 _MandelColor[8];
            uniform int _ColorIndexS; // start color to interpolate
            uniform int _ColorIndexE; // end color of interpolation
            // Time
            uniform float _T; // time speed for color interpolation
            uniform float _MyTime;
            // Shadow
            uniform float2 _ShadowDistance;
            uniform float _ShadowIntensity, _ShadowPenumbra;
            // Ambient Occlussion
            uniform float _AOStepSize, _AOIntensity;
            uniform int _AOIterations;
            // Reflection
            uniform int _ReflectionCount;
            uniform float _ReflectionIntensity, _EnvReflIntensity;
            uniform samplerCUBE _ReflectionCube;
            // Distance Field
            uniform float4 _Sphere;
            uniform float4 _Sphere1;
            uniform float4 _Sphere2;
            uniform float4 _Sphere3;
            uniform float _SphereSmooth, _SphereIntersectSmooth;
            uniform float4 _Box;
            uniform float _BoxRound, _BoxSphereSmooth;
            uniform float4 _Torus;
            uniform int _IsModulor;
            uniform float3 _ModInterval;
            uniform float _DegreeRotate;
            uniform float _Dis;
            uniform float _Twist;
            uniform float _Onion;
            // Mandelbulb
            uniform float _Power;
            uniform int _Iterations;
            uniform float4 _Mandelbulb;
            // Mandelbox
            uniform float _ScaleBox;
            uniform float _FoldingLimit;
            uniform float _FixedRadius2;
            uniform float _MinRadius2;
            uniform int _IterationsBox;
            uniform float _BoxBreathe;
            uniform float4 _Mandelbox;

            uniform float glow = 0;

            uniform float4 _MainTex_TexelSize;

            struct AttributesDefault
            {
                float3 vertex : POSITION;
                half2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
             float4 vertex : SV_POSITION;
             float2 texcoord : TEXCOORD0;
             float2 texcoordStereo : TEXCOORD1;
             float4 ray : TEXCOORD2;
            };

            // Vertex manipulation
            float2 TransformTriangleVertexToUV(float2 vertex)
            {
                float2 uv = (vertex + 1.0) * 0.5;
                return uv;
            }

            v2f vert(AttributesDefault v  )
            {
                v2f o;
                v.vertex.z = 0.1;
                o.vertex = float4(v.vertex.xy, 0.0, 1.0);
                o.texcoord = TransformTriangleVertexToUV(v.vertex.xy);
                o.texcoordStereo = TransformStereoScreenSpaceTex(o.texcoord, 1.0);

                int index = (o.texcoord.x / 2) + o.texcoord.y;
                o.ray = _CamFrustum[index];
 
                return o;
            }

            float3 rotateY(float3 v, float degree)
            {
                float rad = 0.0174532925 * degree; // convert degree to rad
                float cosY = cos(rad);
                float sinY = sin(rad);
                return float3(cosY * v.x - sinY * v.z, v.y, sinY * v.x + cosY * v.z);
            }

            float3 rotateX(float3 v, float degree)
            {
                float rad = 0.0174532925 * degree; // convert degree to rad
                float cosX = cos(rad);
                float sinX = sin(rad);
                return float3(v.x, cosX * v.y - sinX * v.z, sinX * v.y + cosX * v.z);
            }

            float3 bounceY(float3 v, float degree)
            {
                float rad = 0.0174532925 * degree; // convert degree to rad
                float cosY = cos(rad);
                float sinY = sin(rad);
                return float3(v.x, sinY * 4 + v.y - 1, v.z);
            }

            float3 bounceX(float3 v, float degree)
            {
                float rad = 0.0174532925 * degree; // convert degree to rad
                float cosX = cos(rad);
                float sinX = sin(rad);
                return float3(sin(rad + (3 * 3.14) * 0.5) * 5 + v.x, v.y, v.z);
            }

            float3 bounceX3(float3 v, float degree)
            {
                float rad = 0.0174532925 * degree; // convert degree to rad
                float cosX = cos(rad);
                float sinX = sin(rad);
                return float3(sin(rad + (3.14) * 0.5) * 5 + v.x, v.y, v.z);
            }

            float2 pattern(float2 p)
            {
                p = frac(p);
                float r = 0.123;
                float v = 0.0, g = 0.0;
                r = frac(r * 9184.928);
                float cp, d;
                
                d = p.x;
                g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 1000.0);
                d = p.y;
                g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 1000.0);
                d = p.x - 1.0;
                g += pow(clamp(3.0 - abs(d), 0.0, 1.0), 1000.0);
                d = p.y - 1.0;
                g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 10000.0);

                const int ITER = 12;
                for(int i = 0; i < ITER; i ++)
                {
                    cp = 0.5 + (r - 0.5) * 0.9;
                    d = p.x - cp;
                    g += pow(clamp(1.0 - abs(d), 0.0, 1.0), 200.0);
                    if(d > 0.0) {
                        r = frac(r * 4829.013);
                        p.x = (p.x - cp) / (1.0 - cp);
                        v += 1.0;
                    }
                    else {
                        r = frac(r * 1239.528);
                        p.x = p.x / cp;
                    }
                    p = p.yx;
                }
                v /= float(ITER);
                return float2(g, v);
            }

            float4 boxSphere(float3 p)
            {
                float4 sphere = float4(lerp(_SphereColor[_ColorIndexS].rgb, _SphereColor[_ColorIndexE].rgb, _T), sdSphere(rotateY(p, _DegreeRotate * _Time), _Sphere.xyz, _Sphere.w));
                float4 box = float4(lerp(_BoxColor[_ColorIndexS].rgb, _BoxColor[_ColorIndexE].rgb, _T), opDisplace(sdRoundBox(rotateY(p, _DegreeRotate * _Time), _Box.xyz, _Box.www, _BoxRound), p, _Dis));
                float4 combine1 = opSS(sphere, box, _BoxSphereSmooth);
                float4 sphere1 = float4(lerp(_SphereColor[_ColorIndexS].rgb, _SphereColor[_ColorIndexE].rgb, _T), sdSphere(bounceY(p, _DegreeRotate * _Time), _Sphere1.xyz, _Sphere1.w));
                float4 combine2 = opUS(sphere1, combine1, _SphereSmooth);
                return combine2;
            }

            float4 distanceField(float3 p, inout float trap) {

                if (_IsModulor)
                {
                    // For Infinite planes and axis
                    float modX = pMod1(p.x, _ModInterval.x);
                    float modY = pMod1(p.y, _ModInterval.y);
                    float modZ = pMod1(p.z, _ModInterval.z);
                }

                float4 ground = float4(_GroundColor.rgb, sdPlane(p, float4(0, 1, 0, 0)));
                float4 torus = float4(lerp(_SphereColor[_ColorIndexS].rgb, _SphereColor[_ColorIndexE].rgb, _T), sdTorus(p, _Torus.xyz, float2(_Torus.w, _Torus.w / 5.0)));
                float4 boxSphere1 = boxSphere(p);
                float4 sphere2 = float4(lerp(_SphereColor[_ColorIndexS].rgb, _SphereColor[_ColorIndexE].rgb, _T), sdSphere(bounceX3(rotateY(p, _DegreeRotate * _Time), _DegreeRotate * _Time), _Sphere2.xyz, _Sphere2.w));
                float4 sphere3 = float4(lerp(_SphereColor[_ColorIndexS].rgb, _SphereColor[_ColorIndexE].rgb, _T), sdSphere(bounceX(rotateY(p, _DegreeRotate * _Time), _DegreeRotate * _Time), _Sphere3.xyz, _Sphere3.w));
                float4 combineSpheres = opUS(sphere2, sphere3, _SphereSmooth);
                float4 combine = opUS(boxSphere1, combineSpheres, _SphereSmooth);
                float4 combine1 = opUS(combine, torus, _SphereSmooth);
                
                // float4 mandelbulb = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), mandelbulbSDF(rotateX(rotateY(p, _DegreeRotate * _Time), _DegreeRotate * _Time), trap, _Mandelbulb, _Power, _Iterations, glow));
                float4 mandelbox = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), mandelboxSDF((p * _Mandelbox.w) - _Mandelbox.xyz, _ScaleBox, _IterationsBox, _FixedRadius2, _MinRadius2, _FoldingLimit, trap, glow, _BoxBreathe, _MyTime));
                float4 hartver = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), hartverdrahtet(p));
                float4 kaleido = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), kaleidoscopic_IFS(p));
                float4 kleinian = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), pseudo_kleinian(p));
                float4 knightyan = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), pseudo_knightyan(p));
                float4 tglad = float4(lerp(_MandelColor[_ColorIndexS].rgb, _MandelColor[_ColorIndexE].rgb, _T), tglad_formula(p));

                // return opU(ground, min(combine1, 1.0));
                return min(mandelbox, 1.0);
            }

            float3 getNormal(float3 p)
            {
                float trap;
                const float2 offset = float2(0.001, 0.0);
                
                float3 n = float3(
                    distanceField(p + offset.xyy, trap).w - distanceField(p - offset.xyy, trap).w,
                    distanceField(p + offset.yxy, trap).w - distanceField(p - offset.yxy, trap).w,
                    distanceField(p + offset.yyx, trap).w - distanceField(p - offset.yyx, trap).w);

                return normalize(n);
            }

            float hardShadow(float3 ro, float3 rd, float mint, float maxt)
            {
                float trap;
                for (float t = mint; t < maxt;)
                {
                    float h = distanceField(ro + rd * t, trap).w;
                    if (h < 0.001)
                    {
                        return 0.0;
                    }
                    t += h;
                }
                return 1.0;
            }

            float softShadow(float3 ro, float3 rd, float mint, float maxt, float k, float3 n)
            {
                float3 prayDir = rd - ro;
                float3 dir = normalize(prayDir);
                float maxLength = length(prayDir);
                float3 rayPos = ro;
                float trap;
                float h = 1000.0;
                float t = 0.1;rayPos += dir * t;
                float result = 1.0;
                for (int i = 0; i < mint && t < maxt; i++)
                {
                    if (h < 0.001)
                    {
                        return 0.0;
                    }
                    h = distanceField(rayPos, trap).w;
                    result = min(result, k * h / t);
                    t += h;
                    rayPos += h * dir;
                }
                return result * clamp(dot(n, dir), 0.0, 1.0);
            }
            
            float ambientOcclusion(float3 p, float3 n)
            {
                float trap;
                float step = _AOStepSize;
                float ao = 0.0;
                float dist;
                for (int i = 1; i <= _AOIterations; i++)
                {
                    dist = step * i;
                    ao += max(0.0, (dist - distanceField(p + n * dist, trap).w) / dist);

                }
                return 1.0 - clamp(ao * _AOIntensity, 0.0, 1.0);
            }

            float3 shading(float3 p, float3 n, fixed3 c, float trap)
            {
                float3 result;
                // Point Light
                float3 pointLightDir = _PointLightDir - p;
                float pDiffuse = (_LightCol * clamp(dot(normalize(pointLightDir), n), 0.0, 1.0) * 0.5 + 0.5) * _LightIntensity;
                float d = distance(_PointLightDir, p);
                float attenuation = 1 / d;
                // Ambient Light
                // pDiffuse += 2.5 * _LightCol * (0.05 + 0.3 * _LightIntensity);
                // Shadows
                float pshadow = softShadow(p, _PointLightDir, _ShadowDistance.x, _ShadowDistance.y, _ShadowPenumbra, n) * 0.5 + 0.5;
                pshadow = max(0.0, pow(pshadow, _ShadowIntensity));
                // Ambient Occlusion
                float ao = ambientOcclusion(p, n);
                // Diffuse Color
                // float3 color = c.rgb * _ColorIntensity;
                // float3 color = c.rgb * _ColorIntensity * glow * 0.2;

                // Color fractal Mandelbulb
                // color = float3(0.01, 0.01, 0.01);
                // color = lerp( color, float3(0.10,0.20,0.30), clamp(trap.y,0.0,1.0) );
                // color = lerp( color, float3(0.02,0.10,0.30), clamp(trap.z*trap.z,0.0,1.0) );
                // color = lerp( color, _GroundColor, clamp(pow(trap.w,6.0),0.0,1.0) );
                // color *= 0.5;

                // Color fractal Mandelbox
                // color = lerp(color, _GroundColor, clamp(trap.x*trap.x, 0.0, 1.0));
                // color = lerp(color, _GroundColor, clamp(trap.y*trap.y, 0.0, 1.0));
                // color = lerp(color, 0.1*_GroundColor, clamp(trap.z*trap.z, 0.0, 1.0));
                // color *= 0.5;
                
                // Calculate glowline
                float glowline = 0.0;
                float3 p3 = p;
                p3 *= 2.0;
                glowline += max((modc(length(p3) - _Time.y*3, 18.0) - 15.0)*6.7, 1.0);
                float2 p2 = pattern(p3.xz *0.5);
                if(p2.x<1.3) { glowline = 1.0; }
                glowline += max(1.0-abs(dot(-UNITY_MATRIX_V[2].xyz, n)) - 0.4, 0.0) * 1.0;
                float3 emmission = float3(0.7, 0.7, 1.0) * glowline * 1.0;

                // Color dichromatic Mandelbox
                float3 color = _ColorIntensity;
                float ct=(abs(frac(trap*1.0)-0.5)*2.0)*0.35+0.65;
                float ct2=abs(frac(trap*.071)-0.5)*2.0;
                color*=lerp(fixed3(0.8,0.7,0.4)*ct,fixed3(0.7,0.15,0.2)*ct,ct2);

                result = pDiffuse * pshadow * color * ao * attenuation;

                return result;
            }

            bool rayMarching(float3 ro, float3 rd, float depth, float _MaxDistance, int _MaxIterations, inout float3 p, inout fixed3 dColor, out float resColor)
            {
                bool hit;
                float t = 0.01; // distance travelled along the ray direction

                float trap = 10.0;

                for (int i = 0; i < _MaxIterations; i++)
                {
                    if (t > _MaxDistance || t >= depth)
                    {
                        //Environment
                        hit = false;
                        break;
                    }
                    p = ro + rd * t; // World space position of sample
                    // check for a hit in distancefield
                    float4 d = distanceField(p, trap);
                    if (abs(d.w) <= _MinDistance) // we have hit something!
                    {
                        dColor = d.rgb;
                        hit = true;
                        resColor = trap;
                        break;
                    }
                    t += d.w;
                }
                return hit;
            }

            float4 frag(v2f i) : SV_Target
            {
                i.texcoord.y = 1 - i.texcoord.y;
                float4 col = tex2D(_MainTex, i.texcoord);
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(i.texcoord));
                depth = Linear01Depth(depth);
                depth *= length(i.ray);
                
                float3 rayOrigin = _CamWorldSpace;
                float3 rayDirection = normalize(i.ray);
                fixed4 res;
                float3 hitPos = 0;
                fixed3 dColor;
                float trap;

                bool hit = rayMarching(rayOrigin, rayDirection, depth, _MaxDistance, _MaxIterations, hitPos, dColor, trap);
                if (hit) // hit
                {
                    res = fixed4(0, 0, 0, 1);
                    //shading!
                    float3 n = getNormal(hitPos);
                    float3 s = shading(hitPos, n, dColor, trap);
                    res = fixed4(s, 1);

                    uint mipLevel = 2;
                    float invMipLevel = .5f;

                    // Reflections
                    for (int i = 0; i < _ReflectionCount; i++)
                    {
                        // reflected ray
                        rayDirection = normalize(reflect(rayDirection, n));
                        rayOrigin = hitPos + (rayDirection * 0.01);
                        hit = rayMarching(rayOrigin, rayDirection, _MaxDistance * invMipLevel, _MaxDistance * invMipLevel, _MaxIterations / mipLevel, hitPos, dColor, trap);
                        if (hit) // reflected ray hit
                        {
                            //shading!
                            float3 n = getNormal(hitPos);
                            float3 s = shading(hitPos, n, dColor, trap);
                            res += fixed4(s * _ReflectionIntensity, 0) * invMipLevel;
                        }
                        else // reflected ray missed
                        {
                            break;
                        }
                        mipLevel *= 2;
                        invMipLevel *= 0.5;
                    }
                    // draw the env reflexion even if the last reflexion cast was a hit
                    if (_ReflectionCount > 0)
                    {
                        // environment reflection
                        res += fixed4(texCUBE(_ReflectionCube, rayDirection).rgb * _EnvReflIntensity, 0);
                    }
                }
                else // miss
                {
                    res = fixed4(0, 0, 0, 0);
                }
                
                // returns whichever is closer to the camera
                return fixed4(col * (1.0 - res.w) + res.xyz * res.w, 1.0);
            }

            ENDHLSL
        }
    }
}