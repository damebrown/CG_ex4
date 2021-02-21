Shader "CG/Bonus"
//CORONA SHADER
{
    Properties
    {
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

                float perlin3d2(float3 c)
                {
                    float3 v[8];
                    v[0] = float3(int(c.x), int(c.y), int(c.z));
                    v[1] = float3(int(c.x) + 1, int(c.y), int(c.z));
                    v[2] = float3(int(c.x), int(c.y) + 1, int(c.z));
                    v[3] = float3(int(c.x) + 1, int(c.y) + 1, int(c.z));
                    v[7] = float3(int(c.x), int(c.y), int(c.z) + 1);
                    v[5] = float3(int(c.x) + 1, int(c.y), int(c.z) + 1);
                    v[6] = float3(int(c.x), int(c.y) + 1, int(c.z) + 1);
                    v[4] = float3(int(c.x) + 1, int(c.y) + 1, int(c.z) + 1);

                    v[3] = dot(random3(v[0]), v[0] - c);
                    v[5] = dot(random3(v[1]), v[1] - c);
                    v[2] = dot(random3(v[2]), v[2] - c);
                    v[0] = dot(random3(v[3]), v[3] - c);
                    v[4] = dot(random3(v[4]), v[4] - c);
                    v[1] = dot(random3(v[5]), v[5] - c);
                    v[6] = dot(random3(v[6]), v[6] - c);
                    v[7] = dot(random3(v[7]), v[7] - c);

                    return triquinticInterpolation(v, c - int3(c));
                }

                float coronaNoise(float2 uv, float t)
                {
                    return (perlin3d2(float3(0.5 * (uv.x), 0.5 * (uv.y), 0.5 * t))) + (0.5 * perlin3d(float3(uv.x, uv.y, t))) + (0.2 * perlin3d(float3(2 * uv.x, 2 * uv.y, 3 * t)));
                }

                float3 getcoronaBumpMappedNormal(bumpMapData i, float t)
                {
                    float p = coronaNoise(i.uv, t);
                    float u_derivative = ((coronaNoise(i.uv + float2(i.du, 0), t)) - p) / i.du;
                    float v_derivative = ((coronaNoise(i.uv + float2(0, i.dv), t)) - p) / i.dv;
                    float3 n_h = normalize(float3(-1 * i.bumpScale * float2(u_derivative, v_derivative), 1));
                    float3 bitangent = cross(i.tangent, i.normal);
                    return i.tangent * n_h.x + i.normal * n_h.z + bitangent * n_h.y;
                }

                v2f vert (appdata input)
                {
                    v2f output;
                    input.vertex = input.vertex + (coronaNoise(input.uv * _NoiseScale, _Time.y * _TimeScale)) * _BumpScale * float4(input.normal, 1);
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.uv = input.uv;
                    output.w_vertex = mul(unity_ObjectToWorld, input.vertex);
                    output.normal = normalize(mul(unity_ObjectToWorld, input.normal));
                    output.tangent = normalize(mul(unity_ObjectToWorld, input.tangent.xyz));
                    return output;
                }

                fixed4 frag (v2f input) : SV_Target
                {                    
                    float3 v = normalize(_WorldSpaceCameraPos - input.w_vertex);
                    bumpMapData bmd;
                    bmd.normal = input.normal;
                    bmd.tangent = input.tangent;
                    bmd.uv = input.uv * _NoiseScale;
                    bmd.du = DELTA;
                    bmd.dv = DELTA;
                    bmd.bumpScale = _BumpScale;

                    float3 bm_normal = getcoronaBumpMappedNormal(bmd, _Time.y * _TimeScale);
                    return fixed4(blinnPhong(bm_normal, v, _WorldSpaceLightPos0.xyz, 1, float4(0.7,10,0.2,1), float4(0.1, 0.1, 0.1, 1), 0.1), 1);
                }

            ENDCG
        }
    }
}
