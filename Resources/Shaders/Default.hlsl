#include "Common.hlsl"

Texture2D albedo : register(t0);

VertexOut VS(VertexIn vin)
{
  VertexOut vout;
  // Transform to homogeneous clip space.
  float4 posW = mul(float4(vin.pL, 1.0f), mtxW);
  vout.pos = mul(posW, mtxVP);
  vout.normal = normalize(vin.nL);
  vout.tangent = normalize(vin.tL);
  vout.uv = vin.uv;
  return vout;
}

float4 PS(VertexOut pin) : SV_Target
{
  float4 output = 0;
  float4 color = albedo.Sample(Ani, pin.uv);
  //normal_m.xyz = GetWorldNormal(normal_m.xyz, 0, 0);

  // spec/diff/reflectvitity are all generated from metallic.
  //
  //unity_ColorSpaceDielectricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04)
  //standard dielectric reflectivity coef at incident angle (= 4%)
  //float3 specColor = lerp(float3(0.04, 0.04, 0.04), albedo_s.rgb, normal_m.a);
  //float oneMinusReflectivity = 0.96 - normal_m.a * 0.96;
  //float3 diffColor = albedo_s.rgb * oneMinusReflectivity;

  float3 giColor = 0;
  float3 emissiveColor = 0;
  float3 extraColor = giColor + emissiveColor;

  //output.backBuffer = float4(extraColor, 0);
  //output.backBuffer = float4(EncodeSRGB(albedo_s).rgb, 0);
  output = EncodeSRGB(color);//EncodeSRGB(normal_m);//float4(pin.normal, 0);

  // TEMP Light
  float3 lightDir = normalize(float3(0.5, -2, 0.5));
  float3 normal = normalize(pin.normal);
  normal.y *= -1;
  float factor = clamp(0.5 * dot(lightDir, normal) + 0.5 + 0.1, 0, 1);
  output *= factor;
  ////////

  // TEMP Stipple Effect
  float alphaHC = 1.0f;
  //float alphaHC = 0.2f;
  int2 screenSizeHC = int2(1920, 1080);
  // Thresholds
  float stipple[4][4] =
  {
    { 0.0/16,  8.0/16,  2.0/16, 10.0/16},
    {12.0/16,  4.0/16, 14.0/16,  6.0/16},
    { 3.0/16, 11.0/16,  1.0/16,  9.0/16},
    {15.0/16,  7.0/16, 13.0/16,  5.0/16}
  };

  int2 screenPos = floor(pin.pos.xy);

  int2 stipplePos = int2(screenPos.x % 4, screenPos.y % 4);
  float stippleValue = stipple[stipplePos.x][stipplePos.y];
  if(alphaHC < stippleValue)
  {
    discard;
  }
  ////////

  return output;
}