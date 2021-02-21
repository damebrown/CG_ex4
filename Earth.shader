Shader "CG/Earth"
{
    Properties
    {
        [NoScaleOffset] _AlbedoMap ("Albedo Map", 2D) = "defaulttexture" {}
        _Ambient ("Ambient", Range(0, 1)) = 0.15
        [NoScaleOffset] _SpecularMap ("Specular Map", 2D) = "defaulttexture" {}
        _Shininess ("Shininess", Range(0.1, 100)) = 50
        [NoScaleOffset] _HeightMap ("Height Map", 2D) = "defaulttexture" {}
        _BumpScale ("Bump Scale", Range(1, 100)) = 30
        [NoScaleOffset] _CloudMap ("Cloud Map", 2D) = "black" {}
        _AtmosphereColor ("Atmosphere Color", Color) = (0.8, 0.85, 1, 1)
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

                #pragma vertex vert
                #pragma fragment frag
                #include "UnityCG.cginc"
                #include "CGUtils.cginc"

                // Declare used properties
                uniform sampler2D _AlbedoMap;
                uniform float _Ambient;
                uniform sampler2D _SpecularMap;
                uniform float _Shininess;
                uniform sampler2D _HeightMap;
                uniform float4 _HeightMap_TexelSize;
                uniform float _BumpScale;
                uniform sampler2D _CloudMap;
                uniform fixed4 _AtmosphereColor;

                struct appdata
                { 
                    float4 vertex : POSITION;
                };

                struct v2f
                {
                    float4 pos : SV_POSITION;
                    float3 vertex       : TEXCOORD0;
                };

                v2f vert (appdata input)
                {
                    v2f output;
                    output.pos = UnityObjectToClipPos(input.vertex);
                    output.vertex = input.vertex;
                    return output;
                }

                fixed4 frag(v2f input) : SV_Target
                {
                    float2 suv = getSphericalUV(input.vertex);
                    float3 base_normal = normalize(mul(unity_ObjectToWorld, input.vertex));
                    bumpMapData bmd = {base_normal, cross(input.vertex, float3(0,1,0)) , suv, _HeightMap, _HeightMap_TexelSize.x, _HeightMap_TexelSize.y, _BumpScale / 10000 };
                    float3 final_normal = ((1 - tex2D(_SpecularMap, suv)) * getBumpMappedNormal(bmd)) + (tex2D(_SpecularMap, suv) * base_normal);
                    float3 v = _WorldSpaceCameraPos - input.vertex;
                    float sqrt_lambert = sqrt(max(0, dot(base_normal, _WorldSpaceLightPos0.xyz)));
                    fixed4 blinn_phong = fixed4(blinnPhong(final_normal, v, _WorldSpaceLightPos0.xyz, _Shininess, tex2D(_AlbedoMap, suv), tex2D(_SpecularMap, suv), _Ambient), 1);
                    fixed4 atmosfire = (1 - max(0, dot(base_normal,v))) * sqrt_lambert * _AtmosphereColor;
                    fixed4 clouds = tex2D(_CloudMap, suv) * (sqrt_lambert + _Ambient);
                    return blinn_phong + atmosfire + clouds;
                }

            ENDCG
        }
    }
}
