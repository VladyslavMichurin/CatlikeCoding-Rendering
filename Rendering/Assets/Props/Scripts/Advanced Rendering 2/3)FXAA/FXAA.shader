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

		bool ShouldSkipPixel (LuminanceData _l) 
		{
			float threshold =
				max(_ContrastThreshold, _RelativeThreshold * _l.highest);
			return _l.contrast < threshold;
		}

		float DeterminePixelBlendFactor (LuminanceData _l) 
		{
			float filter = 2 * (_l.n + _l.e + _l.s + _l.w);
			filter += _l.ne + _l.nw + _l.se + _l.sw;
			filter *= 1.0 / 12;
			filter = abs(filter - _l.m);
			filter = saturate(filter / _l.contrast);

			float blendFactor = smoothstep(0, 1, filter);
			return blendFactor * blendFactor * _SubpixelBlending;
		}

        struct EdgeData
        {
            bool isHorizontal;
			float pixelStep;
			float oppositeLuminance, gradient;
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
				e.oppositeLuminance = nLuminance;
				e.gradient = nGradient;
			}
			else
			{
				e.oppositeLuminance = pLuminance;
				e.gradient = pGradient;
			}

			return e;
		}

		#if defined(LOW_QUALITY)
			#define EDGE_STEP_COUNT 4
			#define EDGE_STEPS 1, 1.5, 2, 4
			#define EDGE_GUESS 12
		#else
			#define EDGE_STEP_COUNT 10
			#define EDGE_STEPS 1, 1.5, 2, 2, 2, 2, 2, 2, 2, 4
			#define EDGE_GUESS 8
		#endif

		static const float edgeSteps[EDGE_STEP_COUNT] = { EDGE_STEPS };

		float DetermineEdgeBlendFactor (LuminanceData _l, EdgeData _e, float2 _uv)
		{
			float2 uvEdge = _uv;
			float2 edgeStep;
			if(_e.isHorizontal)
			{
				uvEdge.y += _e.pixelStep * 0.5;
				edgeStep = float2(_MainTex_TexelSize.x, 0);
			}
			else
			{
				uvEdge.x += _e.pixelStep * 0.5;
				edgeStep = float2(0, _MainTex_TexelSize.y);
			}

			float edgeLuminance = (_l.m + _e.oppositeLuminance) * 0.5;
			float gradientThreshold = _e.gradient * 0.25;
			

			// Positive Distance
			//////////////////////////////////////////////////////////////////
			float2 puv = uvEdge + edgeStep * edgeSteps[0];
			float pLuminanceDelta = SampleLuminance(puv) - edgeLuminance;
			bool pAtEnd = abs(pLuminanceDelta) >= gradientThreshold;

			UNITY_UNROLL
            for (int i = 1; i < EDGE_STEP_COUNT && !pAtEnd; i++) 
			{
				puv += edgeStep * edgeSteps[i];
				pLuminanceDelta = SampleLuminance(puv) - edgeLuminance;
				pAtEnd = abs(pLuminanceDelta) >= gradientThreshold;
			}
			if(!pAtEnd)
			{
				puv += edgeStep * EDGE_GUESS;
			}
			
			// Negative Distance
			//////////////////////////////////////////////////////////////////
			float2 nuv = uvEdge - edgeStep * edgeSteps[0];
			float nLuminanceDelta = SampleLuminance(nuv) - edgeLuminance;
			bool nAtEnd = abs(nLuminanceDelta) >= gradientThreshold;

			UNITY_UNROLL
            for (int i = 1; i < EDGE_STEP_COUNT && !nAtEnd; i++) 
			{
				nuv -= edgeStep * edgeSteps[i];
				nLuminanceDelta = SampleLuminance(nuv) - edgeLuminance;
				nAtEnd = abs(nLuminanceDelta) >= gradientThreshold;
			}
			if(!pAtEnd)
			{
				nuv -= edgeStep * EDGE_GUESS;
			}

			// Finalizing Distance
			//////////////////////////////////////////////////////////////////
			float pDistance, nDistance;
			if(_e.isHorizontal)
			{
				pDistance = puv.x - _uv.x;
				nDistance = _uv.x - nuv.x;
			}
			else
			{
				pDistance = puv.y - _uv.y;
				nDistance = _uv.y - nuv.y;
			}

			float shortestDistance = pDistance;
			bool deltaSign = pLuminanceDelta > 0;
			if(pDistance > nDistance)
			{
				shortestDistance = nDistance;
				deltaSign = nLuminanceDelta > 0;
			}

			if (deltaSign == (_l.m - edgeLuminance >= 0)) {
				return 0;
			}

			return 0.5 - shortestDistance / (pDistance + nDistance);
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
			float edgeBlend = DetermineEdgeBlendFactor(l, e, _uv);
			float finalBlend = max(pixelBlend, edgeBlend);

			if (e.isHorizontal) 
			{
				_uv.y += e.pixelStep * finalBlend;
			}
			else 
			{
				_uv.x += e.pixelStep * finalBlend;
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
					sample.rgb = saturate(sample.rgb);
					sample.a = LinearRgbToLuminance(sample.rgb);
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
				#pragma multi_compile __ LOW_QUALITY
				#pragma multi_compile _ GAMMA_BLENDING

				float4 FragmentProgram (Interpolators i) : SV_Target 
				{
					float4 sample = ApplyFXAA(i.uv);
					#if defined(GAMMA_BLENDING)
						sample.rgb = GammaToLinearSpace(sample.rgb);
					#endif
					return sample;
				}
			ENDCG
		}
	}
}