// Upgrade NOTE: replaced 'defined LUMINANCE_GREEN' with 'defined (LUMINANCE_GREEN)'

Shader "_MyShaders/_CatlikeCoding/Advanced Rendering 2/3)FXAA"
{
    Properties 
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

	CGINCLUDE
		#include "UnityCG.cginc"

		sampler2D _MainTex;
		float4 _MainTex_TexelSize;

		float _SubpixelBlending, _ContrastThreshold, _RelativeThreshold;

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

		float4 Sample(float2 _uv)
		{
			return tex2Dlod(_MainTex, float4(_uv, 0, 0));
		}
		float SampleLuminance(float2 _uv)
		{
			#if defined (LUMINANCE_GREEN)
				return Sample(_uv).g;
			#else
				return Sample(_uv).a;
			#endif
		}
		float SampleLuminance(float2 _uv, float _uOffset, float _vOffset)
		{
			_uv += _MainTex_TexelSize * float2(_uOffset, _vOffset);
			return SampleLuminance(_uv);
		}

		struct LuminanceData
		{
			float m, n, e, s, w;
			float ne, nw, se, sw;
			float highest, lowest, contrast;
		};
		LuminanceData SampleLuminanceNeighborhood(float2 _uv)
		{
			LuminanceData l;
			l.m = SampleLuminance(_uv);
			l.n = SampleLuminance(_uv,  0,  1);
			l.e = SampleLuminance(_uv,  1,  0);
			l.s = SampleLuminance(_uv,  0, -1);
			l.w = SampleLuminance(_uv, -1,  0);
			
			l.ne = SampleLuminance(_uv,  1,  1);
			l.nw = SampleLuminance(_uv, -1,  1);
			l.se = SampleLuminance(_uv,  1, -1);
			l.sw = SampleLuminance(_uv, -1, -1);

			l.highest = max(max(max(max(l.n, l.e), l.s), l.w), l.m);
			l.lowest = min(min(min(min(l.n, l.e), l.s), l.w), l.m);
			l.contrast = l.highest - l.lowest;
			return l;
		}

		bool ShouldSkipPixel (LuminanceData l) 
		{
			float threshold =
				max(_ContrastThreshold, _RelativeThreshold * l.highest);
			return l.contrast < threshold;
		}

		float DeterminePixelBlendFactor (LuminanceData l) 
		{
			float filter = 2 * (l.n + l.e + l.s + l.w);
			filter += l.ne + l.nw + l.se + l.sw;
			filter *= 1.0 / 12;
			filter = abs(filter - l.m);
			filter = saturate(filter / l.contrast);

			float blendFactor = smoothstep(0, 1, filter);
			return blendFactor * blendFactor * _SubpixelBlending;
		}

        struct EdgeData
        {
            bool isHorizontal;
			float pixelStep;
        };
		EdgeData DetermineEdge (LuminanceData _l) 
		{
			EdgeData e;
			float horizontal = 
				abs(_l.n + _l.s - 2 * _l.m) * 2 +
				abs(_l.ne + _l.se - 2 * _l.e) +
				abs(_l.nw + _l.sw - 2 * _l.w);
			float vertical = 
				abs(_l.e + _l.w - 2 * _l.m) * 2 +
				abs(_l.ne + _l.nw - 2 * _l.n) +
				abs(_l.se + _l.sw - 2 * _l.s);
			e.isHorizontal = horizontal >= vertical;

			float pLuminance = e.isHorizontal ? _l.n : _l.e;
			float nLuminance = e.isHorizontal ? _l.s : _l.w;
			float pGradient = abs(pLuminance - _l.m);
			float nGradient = abs(nLuminance - _l.m);

			e.pixelStep =
				e.isHorizontal ? _MainTex_TexelSize.y : _MainTex_TexelSize.x;

			if (pGradient < nGradient) 
			{
				e.pixelStep = -e.pixelStep;
			}

			return e;
		}

		float4 ApplyFXAA (float2 _uv) 
		{
			LuminanceData l = SampleLuminanceNeighborhood(_uv);
			if (ShouldSkipPixel(l)) 
			{
				return Sample(_uv);
			}

			float pixelBlend = DeterminePixelBlendFactor(l);
			EdgeData e = DetermineEdge(l);
			if (e.isHorizontal) 
			{
				_uv.y += e.pixelStep * pixelBlend;
			}
			else 
			{
				_uv.x += e.pixelStep * pixelBlend;
			}
			return float4(Sample(_uv).rgb, l.m);
		}

	ENDCG

	SubShader 
	{
		Cull Off
		ZTest Always
		ZWrite Off

		Pass // 0 luminancePass
		{ 
			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				float4 FragmentProgram (Interpolators i) : SV_Target 
				{
					float4 sample = tex2D(_MainTex, i.uv);
					sample.a = LinearRgbToLuminance(saturate(sample.rgb));
					return sample;
				}
			ENDCG
		}
		Pass // 1 fxaaPass
		{ 
			CGPROGRAM
				#pragma vertex VertexProgram
				#pragma fragment FragmentProgram

				#pragma multi_compile __ LUMINANCE_GREEN

				float4 FragmentProgram (Interpolators i) : SV_Target 
				{
					return ApplyFXAA(i.uv);
				}
			ENDCG
		}
	}
}