using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DistanceFunctions : MonoBehaviour
{
    float pi = 3.1415926535897932384626433832795f;

    // GLSL compatible mod()
    float  modc(float  a, float  b) { return a - b * Mathf.Floor(a/b); }

    //returs the absolute value of a vector
    Vector3 Abs(Vector3 vec)
    {
        return new Vector3(Mathf.Abs(vec.x), Mathf.Abs(vec.y), Mathf.Abs(vec.z));
    }

    //returs the absolute value of a vector
    Vector2 Abs2(Vector2 vec)
    {
        return new Vector2(Mathf.Abs(vec.x), Mathf.Abs(vec.y));
    }

    //returns the Largest Vector
    Vector3 Max(Vector3 vec1, Vector3 vec2)
    {
        return new Vector3(Mathf.Max(vec1.x, vec2.x), Mathf.Max(vec1.y, vec2.y), Mathf.Max(vec1.z, vec2.z));
    }

    //returns the Smallest Vector
    Vector3 Min(Vector3 vec1, Vector3 vec2)
    {
        return new Vector3(Mathf.Max(vec1.x, vec2.x), Mathf.Max(vec1.y, vec2.y), Mathf.Max(vec1.z, vec2.z));
    }

    //returns the Largest Vector
    Vector2 Max2(Vector2 vec1, Vector2 vec2)
    {
        return new Vector2(Mathf.Max(vec1.x, vec2.x), Mathf.Max(vec1.y, vec2.y));
    }

    //returns the Smallest Vector
    Vector2 Min2(Vector2 vec1, Vector2 vec2)
    {
        return new Vector2(Mathf.Max(vec1.x, vec2.x), Mathf.Max(vec1.y, vec2.y));
    }

    Vector3 Clamp(Vector3 vec, float min, float max)
    {
        return new Vector3(Mathf.Clamp(vec.x, min, max), Mathf.Clamp(vec.y, min, max), Mathf.Clamp(vec.z, min, max));
    }

    // rotate vector
    Vector3 RotateX(Vector3 p, float angle)
    {
        float c = Mathf.Cos(angle);
        float s = Mathf.Sin(angle);
        return new Vector3(p.x, c*p.y + s*p.z, -s*p.y + c*p.z);
    }
    Vector3 RotateY(Vector3 p, float angle)
    {
        float c = Mathf.Cos(angle);
        float s = Mathf.Sin(angle);
        return new Vector3(c*p.x - s*p.z, p.y, s*p.x + c*p.z);
    }
    Vector3 RotateZ(Vector3 p, float angle)
    {
        float c = Mathf.Cos(angle);
        float s = Mathf.Sin(angle);
        return new Vector3(c*p.x + s*p.y, -s*p.x + c*p.y, p.z);
    }

    // Sphere
    float sdSphere(Vector3 position, Vector3 origin, float radius)
    {
        return Vector3.Distance(position, origin) - radius;
    }

    // Infinate Plane
    // n.xyz: normal of the plane(normalized)
    // n.w: offset
    float sdPlane(Vector3 position, Vector4 n)
    {
        // n must be normalized
        return Vector3.Dot(position, new Vector3(n.x, n.y, n.z)) + n.w;
    }

    // Box
    // b: size of box in x/y/z
    float sdBox(Vector3 position, Vector3 origin, Vector3 b)
    {
        Vector3 d = Abs(position - origin) - b;
        return Mathf.Min(Mathf.Max(d.x, Mathf.Max(d.y, d.z)), 0.0f) + (Max(d, Vector3.zero).magnitude);
    }

    // Rounded Box
    // r: roundbox value
    float sdRoundBox(in Vector3 position, in Vector3 origin, in Vector3 b, in float r)
    {
        Vector3 q = Abs(position - origin) - b;
        return Mathf.Min(Mathf.Max(q.x, Mathf.Max(q.y, q.z)), 0.0f) + (Max(q, Vector3.zero).magnitude) - r;
    }
    
    // Torus
    // t.x: diameter
    // t.y: thickness
    float sdTorus(Vector3 position, Vector3 origin, Vector2 t)
    {
        Vector2 q = new Vector2((new Vector2(position.x, position.z).magnitude) - t.x, position.y) - new Vector2(origin.x, origin.y);
        return (q.magnitude) - t.y;
    }

    // BOOLEAN OPERATORS

    // Union
    Vector4 opU(Vector4 d1, Vector4 d2)
    {
        return (d1.w < d2.w) ? d1 : d2;
    }

    // Subtraction
    float opS(float d1, float d2)
    {
        return Mathf.Max(-d1, d2);
    }

    // Intersection
    float opI(float d1, float d2)
    {
        return Mathf.Max(d1, d2);
    }

    //modulor operator
    public float mod(float a, float n)
    {
        float halfsize = n / 2;
        //float result;
        /*
        if (a < 0)
        {
            result = -((-a + halfsize) % n - halfsize);
        }
        else result = (a + halfsize) % n - halfsize;
        */
        a = (a + halfsize) % n - halfsize;
        a = (a - halfsize) % n + halfsize;

        return a;
    }

    // Mod Position Axis
    public float pMod1 (float p, float size)
    {
        float halfsize = size * 0.5f;
        float c = Mathf.Floor((p+halfsize)/size);
        p = (p+halfsize % size)-halfsize;
        p = (-p+halfsize % size)-halfsize;
        return c;
    }

    // Displacement
    float opDisplace(in float primitive, in Vector3 p, in float dis)
    {
        float d1 = primitive;
        float d2 = Mathf.Sin(dis*p.x)*Mathf.Sin(dis*p.y)*Mathf.Sin(dis*p.z);
        return d1 + d2;
    }

    void sphereFold(ref Vector3 p, ref float dp, float fixedRadius2, float minRadius2)
    {
        float r2 = Vector3.Dot(p, p);
        if (r2 < minRadius2)
        {
            // Linear inner scaling
            float temp = (fixedRadius2 / minRadius2);
            p *= temp;
            dp *= temp; 
        }
        else if (r2 < fixedRadius2)
        {
            // This is the actual sphere inversion
            float temp = (fixedRadius2 / r2);
            p *= temp;
            dp *= temp;
        }
    }

    void boxFold(ref Vector3 p, ref float dp, float foldingLimit, float boxBreathe, float time)
    {
        p = Clamp(p + new Vector3(Mathf.Lerp(Mathf.Sin(time * boxBreathe), 0.0f, 1.2f), Mathf.Lerp(Mathf.Sin(time * boxBreathe), 0.0f, 1.2f), Mathf.Lerp(Mathf.Sin(time * boxBreathe), 0.0f, 1.2f)), -foldingLimit, foldingLimit) * 2.0f - p;
    }

    public float mandelboxSDF(Vector3 p, float scale, int iterations, float fixedRadius2, float minRadius2, float foldingLimit, float boxBreathe, float time)
    {
        Vector3 p0 = p;
        Vector3 offset = p;
        float dr = 1.0f;
        for (int i = 0; i < iterations; i++)
        {

            boxFold(ref p, ref dr, foldingLimit, boxBreathe, time);     // Reflect
            sphereFold(ref p, ref dr, fixedRadius2, minRadius2);  // Sphere Inversion

            p = scale * p + offset;     // Scale and Translate
            dr = dr * Mathf.Abs(scale) + 1.0f;

        }

        float r = p.magnitude;
        return r / Mathf.Abs(dr);
    }

    // ----------- //
    public float SmoothMin(float d1, float d2, float k)
    {
        float h = Mathf.Exp(-k * d1) + Mathf.Exp(-k * d2);
        return -Mathf.Log(h) / k;
    }

    public float CalcDistance(Vector3 pos, float scale, int iterations, float fixedRadius2, float minRadius2, float foldingLimit, float boxBreathe, float time, Vector3 sphereOrigin, float sphereRadius)
    {
        float d1 = mandelboxSDF(pos, scale, iterations, fixedRadius2, minRadius2, foldingLimit, boxBreathe, time);
        float d2 = sdSphere(pos, sphereOrigin, sphereRadius);
        return SmoothMin(d1, d2, 1f);
    }

    public Vector3 CalcNormal(Vector3 pos, float scale, int iterations, float fixedRadius2, float minRadius2, float foldingLimit, float boxBreathe, float time, Vector3 sphereOrigin, float sphereRadius)
    {
        var d = 0.01f;
        return new Vector3(
            CalcDistance(pos + new Vector3( d, 0f, 0f), scale, iterations, fixedRadius2, minRadius2, foldingLimit, boxBreathe, time, sphereOrigin, sphereRadius) - CalcDistance(pos + new Vector3(-d, 0f, 0f), scale, iterations, fixedRadius2, minRadius2, foldingLimit, boxBreathe, time, sphereOrigin, sphereRadius),
            CalcDistance(pos + new Vector3(0f,  d, 0f), scale, iterations, fixedRadius2, minRadius2, foldingLimit, boxBreathe, time, sphereOrigin, sphereRadius) - CalcDistance(pos + new Vector3(0f, -d, 0f), scale, iterations, fixedRadius2, minRadius2, foldingLimit, boxBreathe, time, sphereOrigin, sphereRadius),
            CalcDistance(pos + new Vector3(0f, 0f,  d), scale, iterations, fixedRadius2, minRadius2, foldingLimit, boxBreathe, time, sphereOrigin, sphereRadius) - CalcDistance(pos + new Vector3(0f, 0f, -d), scale, iterations, fixedRadius2, minRadius2, foldingLimit, boxBreathe, time, sphereOrigin, sphereRadius)).normalized;
    }
}

