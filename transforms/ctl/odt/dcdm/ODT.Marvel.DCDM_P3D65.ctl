
// <ACEStransformID>ODT.Marvel.DCDM_P3D65.a1.v1</ACEStransformID>
// <ACESuserName>ACES 1.0 Output - DCDM (P3-D65 gamut clip)</ACESuserName>

// 
// Output Device Transform - DCDM (X'Y'Z'), limited to P3-D65
//

//
// Summary:
//  This ODT encodes XYZ colorimetry that is gamut-limited to P3 primaries with 
//  a D65 whitepoint. This has two advantages:
// 
//   1) "Gamut mapping" is explicitly controlled by the ODT by clipping any XYZ 
//      values that map outside of the P3 gamut. Without this step, it would be 
//      left to the projector to handle any XYZ values outside of the P3 gamut. 
//      In most devices, this is performed using a simple clip, but not always.   
//      If out-of-gamut values are left to be handled by the device, different 
//      image appearance could potentially result on different devices even 
//      though they have the same gamut.
//
//   2) Assuming the content was graded (and approved) on a projector with a 
//      P3-D65 gamut, limiting the colors to that gamut assures there will be
//      no unexpected color appearance if the DCP is later viewed on a device 
//      with a wider gamut.
// 
//  The assumed observer adapted white is D65, and the viewing environment is 
//  that of a dark theater. 
//
//  This transform shall be used for a device calibrated to match the Digital 
//  Cinema Reference Projector Specification outlined in SMPTE RP 431-2-2007.
//
// Assumed observer adapted white point:
//         CIE 1931 chromaticities:    x            y
//                                     0.31270		0.32900
//
// Viewing Environment:
//  Environment specified in SMPTE RP 431-2-2007
//



import "ACESlib.Utilities";
import "ACESlib.Transform_Common";
import "ACESlib.ODT_Common";
import "ACESlib.Tonescales";



/* ----- ODT Parameters ------ */
const Chromaticities DISPLAY_PRI = P3D65_PRI;
const float XYZ_2_DISPLAY_PRI_MAT[4][4] = XYZtoRGB( DISPLAY_PRI, 1.0);
const float DISPLAY_PRI_2_XYZ_MAT[4][4] = RGBtoXYZ( DISPLAY_PRI, 1.0);

const float DISPGAMMA = 2.6; 



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
    float oces[3] = { rIn, gIn, bIn};

  // ACES to RGB rendering space
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

  // Rendering space RGB to XYZ
    float XYZ[3] = mult_f3_f44( linearCV, AP1_2_XYZ_MAT);
    
	// Apply CAT from ACES white point to assumed observer adapted white point
	  XYZ = mult_f3_f33( XYZ, D60_2_D65_CAT);

  // XYZ to P3D65    
    float P3D65[3] = mult_f3_f44( XYZ, XYZ_2_DISPLAY_PRI_MAT);
    
  // Clip values < 0 or > 1 (i.e. projecting outside the display primaries)
    P3D65 = clamp_f3( P3D65, 0., 1.);

  // P3D65 to XYZ
    XYZ = mult_f3_f44( P3D65, DISPLAY_PRI_2_XYZ_MAT);

  // Encode linear code values with transfer function
    float outputCV[3] = dcdm_encode( XYZ);
    
    rOut = outputCV[0];
    gOut = outputCV[1];
    bOut = outputCV[2];
    aOut = aIn;
}