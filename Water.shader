Shader "CG/Water"
{
    Properties
    {
        _CubeMap("Reflection Cube Map", Cube) = "" {}
        _NoiseScale("Texture Scale", Range(1, 100)) = 10 
        _TimeScale("Time Scale", Range(0.1, 5)) = 3 
        _BumpScale("Bump Scale", Range(0, 0.5)) = 0.05
    }
    SubShader
    {
        Pass
        {
            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"
                #include "CGRandom.cginc"

                #define DELTA 0.01

                // Declare used properties
                uniform samplerCUBE _CubeMap;
                uniform float _NoiseScale;
                uniform float _TimeScale;
                uniform float _BumpScale;

                struct appdata
                { 
                    float4 vertex   : POSITION;
                    float3 normal   : NORMAL;
                    float4 tangent  : TANGENT;
                    float2 uv       : TEXCOORD0;
                };

                struct v2f
                {
                    float4 pos      : SV_POSITION;
                    float2 uv       : TEXCOORD0;
                    float3 w_vertex : TEXCOORD1;
                    float3 normal   : NORMAL;
                    float3 tangent  : TANGENT;
                };

                // Returns the value of a noise function simulating water, at coordinates uv and time t
                float waterNoise(float2 uv, float t)
                {
                    return (perlin3d(float3(0.5 * (uv.x), 0.5 * (uv.y), 0.5 * t))) + (0.5 * perlin3d(float3(uv.x, uv.y, t))) + (0.2 * perlin3d(float3(2 * uv.x, 2 * uv.y, 3 * t)));
                }

                // Returns the world-space bump-mapped normal for the given bumpMapData and time t
                float3 getWaterBumpMappedNormal(bumpMapData i, float t)
                {
                    float p = waterNoise(i.uv, t);
                    float u_derivative = ((waterNoise(i.uv + float2(i.du, 0), t)) - p) / i.du;
                    float v_derivative = ((waterNoise(i.uv + float2(0, i.dv), t)) - p) / i.dv;
                    float3 n_h = normalize(float3(-1 * i.bumpScale * float2(u_derivative, v_derivative), 1));
                    float3 bitangent = cross(i.tangent, i.normal);
                    return i.tangent * n_h.x + i.normal * n_h.z + bitangent * n_h.y;
                }


                v2f vert (appdata input)
                {
                    v2f output;
                    input.vertex = input.vertex + (waterNoise(input.uv * _NoiseScale, _Time.y * _TimeScale)) * _BumpScale * float4(input.normal,1);
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.uv = input.uv;
                    output.w_vertex = mul(unity_ObjectToWorld, input.vertex);
                    output.normal = normalize(mul(unity_ObjectToWorld, input.normal));
                    output.tangent = normalize(mul(unity_ObjectToWorld, input.tangent.xyz));
                    return output;
                }

                fixed4 frag(v2f input) : SV_Target
                {
                    float3 v = normalize(_WorldSpaceCameraPos - input.w_vertex);
                    bumpMapData bmd; 
                    bmd.normal = input.normal;
                    bmd.tangent = input.tangent;
                    bmd.uv = input.uv* _NoiseScale;
                    bmd.du = DELTA;
                    bmd.dv = DELTA;
                    bmd.bumpScale = _BumpScale;

                    float3 bm_normal = getWaterBumpMappedNormal(bmd, _Time.y*_TimeScale);
                    float3 r = 2 * (dot(v, bm_normal)) * bm_normal - v;
                    float3 reflected_color = texCUBE(_CubeMap, r);
                    return fixed4((1 - max(0, dot(v, bm_normal)) + 0.2) * reflected_color,1);
                }

            ENDCG
        }
    }
}
