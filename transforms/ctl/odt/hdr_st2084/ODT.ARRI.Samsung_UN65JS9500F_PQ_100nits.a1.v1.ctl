
// <ACEStransformID>ODT.ARRI.Samsung_UN65JS9500F_PQ_100nits.a1.0.0</ACEStransformID>
// <ACESuserName>ACES 1.0 Output - ARRI's Samsung UN65JS9500F PQ as SDR sim (100 nits)</ACESuserName>

// 
// Output Device Transform - Rec709
//

//
// Summary :
//  This transform is intended for mapping OCES onto a Rec.709 broadcast monitor
//  that is calibrated to a D65 white point at 100 cd/m^2. The assumed observer 
//  adapted white is D65, and the viewing environment is a dim surround. 
//
//  A possible use case for this transform would be HDTV/video mastering.
//
// Device Primaries : 
//  Primaries are those specified in Rec. ITU-R BT.709
//  CIE 1931 chromaticities:  x         y         Y
//              Red:          0.64      0.33
//              Green:        0.3       0.6
//              Blue:         0.15      0.06
//              White:        0.3217    0.329     100 cd/m^2
//
// Display EOTF :
//  The reference electro-optical transfer function specified in 
//  Rec. ITU-R BT.1886.
//
// Signal Range:
//    By default, this tranform outputs full range code values. If instead a 
//    SMPTE "legal" signal is desired, there is a runtime flag to output 
//    SMPTE legal signal. In ctlrender, this can be achieved by appending 
//    '-param1 legalRange 1' after the '-ctl odt.ctl' string.
//
// Assumed observer adapted white point:
//         CIE 1931 chromaticities:    x            y
//                                     0.3217       0.329
//
// Viewing Environment:
//   This ODT has a compensation for viewing environment variables more typical 
//   of those associated with video mastering.
//



import "ACESlib.Utilities";
import "ACESlib.Transform_Common";
import "ACESlib.ODT_Common";
import "ACESlib.Tonescales";



/* --- ODT Parameters --- */

const Chromaticities ARRI_Burbank_Samsung_PRI =
{
  { 0.6742,  0.3107},
  { 0.2631,  0.6494},
  { 0.1521,  0.0530},
  { 0.3056,  0.3274}
};

const Chromaticities DISPLAY_PRI = ARRI_Burbank_Samsung_PRI;

const float XYZ_2_DISPLAY_PRI_MAT[4][4] = XYZtoRGB(DISPLAY_PRI,1.0);

// Special CAT for Burbank monitor - Munich will want to have their own
// in accord with their own measurements
const float D60_2_BUR_SAMSUNG_CAT[3][3] = calculate_cat_matrix( AP0.white, DISPLAY_PRI.white);

const float DISPGAMMA = 2.4; 
const float L_W = 100.0;
const float L_B = 0.005;



void main 
(
    input varying float rIn, 
    input varying float gIn, 
    input varying float bIn, 
    input varying float aIn,
    output varying float rOut,
    output varying float gOut,
    output varying float bOut,
    output varying float aOut,
    input varying int legalRange = 1
)
{
    float oces[3] = { rIn, gIn, bIn};

  // OCES to RGB rendering space
    float rgbPre[3] = mult_f3_f44( oces, AP0_2_AP1_MAT);

  // Apply the tonescale independently in rendering-space RGB
    float rgbPost[3];
    rgbPost[0] = segmented_spline_c9_fwd( rgbPre[0]);
    rgbPost[1] = segmented_spline_c9_fwd( rgbPre[1]);
    rgbPost[2] = segmented_spline_c9_fwd( rgbPre[2]);

  // Scale luminance to linear code value
    float linearCV[3];
    linearCV[0] = Y_2_linCV( rgbPost[0], CINEMA_WHITE, CINEMA_BLACK);
    linearCV[1] = Y_2_linCV( rgbPost[1], CINEMA_WHITE, CINEMA_BLACK);
    linearCV[2] = Y_2_linCV( rgbPost[2], CINEMA_WHITE, CINEMA_BLACK);

  // Apply gamma adjustment to compensate for dim surround
    linearCV = darkSurround_to_dimSurround( linearCV);

  // Apply desaturation to compensate for luminance difference
    linearCV = mult_f3_f33( linearCV, ODT_SAT_MAT);
    
  // Convert to display primary encoding
    // Rendering space RGB to XYZ
    float XYZ[3] = mult_f3_f44( linearCV, AP1_2_XYZ_MAT);

    // Apply CAT from ACES white point to assumed observer adapted white point
    XYZ = mult_f3_f33( XYZ, D60_2_BUR_SAMSUNG_CAT);

    // CIE XYZ to display primaries
    linearCV = mult_f3_f44( XYZ, XYZ_2_DISPLAY_PRI_MAT);

  // Handle out-of-gamut values
    // Clip values < 0 or > 1 (i.e. projecting outside the display primaries)
    linearCV = clamp_f3( linearCV, 0., 1.);
  
//   // Determine output absolute luminance
//    float outputLum[3];
//    outputLum[0] = bt1886_f( linearCV[0], DISPGAMMA, L_W, L_B);
//    outputLum[1] = bt1886_f( linearCV[1], DISPGAMMA, L_W, L_B);
//    outputLum[2] = bt1886_f( linearCV[2], DISPGAMMA, L_W, L_B);

  // Determine output absolute luminance
  float outputLum[3];
  outputLum[0] = L_B + (L_W - L_B) * linearCV[0];
  outputLum[1] = L_B + (L_W - L_B) * linearCV[1];
  outputLum[2] = L_B + (L_W - L_B) * linearCV[2];

  // Encode linear code values with transfer function
    float outputCV[3] = Y_2_ST2084_f3(outputLum);

  // Default output is full range, check if legalRange param was set to true
    if (legalRange == 1) {
      outputCV = fullRange_to_smpteRange_f3( outputCV);
    }

    rOut = outputCV[0];
    gOut = outputCV[1];
    bOut = outputCV[2];
    aOut = aIn;
}