#ifndef CG_RANDOM_INCLUDED
// Upgrade NOTE: excluded shader from DX11, OpenGL ES 2.0 because it uses unsized arrays
#pragma exclude_renderers d3d11 gles
// Upgrade NOTE: excluded shader from DX11 because it uses wrong array syntax (type[size] name)
#pragma exclude_renderers d3d11
#define CG_RANDOM_INCLUDED

// Returns a psuedo-random float between -1 and 1 for a given float c
float random(float c)
{
    return -1.0 + 2.0 * frac(43758.5453123 * sin(c));
}

// Returns a psuedo-random float2 with componenets between -1 and 1 for a given float2 c 
float2 random2(float2 c)
{
    c = float2(dot(c, float2(127.1, 311.7)), dot(c, float2(269.5, 183.3)));

    float2 v = -1.0 + 2.0 * frac(43758.5453123 * sin(c));
    return v;
}

// Returns a psuedo-random float3 with componenets between -1 and 1 for a given float3 c 
float3 random3(float3 c)
{
    float j = 4096.0 * sin(dot(c, float3(17.0, 59.4, 15.0)));
    float3 r;
    r.z = frac(512.0*j);
    j *= .125;
    r.x = frac(512.0*j);
    j *= .125;
    r.y = frac(512.0*j);
    r = -1.0 + 2.0 * r;
    return r.yzx;
}

// Interpolates a given array v of 4 float2 values using bicubic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
//
// [0]=====o==[1]
//         |
//         t
//         |
// [2]=====o==[3]
//
float bicubicInterpolation(float2 v[4], float2 t)
{
    float2 u = t * t * (3.0 - 2.0 * t); // Cubic interpolation

    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 4 float2 values using biquintic interpolation
// at the given ratio t (a float2 with components between 0 and 1)
float biquinticInterpolation(float2 v[4], float2 t)
{
    float2 u = 6 * pow(t, 5) - 15 * pow(t, 4) + 10 * pow(t, 3);
    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);

    // Interpolate in the y direction and return
    return lerp(x1, x2, u.y);
}

// Interpolates a given array v of 8 float3 values using triquintic interpolation
// at the given ratio t (a float3 with components between 0 and 1)
float triquinticInterpolation(float3 v[8], float3 t)
{
    float3 u = 6 * pow(t, 5) - 15 * pow(t, 4) + 10 * pow(t, 3);
    // Interpolate in the x direction
    float x1 = lerp(v[0], v[1], u.x);
    float x2 = lerp(v[2], v[3], u.x);
    float y1 = lerp(x1, x2, u.y);

    float x3 = lerp(v[4], v[5], u.x);
    float x4 = lerp(v[6], v[7], u.x);
    float y2 = lerp(x3, x4, u.y);

    // Interpolate in the y direction and return
    return lerp(y1, y2, u.z);
}

// Returns the value of a 2D value noise function at the given coordinates c
float value2d(float2 c)
{
    float2 v[4];
    v[0] = random2(float2(int(c.x), int(c.y)));
    v[1] = random2(float2(int(c.x)+1, int(c.y)));
    v[2] = random2(float2(int(c.x), int(c.y)+1));
    v[3] = random2(float2(int(c.x) + 1, int(c.y) + 1));
    return bicubicInterpolation(v, c - int2(c));
}

// Returns the value of a 2D Perlin noise function at the given coordinates c
float perlin2d(float2 c)
{
    float2 v[4];

    v[0] = float2(int(c.x), int(c.y));
    v[1] = float2(int(c.x) + 1, int(c.y));
    v[2] = float2(int(c.x), int(c.y) + 1);
    v[3] = float2(int(c.x) + 1, int(c.y) + 1);

    v[0] = dot(random2(v[0]), v[0] -c);
    v[1] = dot(random2(v[1]), v[1] -c);
    v[2] = dot(random2(v[2]), v[2] -c);
    v[3] = dot(random2(v[3]), v[3] -c);
    
    return biquinticInterpolation(v, c - int2(c));
}

// Returns the value of a 3D Perlin noise function at the given coordinates c
float perlin3d(float3 c)
{
    float3 v[8];
    v[0] = float3(int(c.x), int(c.y), int(c.z));
    v[1] = float3(int(c.x) + 1, int(c.y), int(c.z));
    v[2] = float3(int(c.x), int(c.y) + 1, int(c.z));
    v[3] = float3(int(c.x) + 1, int(c.y) + 1, int(c.z));
    v[4] = float3(int(c.x), int(c.y), int(c.z) + 1);
    v[5] = float3(int(c.x) + 1, int(c.y), int(c.z) + 1);
    v[6] = float3(int(c.x), int(c.y) + 1, int(c.z) + 1);
    v[7] = float3(int(c.x) + 1, int(c.y) + 1, int(c.z) + 1);

    v[0] = dot(random3(v[0]), v[0] - c);
    v[1] = dot(random3(v[1]), v[1] - c);
    v[2] = dot(random3(v[2]), v[2] - c);
    v[3] = dot(random3(v[3]), v[3] - c);
    v[4] = dot(random3(v[4]), v[4] - c);
    v[5] = dot(random3(v[5]), v[5] - c);
    v[6] = dot(random3(v[6]), v[6] - c);
    v[7] = dot(random3(v[7]), v[7] - c);

    return triquinticInterpolation(v, c - int3(c));
}


#endif // CG_RANDOM_INCLUDED
