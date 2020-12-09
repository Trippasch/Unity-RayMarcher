#define pi 3.1415926535897932384626433832795

// GLSL compatible mod()
float  modc(float  a, float  b) { return a - b * floor(a/b); }
float2 modc(float2 a, float2 b) { return a - b * floor(a/b); }
float3 modc(float3 a, float3 b) { return a - b * floor(a/b); }
float4 modc(float4 a, float4 b) { return a - b * floor(a/b); }

// rotate vector
float3 RotateX(float3 p, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3(p.x, c*p.y + s*p.z, -s*p.y + c*p.z);
}
float3 RotateY(float3 p, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3(c*p.x - s*p.z, p.y, s*p.x + c*p.z);
}
float3 RotateZ(float3 p, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3(c*p.x + s*p.y, -s*p.x + c*p.y, p.z);
}

float3 BounceY(float3 v, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3(v.x, s * 4 + v.y - 1, v.z);
}

float3 BounceX(float3 v, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3(sin(angle + (3 * 3.14) * 0.5) * 5 + v.x, v.y, v.z);
}

float3 BounceX3(float3 v, float angle)
{
    float s, c;
    sincos(angle, s, c);
    return float3(sin(angle + (3.14) * 0.5) * 5 + v.x, v.y, v.z);
}

// glowline pattern
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

// Sphere
float sdSphere(float3 position, float3 origin, float radius)
{
    return distance(position, origin) - radius;
}

// Infinate Plane
// n.xyz: normal of the plane(normalized)
// n.w: offset
float sdPlane(float3 position, float4 n)
{
    // n must be normalized
    return dot(position, n.xyz) + n.w;

}

// Box
// b: size of box in x/y/z
float sdBox(float3 position, float3 origin, float3 b)
{
    float3 d = abs(position - origin) - b;
    return min(max(d.x, max(d.y, d.z)), 0.0) + length(max(d, 0.0));
}

// Rounded Box
// r: roundbox value
float sdRoundBox(in float3 position, in float3 origin, in float3 b, in float r)
{
    float3 q = abs(position - origin) - b;
    return min(max(q.x, max(q.y, q.z)), 0.0) + length(max(q, 0.0)) - r;
}

// Torus
// t.x: diameter
// t.y: thickness
float sdTorus(float3 position, float3 origin, float2 t)
{
    float2 q = float2(length(position.xz) - t.x, position.y) - origin;
    return length(q) - t.y;
}

// BOOLEAN OPERATORS

// Union
float4 opU(float4 d1, float4 d2)
{
    return (d1.w < d2.w) ? d1 : d2;
}

// Subtraction
float opS(float d1, float d2)
{
    return max(-d1, d2);
}

// Intersection
float opI(float d1, float d2)
{
    return max(d1, d2);
}

// SMOOTH BOOLEAN OPERATORS

float4 opUS(float4 d1, float4 d2, float k)
{
    float h = clamp(0.5 + 0.5 * (d2.w - d1.w) / k, 0.0, 1.0);
    float3 color = lerp(d2.rgb, d1.rgb, h);
    float dist = lerp(d2.w, d1.w, h) - k * h * (1.0 - h);
    return float4(color, dist);
}

float4 opSS(float4 d1, float4 d2, float k)
{
    float4 h = clamp(0.5 - 0.5 * (d2.w + d1.w) / k, 0.0, 1.0);
    float3 color = lerp(d2.rgb, d1.rgb, h);
    float dist = lerp(d2.w, -d1.w, h) + k * h * (1.0 - h);
    return float4(color, dist);
}

float4 opIS(float4 d1, float4 d2, float k)
{
    float h = clamp(0.5 - 0.5 * (d2.w - d1.w) / k, 0.0, 1.0);
    float3 color = lerp(d2.rgb, d1.rgb, h);
    float dist = lerp(d2.w, d1.w, h) + k * h * (1.0 - h);
    return float4(color, dist);
}

// Mod Position Axis
float pMod1 (inout float p, float size)
{
    float halfsize = size * 0.5;
    float c = floor((p+halfsize)/size);
    p = fmod(p+halfsize,size)-halfsize;
    p = fmod(-p+halfsize,size)-halfsize;
    return c;
}

// Displacement
float opDisplace(in float primitive, in float3 p, in float dis)
{
    float d1 = primitive;
    float d2 = sin(dis*p.x)*sin(dis*p.y)*sin(dis*p.z);
    return d1 + d2;
}

// Twist
float3 opTwist(in float3 p, in float twist)
{
    float c = cos(twist * p.y);
    float s = sin(twist * p.y);
    float2x2 m = float2x2(c, -s, s, c);
    float3 q = float3(mul(m, p.xz), p.y);
    return q;
}

// Onion
float opOnion(in float sdf, in float thickness)
{
    return abs(sdf) - thickness;
}

float mandelbulbSDF(float3 p, out float4 resColor, float power, int iterations, inout float glow)
{
	// p.xyz = (p.xyz - origin.xyz) * origin.w * 0.5;
	float3 z = p;
	float3 dz = float3(0.0, 0.0, 0.0);
	float theta, phi;
    float r = dot(z, z);
	float dr = 1.0;
    float4 trap = float4(abs(z), r);

	float t0 = 1.0;
	for(int i = 0; i < iterations; ++i) {
		r = length(z);
		if (r > 2.0) continue;
		theta = atan(z.y / z.x);
        // #ifdef phase_shift_on
		phi = asin(z.z / r) + _Time * 2;
        // #else
        // phi = asin(z.z / r);
        // #endif
		
		dr = pow(r, power - 1.0) * dr * power + 1.0;
	
		r = pow(r, power);
		theta = theta * power;
		phi = phi * power;
		
		z = r * float3(cos(theta)*cos(phi), sin(theta)*cos(phi), sin(phi)) + p;
		
        trap = min(trap, float4(abs(z), r));
		t0 = min(t0, r);
        glow += clamp(0.05 / abs(z.z + sin((i * pi / 20.0)) * 0.8), 0.0, 1.0);
	}
    
    resColor = float4(sqrt(r), trap.yzw);

	return float3(0.5 * log(r) * r / dr, t0, 0.0);
}

void sphereFold(inout float3 p, inout float dp, float fixedRadius2, float minRadius2)
{
    float r2 = dot(p, p);
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

void boxFold(inout float3 p, inout float dp, float foldingLimit, float boxBreathe, out float time)
{
    time = _Time.y;
    p = clamp(p + lerp(sin(time * boxBreathe), 0.0, 1.2), -foldingLimit, foldingLimit) * 2.0 - p;
}

float mandelboxSDF(float3 p, float scale, int iterations, float fixedRadius2, float minRadius2, float foldingLimit, inout float trap, inout float glow, float boxBreathe, out float time)
{
    float3 p0 = p;
    trap = dot(p + p0, p + p0) + dot(p, p);
    float3 offset = p;
    float dr = 1.0;
    for (int i = 0; i < iterations; i++)
    {
        glow += clamp(2.05 / abs(p.z + sin((i * pi / 20.0)) * 0.8), 0.0, 1.0);

        boxFold(p, dr, foldingLimit, boxBreathe, time);     // Reflect
        sphereFold(p, dr, fixedRadius2, minRadius2);  // Sphere Inversion

        trap = min(trap, dot(p + p0, p + p0) + dot(p, p));

        p = scale * p + offset;     // Scale and Translate
        dr = dr * abs(scale) + 1.0;

    }

    float r = length(p);
    return r / abs(dr);
}

float hartverdrahtet(float3 f)
{
    float3 cs=float3(.808,.808,1.167);
    float fs=1.;
    float3 fc=0;
    float fu=10.;
    float fd=.763;
    
    // scene selection
    {
        // float time = _Time.y;
        // int i = int(modc(time/2.0, 9.0));
        int i = 8;
        if(i==0) cs.y=.58;
        if(i==1) cs.xy=.5;
        if(i==2) cs.xy=.5;
        if(i==3) fu=1.01,cs.x=.9;
        if(i==4) fu=1.01,cs.x=.9;
        if(i==6) cs=float3(.5,.5,1.04);
        if(i==5) fu=.9;
        if(i==7) fd=.7,fs=1.34,cs.xy=.5;
        if(i==8) fc.z=-.38;
    }
    
    //cs += sin(time)*0.2;

    float v=1.;
    for(int i=0; i<12; i++){
        f=2.*clamp(f,-cs,cs)-f;
        float c=max(fs/dot(f,f),1.);
        f*=c;
        v*=c;
        f+=fc;
    }
    float z=length(f.xy)-fu;
    return fd*max(z,abs(length(f.xy)*f.z)/sqrt(dot(f,f)))/abs(v);
}

float kaleidoscopic_IFS(float3 z)
{
    int FRACT_ITER      = 20;
    float FRACT_SCALE   = 1.8;
    float FRACT_OFFSET  = 1.0;

    float c = 2.0;
    z.y = modc(z.y, c)-c/2.0;
    z = RotateZ(z, pi/2.0);
    float r;
    int n1 = 0;
    for (int n = 0; n < FRACT_ITER; n++) {
        float rotate = pi*0.5;
        z = RotateX(z, rotate);
        z = RotateY(z, rotate);
        z = RotateZ(z, rotate);

        z.xy = abs(z.xy);
        if (z.x+z.y<0.0) z.xy = -z.yx; // fold 1
        if (z.x+z.z<0.0) z.xz = -z.zx; // fold 2
        if (z.y+z.z<0.0) z.zy = -z.yz; // fold 3
        z = z*FRACT_SCALE - FRACT_OFFSET*(FRACT_SCALE-1.0);
    }
    return (length(z) ) * pow(FRACT_SCALE, -float(FRACT_ITER));
}

float pseudo_kleinian(float3 p)
{
    float3 CSize = float3(0.92436,0.90756,0.92436);
    float Size = 1.0;
    float3 C = float3(0.0,0.0,0.0);
    float DEfactor=1.;
    float3 Offset = float3(0.0,0.0,0.0);
    float3 ap=p+1.;
    for(int i=0;i<10 ;i++){
        ap=p;
        p=2.*clamp(p, -CSize, CSize)-p;
        float r2 = dot(p,p);
        float k = max(Size/r2,1.);
        p *= k;
        DEfactor *= k + 0.05;
        p += C;
    }
    float r = abs(0.5*abs(p.z-Offset.z)/DEfactor);
    return r;
}

float pseudo_knightyan(float3 p)
{
    float3 CSize = float3(0.63248,0.78632,0.875);
    float DEfactor=1.;
    for(int i=0;i<6;i++){
        p = 2.*clamp(p, -CSize, CSize)-p;
        float k = max(0.70968/dot(p,p),1.);
        p *= k;
        DEfactor *= k + 0.05;
    }
    float rxy=length(p.xy);
    return max(rxy-0.92784, abs(rxy*p.z) / length(p))/DEfactor;
}

float tglad_formula(float3 z0)
{
    z0 = modc(z0, 2.0);

    float mr=0.25, mxr=1.0;
    float4 scale=float4(-3.12,-3.12,-3.12,3.12), p0=float4(0.0,1.59,-1.0,0.0);
    float4 z = float4(z0,1.0);
    for (int n = 0; n < 3; n++) {
        z.xyz=clamp(z.xyz, -0.94, 0.94)*2.0-z.xyz;
        z*=scale/clamp(dot(z.xyz,z.xyz),mr,mxr);
        z+=p0;
    }
    float dS=(length(max(abs(z.xyz)-float3(1.2,49.0,1.4),0.0))-0.06)/z.w;
    return dS;
}