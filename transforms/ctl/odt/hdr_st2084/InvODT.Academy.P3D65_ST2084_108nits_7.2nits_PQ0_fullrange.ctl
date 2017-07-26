
// <ACEStransformID>InvODT.Academy.P3D65_ST2084_108.a1.0.3</ACEStransformID>
// <ACESuserName>Inverse ACES 1.0 Output - P3-D65 ST2084 (108 nits)</ACESuserName>

// 
// Inverse Output Device Transform - P3D65 (108 cd/m^2)
//

//
// Summary :
//  This transform is intended for converting code values for an HDR projector calibrated 
//  to P3 primaries and a D65 white point at 108 cd/m^2 into OCES. The assumed observer 
//  adapted white is D65, and the viewing environment is that of a dark surround. 
//
// Device Primaries : 
//  CIE 1931 chromaticities:  x         y         Y
//              Red:          0.68      0.32
//              Green:        0.265     0.69
//              Blue:         0.15      0.06
//              White:        0.3127    0.329     108 cd/m^2
//
// Display EOTF :
//  The reference electro-optical transfer function specified in SMPTE ST 
//  2084-2014. This transform makes no attempt to address the Annex functions 
//  which address integer quantization.
//
// Assumed observer adapted white point:
//         CIE 1931 chromaticities:    x            y
//                                     0.3127       0.329
//
// Viewing Environment:
//  Environment specified in SMPTE RP 431-2-2007
//



import "ACESlib.Utilities";
import "ACESlib.Transform_Common";
import "ACESlib.ODT_Common";
import "ACESlib.Tonescales";



/* --- ODT Parameters --- */
const Chromaticities DISPLAY_PRI = 
{ // P3-D65
  { 0.68000,  0.32000},
  { 0.26500,  0.69000},
  { 0.15000,  0.06000},
  { 0.31270,  0.32900}
};
const float DISPLAY_PRI_2_XYZ_MAT[4][4] = RGBtoXYZ( DISPLAY_PRI, 1.0);


const float EXP_SHIFT = log10(7.2) - log10(4.8);

float shift( float in)
{
    return pow10( log10(in)-EXP_SHIFT);
}

const SegmentedSplineParams_c9 ODT_108nits =
{
    // coefsLow[10]
    { -4.5171198117, -3.8483710365, -3.0177000000, -2.2706000000, -1.5835000000, -0.9365000000, -0.2894000000, 0.3468668498, 1.0156156250, 1.0156156250},
    // coefsHigh[10]
    { 0.4790997774, 0.8833826974, 1.2882000000, 1.6228000000, 1.8325000000, 1.9621000000, 2.0167000000, 2.0334237555, 2.0334237555, 2.0334237555},
    { shift(segmented_spline_c5_fwd( 0.18*pow(2.,-15.0))), 0.0000656530},    // minPoint
    { shift(segmented_spline_c5_fwd( 0.18)), 4.80000000},    // midPoint
    { shift(segmented_spline_c5_fwd( 0.18*pow(2.,9.0))), 108.00000000},    // maxPoint
    1.00,  // slopeLow
    0.00   // slopeHigh
};

float[3] Y_2_linCV_f3( float in[3], float Ymax, float Ymin)
{
  // f3 version
  
  float out[3];
  out[0] = Y_2_linCV( in[0], Ymax, Ymin);
  out[1] = Y_2_linCV( in[1], Ymax, Ymin);
  out[2] = Y_2_linCV( in[2], Ymax, Ymin);

  return out;
}

float[3] linCV_2_Y_f3( float in[3], float Ymax, float Ymin)
{
  // f3 version
  
  float out[3];
  out[0] = linCV_2_Y( in[0], Ymax, Ymin);
  out[1] = linCV_2_Y( in[1], Ymax, Ymin);
  out[2] = linCV_2_Y( in[2], Ymax, Ymin);

  return out;
}

void main 
(
    input varying float rIn, 
    input varying float gIn, 
    input varying float bIn, 
    input varying float aIn,
    output varying float rOut,
    output varying float gOut,
    output varying float bOut,
    output varying float aOut
)
{
    float cv[3] = { rIn, gIn, bIn};

    // ST2084 code value to P3-D65 RGB
    float rgb[3] = linCV_2_Y_f3( Y_2_linCV_f3( ST2084_2_Y_f3( cv), 108., 0.), 108., 0.0001);
    
    // Display primaries to CIE XYZ
    float XYZ[3] = mult_f3_f44( rgb, DISPLAY_PRI_2_XYZ_MAT);
    
      // Apply inverse CAT from D65 to ACES white point
      XYZ = mult_f3_f33( XYZ, invert_f33( D60_2_D65_CAT));

    // XYZ to AP1      
    float rgbPre[3] = mult_f3_f44( XYZ, XYZ_2_AP1_MAT);
    
    // Inverse tonescale
    float rgbPost[3];
    rgbPost[0] = segmented_spline_c9_rev( rgbPre[0], ODT_108nits);
    rgbPost[1] = segmented_spline_c9_rev( rgbPre[1], ODT_108nits);
    rgbPost[2] = segmented_spline_c9_rev( rgbPre[2], ODT_108nits);
    
    // AP1 to OCES
    float oces[3] = mult_f3_f44( rgbPost, AP1_2_AP0_MAT);

    rOut = oces[0];
    gOut = oces[1];
    bOut = oces[2];
    aOut = aIn;
}
