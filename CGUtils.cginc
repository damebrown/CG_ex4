#ifndef CG_UTILS_INCLUDED
#define CG_UTILS_INCLUDED

#define PI 3.141592653

// A struct containing all the data needed for bump-mapping
struct bumpMapData
{ 
    float3 normal;       // Mesh surface normal at the point
    float3 tangent;      // Mesh surface tangent at the point
    float2 uv;           // UV coordinates of the point
    sampler2D heightMap; // Heightmap texture to use for bump mapping
    float du;            // Increment size for u partial derivative approximation
    float dv;            // Increment size for v partial derivative approximation
    float bumpScale;     // Bump scaling factor
};


// Receives pos in 3D cartesian coordinates (x, y, z)
// Returns UV coordinates corresponding to pos using spherical texture mapping
float2 getSphericalUV(float3 pos)
{
    float r = sqrt(pow(pos.x, 2) + pow(pos.y, 2) + pow(pos.z, 2));
    float t = atan2(pos.z, pos.x);
    float f = acos(pos.y / r);
    return float2(0.5 + t / (2 * PI), 1 - f / PI);
}

// Implements an adjusted version of the Blinn-Phong lighting model
fixed3 blinnPhong(float3 n, float3 v, float3 l, float shininess, fixed4 albedo, fixed4 specularity, float ambientIntensity)
{
    float3 h = normalize ((l + v) / 2);
    fixed3 ambient = ambientIntensity * albedo;
    fixed3 diffuse = max(0, dot(n, l)) * albedo;
    fixed3 Specular = pow(max(0, dot(n, h)), shininess) * specularity;
    return ambient + diffuse + Specular;
}

// Returns the world-space bump-mapped normal for the given bumpMapData
float3 getBumpMappedNormal(bumpMapData i)
{
    float p = tex2D(i.heightMap, i.uv);
    float u_derivative = (tex2D(i.heightMap, i.uv + float2(i.du, 0)) - p) / i.du;
    float v_derivative = (tex2D(i.heightMap, i.uv + float2(0, i.dv)) - p) / i.dv;
    float3 n_h = normalize (float3(-1 * i.bumpScale * float2(u_derivative, v_derivative), 1));
    float3 bitangent = cross(i.tangent, i.normal);
    return i.tangent * n_h.x + i.normal * n_h.z + bitangent * n_h.y;
}


#endif // CG_UTILS_INCLUDED
