Shader "ShadersMadeByVlad/_Acerola/InktoberShader"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _PaperTex ("Paper Texture", 2D) = "white" {}
        _NoiseTex ("Noise Texture", 2D) = "white" {}

         _HighThreshold ("Upper Treshold for Double threshold step ", Range(0,1)) = 1
         _LowThreshold ("Lower Treshold for Double threshold step ", Range(0,1)) = 0

         _EdgeOppacity ("Edge Oppacity", Range(0,1)) = 1
         _EdgeBrightness ("Edge Brightness", Range(0,1)) = 1
         _LumUpperThreshold ("Luminance Upper Treshold", Range(-1,1)) = 1
         _LumLowerThreshold ("Luminance Lower Treshold", Range(-1,1)) = 1
    }
    SubShader
    {
        Tags 
        { 
            "RenderType"="Opaque" 
        }
        
        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 noiseUV : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST, _MainTex_TexelSize;

            sampler2D _PaperTex;

             sampler2D _NoiseTex;
            float4 _NoiseTex_ST;


            float _HighThreshold, _LowThreshold;

            float _EdgeBrightness, _EdgeOppacity, _LumUpperThreshold, _LumLowerThreshold;

            v2f vert (appdata v)
            {
                v2f o;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.noiseUV = TRANSFORM_TEX(v.uv, _NoiseTex);

                return o;
            }

            fixed4 GrayScale(float3 _tex)
            {
                fixed3 toReturn = _tex;

               float GreyScaleValue = 0.299 * toReturn.r + 0.587 * toReturn.g + 0.114  * toReturn.b;

                toReturn = fixed3(GreyScaleValue, GreyScaleValue, GreyScaleValue);              

                return fixed4(toReturn, 1);
            }

            float4 Blur( float2 _uv)
            {
                float GaussianKernel[25] = { 1, 4, 7, 4, 1,
                                             4, 16, 26, 16, 4,
                                             7, 26, 41, 26, 7,
                                             4, 16, 26, 16, 4,
                                             1, 4, 7, 4, 1};
            
                float R = 0.0f;
                float G = 0.0f;
                float B = 0.0f;

                for (int x = -2; x < 2; ++x) 
                {
                    for (int y = -2; y < 2; ++y) 
                    {
                        float2 newUV = _uv + _MainTex_TexelSize * float2(x, y);
                        
                        fixed4 newTex = GrayScale(tex2D(_MainTex, newUV).rgb);

                        float sampleX = x + 2;
                        float sampleY = (y + 2) * 5;

                        R += GaussianKernel[(sampleX + sampleY)] * newTex.r;
                        G += GaussianKernel[(sampleX + sampleY)] * newTex.g;
                        B += GaussianKernel[(sampleX + sampleY)] * newTex.b;

                    }

                }
                
                R /= 273.0f;
                G /= 273.0f;
                B /= 273.0f;
               
                return float4(R, G, B, 1);
            }

            float4 PreSobel_CannyPipeline(float4 _tex, float2 _uv)
            {

               float4 finalOutput = _tex;
                
               finalOutput = GrayScale(finalOutput);
               
               finalOutput = Blur(_uv);

               return finalOutput;
            }

            float4 Sobel( float2 _uv)
            {
                int3x3 Sx = {
                    1, 0, -1,
                    2, 0, -2,
                    1, 0, -1
                };

                int3x3 Sy = {
                    1, 2, 1,
                    0, 0, 0,
                    -1, -2, -1
                };

                float Gx = 0.0f;
                float Gy = 0.0f;

                for (int x = -1; x <= 1; ++x) 
                {
                    for (int y = -1; y <= 1; ++y) 
                    {
                        float2 newUV = _uv + _MainTex_TexelSize * float2(x, y);
                        
                        fixed4 newTex = PreSobel_CannyPipeline(tex2D(_MainTex, newUV), newUV);
                        half r = newTex.r;

                        Gx += Sx[x + 1][y + 1] * r;
                        Gy += Sy[x + 1][y + 1] * r;

                    }

                }

                float EdgeGradient = sqrt(Gx * Gx + Gy * Gy);
                float EdgeDir = abs(atan2(Gy, Gx));
               
                return float4(EdgeGradient, EdgeGradient, EdgeGradient, EdgeDir);
            }

            float4 Gradient_Supression(float4 _tex, float2 _uv)
            {
                float4 finalOutput = _tex;

                float EdgeGradient = finalOutput.x;
                float EdgeDir = degrees(finalOutput.a);

                float2 sampledGradient = (0,0);
                if ((0.0f <= EdgeDir && EdgeDir <= 36.0f) || (144.0f <= EdgeDir && EdgeDir <= 180.0f)) 
                {
                    float leftGradient = tex2D(_MainTex, _uv + _MainTex_TexelSize * float2(1, 0)).r;
                    float rightGradient = tex2D(_MainTex, _uv + _MainTex_TexelSize * float2(-1, 0)).r;

                    sampledGradient = float2(leftGradient, rightGradient);
                }
                else  if ((72.0f <= EdgeDir && EdgeDir <= 36.0f)) 
                {
                    float topRightGradient = tex2D(_MainTex, _uv + _MainTex_TexelSize * float2(1, 1)).r;
                    float bottomLeftGradient = tex2D(_MainTex, _uv + _MainTex_TexelSize * float2(-1, -1)).r;

                     sampledGradient = float2(topRightGradient, bottomLeftGradient);
                }
                else  if ((108.0f <= EdgeDir && EdgeDir <= 72.0f)) 
                {
                    float toptGradient = tex2D(_MainTex, _uv + _MainTex_TexelSize * float2(0, 1)).r;
                    float bottomGradient = tex2D(_MainTex, _uv + _MainTex_TexelSize * float2(0, -1)).r;

                    sampledGradient = float2(toptGradient, bottomGradient);
                }
                else
                {
                    float topLefttGradient = tex2D(_MainTex, _uv + _MainTex_TexelSize * float2(-1, 1)).r;
                    float bottoRightmGradient = tex2D(_MainTex, _uv + _MainTex_TexelSize * float2(1, -1)).r;

                    sampledGradient = float2(topLefttGradient, bottoRightmGradient);
                }

                finalOutput = EdgeGradient >= sampledGradient.x && EdgeGradient >= sampledGradient.y ? finalOutput : 0.0f;

                return fixed4(finalOutput.rgb, 1);
            }

            float4 Double_Threshold (float4 _tex)
            {
               float3 finalOutput = _tex;
            
               if(finalOutput.r > _HighThreshold)
               {
                    finalOutput = 1.0f;
               }
               else if(finalOutput.r > _LowThreshold)
               {
                    finalOutput = 0.5f;
               }
               else
               {
                    finalOutput = 0;
               }
                
                return fixed4(finalOutput.rgb, 1);
            }

            float4 PreHysteris_CannyPipeline(float4 _tex, float2 _uv)
            {

                float4 finalOutput = _tex;
                
               finalOutput = PreSobel_CannyPipeline(finalOutput, _uv);

               finalOutput = Sobel(_uv);

               finalOutput = Gradient_Supression(finalOutput, _uv);

               finalOutput = Double_Threshold(finalOutput);

               return finalOutput;
            }

            float4 Hysteresis(float4 _tex, float2 _uv)
            {

                float4 finalOutput = _tex;

                for (int x = -1; x <= 1; ++x) 
                {
                    for (int y = -1; y <= 1; ++y) 
                    {
                        float2 newUV = _uv + _MainTex_TexelSize * float2(x, y);
                        
                        fixed4 newTex = PreHysteris_CannyPipeline(finalOutput, newUV);

                        if(newTex.r == 1)
                        {
                            break;
                        }
                        else if(finalOutput.r != 1)
                        {
                            finalOutput = 0;
                        }
                    }

                }

                return fixed4(finalOutput.rgb, 1);

            }

            float4 CannyPipeline(float4 _tex, float2 _uv)
            {

               float4 finalOutput = _tex;                

               finalOutput = PreHysteris_CannyPipeline(finalOutput, _uv);

               finalOutput = Hysteresis(finalOutput, _uv); 

               return finalOutput;
            }


            fixed4 frag (v2f i) : SV_Target
            { 
               fixed4 finalOutput = fixed4(1,1,1,1);
               fixed4 mainTex = tex2D(_MainTex, i.uv);
               fixed4 paperTex = tex2D(_PaperTex, i.uv);
               fixed4 noiseTex = tex2D(_NoiseTex, i.noiseUV);

               finalOutput = mainTex;       
               
               finalOutput = CannyPipeline(finalOutput, i.uv);

                             
               _EdgeBrightness = _EdgeBrightness * 2 - 1;

               float temp_finalOutput = finalOutput;
               temp_finalOutput *= _EdgeBrightness;

               float4 lineMod = (1 + temp_finalOutput) * _EdgeOppacity;

               lineMod += (1 - _EdgeOppacity) * paperTex;


               float4 test = GrayScale(mainTex);
               float mainLum = (test.r + test.g + test.b);



               if(noiseTex.r > 1 - (mainLum + _LumUpperThreshold))
               {

                    noiseTex = 1;
                    
               }
               else
               {
                    noiseTex = 0;
               }

               float4 temp = 1 - (1 * _EdgeOppacity);

               noiseTex = lerp(paperTex, temp, 1 - noiseTex.r);

               finalOutput = lerp(noiseTex, lineMod, finalOutput.r);


               return finalOutput;
            }
            ENDCG
        }
    }
}
