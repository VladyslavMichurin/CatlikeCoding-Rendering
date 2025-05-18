Shader "_MyShaders/_CatlikeCoding/Advanced Rendering 2/1)Bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }

    CGINCLUDE
		#include "UnityCG.cginc"

		sampler2D _MainTex, _SourceTex;
        float4 _MainTex_TexelSize;
        half4 _Filter;
        half _Intensity;

		struct VertexData 
        {
			float4 vertex : POSITION;
			float2 uv : TEXCOORD0;
		};

		struct Interpolators 
        {
			float4 pos : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		Interpolators VertexProgram (VertexData v) 
        {
			Interpolators i;
			i.pos = UnityObjectToClipPos(v.vertex);
			i.uv = v.uv;
			return i;
		}

        half3 Sample (float2 _UV)
        {
            return tex2D(_MainTex, _UV).rgb;
        }
        half3 SampleBox (float2 _UV, float _delta)
        {
            float4 o = _MainTex_TexelSize.xyxy * float2(_delta, -_delta).xxyy;
            half3 s =
				Sample(_UV + o.xy) + Sample(_UV + o.xw) +
				Sample(_UV + o.zy) + Sample(_UV + o.zw);
            return s * 0.25f;
        }

        half3 Prefilter (half3 _color) 
        {
            half brightness = max(_color.r, max(_color.g, _color.b));
			half soft = brightness - _Filter.y;

			soft = clamp(soft, 0, _Filter.z);
			soft = soft * soft * _Filter.w;

			half contribution = max(soft, brightness - _Filter.x);
			contribution /= max(brightness, 0.00001);
			
            return _color * contribution;
		}

	ENDCG

    SubShader
    {
        Cull Off
        ZTest Always
        ZWrite Off
        
        Pass
        {
            Name "Prefilter"

            CGPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            
            half4 FragmentProgram(Interpolators i) : SV_TARGET
            {
                return half4(Prefilter(SampleBox(i.uv, 1)), 1);
            }

            ENDCG
        }

        Pass
        {
            Name "Downsampling"

            CGPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            
            half4 FragmentProgram(Interpolators i) : SV_TARGET
            {
                return half4(SampleBox(i.uv, 1), 1);
            }

            ENDCG
        }

        Pass
        {
            Name "Upsampling"

            Blend One One

            CGPROGRAM
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram
            
            half4 FragmentProgram(Interpolators i) : SV_TARGET
            {
                return half4(SampleBox(i.uv, 0.5), 1);
            }

            ENDCG
        }

        Pass 
        { 

            Name "Bloom"

			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				half4 FragmentProgram (Interpolators i) : SV_Target 
                {
					half4 c = tex2D(_SourceTex, i.uv);
					c.rgb += _Intensity * SampleBox(i.uv, 0.5);
					return c;
				}
			ENDCG
		}

        Pass 
        { 
            Name "Debug"

			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				half4 FragmentProgram (Interpolators i) : SV_Target 
                {
					return half4(_Intensity * SampleBox(i.uv, 0.5), 1);
				}
			ENDCG
		}
    }
}
