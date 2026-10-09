// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import '../../config/constants.dart';
import '../../services/incidentes_service.dart';
import '../../services/predicciones_service.dart';
import '../../models/prediccion.dart';
import '../../theme/app_theme.dart';
import '../../widgets/map_control_button.dart';
import '../../widgets/map_legend_item.dart';

// =============================================================================
// COORDENADAS DE LOS 9 SECTORES (Coincidentes exactamente con Mapa.jsx)
// =============================================================================

const List<LatLng> _sector1Polygon = [
  LatLng(-12.064209, -77.037496), LatLng(-12.064225, -77.037647), LatLng(-12.064245, -77.037821), LatLng(-12.064281, -77.038155), LatLng(-12.064354, -77.038831), LatLng(-12.064843, -77.038843), LatLng(-12.06502, -77.03884), LatLng(-12.065234, -77.03886), LatLng(-12.065613, -77.03892), LatLng(-12.06684, -77.039121), LatLng(-12.068318, -77.039378), LatLng(-12.068936, -77.039581), LatLng(-12.069972, -77.040043), LatLng(-12.070911, -77.040465), LatLng(-12.072205, -77.041097), LatLng(-12.073296, -77.041596), LatLng(-12.073627, -77.041723), LatLng(-12.07429, -77.041835), LatLng(-12.075225, -77.041967), LatLng(-12.075865, -77.042029), LatLng(-12.076447, -77.042049), LatLng(-12.076596, -77.042049), LatLng(-12.077847, -77.042088), LatLng(-12.07955, -77.042132), LatLng(-12.079623, -77.041675), LatLng(-12.080616, -77.041749), LatLng(-12.080198, -77.038544), LatLng(-12.080175, -77.0382), LatLng(-12.080136, -77.038069), LatLng(-12.080053, -77.037614), LatLng(-12.07987, -77.036273), LatLng(-12.075698, -77.036914), LatLng(-12.07356, -77.037227), LatLng(-12.071452, -77.037555), LatLng(-12.069755, -77.037819), LatLng(-12.067642, -77.038137), LatLng(-12.06712, -77.038056), LatLng(-12.066389, -77.037923), LatLng(-12.066334, -77.037889),
];

const List<LatLng> _sector2Polygon = [
  LatLng(-12.064393, -77.039129), LatLng(-12.06439, -77.039214), LatLng(-12.064401, -77.03929), LatLng(-12.064417, -77.039341), LatLng(-12.064462, -77.039401), LatLng(-12.064541, -77.039859), LatLng(-12.064581, -77.040185), LatLng(-12.064669, -77.040876), LatLng(-12.064785, -77.041758), LatLng(-12.06487, -77.042364), LatLng(-12.064946, -77.042918), LatLng(-12.065018, -77.04343), LatLng(-12.065037, -77.0436), LatLng(-12.065131, -77.044233), LatLng(-12.06527, -77.045262), LatLng(-12.06531, -77.045558), LatLng(-12.065304, -77.045645), LatLng(-12.065319, -77.045723), LatLng(-12.065654, -77.046006), LatLng(-12.066095, -77.04637), LatLng(-12.066568, -77.046757), LatLng(-12.067061, -77.04717), LatLng(-12.06747, -77.047508), LatLng(-12.067925, -77.047878), LatLng(-12.068231, -77.048128), LatLng(-12.068659, -77.048478), LatLng(-12.06911, -77.048851), LatLng(-12.069517, -77.049187), LatLng(-12.070155, -77.049715), LatLng(-12.070238, -77.049604), LatLng(-12.070578, -77.049185), LatLng(-12.070952, -77.048723), LatLng(-12.071261, -77.048329), LatLng(-12.071656, -77.047831), LatLng(-12.071799, -77.047657), LatLng(-12.071976, -77.047436), LatLng(-12.072219, -77.047141), LatLng(-12.072268, -77.047079), LatLng(-12.072478, -77.046823), LatLng(-12.072607, -77.046668), LatLng(-12.072677, -77.046528), LatLng(-12.072675, -77.045947), LatLng(-12.072668, -77.045378), LatLng(-12.072669, -77.044784), LatLng(-12.072681, -77.044708), LatLng(-12.072683, -77.044305), LatLng(-12.072691, -77.04342), LatLng(-12.0727, -77.042668), LatLng(-12.072708, -77.041947), LatLng(-12.072712, -77.041884), LatLng(-12.072739, -77.041618), LatLng(-12.072063, -77.041322), LatLng(-12.070795, -77.04074), LatLng(-12.069816, -77.040292), LatLng(-12.069022, -77.039936), LatLng(-12.068484, -77.039733), LatLng(-12.067786, -77.039588), LatLng(-12.066304, -77.039319), LatLng(-12.065974, -77.039258), LatLng(-12.065052, -77.039147),
];

const List<LatLng> _sector3Polygon = [
  LatLng(-12.072806, -77.041647), LatLng(-12.0728, -77.041708), LatLng(-12.072795, -77.041776), LatLng(-12.072778, -77.041975), LatLng(-12.072769, -77.042537), LatLng(-12.072759, -77.043488), LatLng(-12.07275, -77.044705), LatLng(-12.072739, -77.045369), LatLng(-12.072747, -77.046035), LatLng(-12.072743, -77.046856), LatLng(-12.073829, -77.046859), LatLng(-12.075009, -77.046867), LatLng(-12.07522, -77.046866), LatLng(-12.075639, -77.046871), LatLng(-12.076379, -77.046875), LatLng(-12.077152, -77.046894), LatLng(-12.077238, -77.04696), LatLng(-12.077633, -77.046485), LatLng(-12.078601, -77.047304), LatLng(-12.078823, -77.047024), LatLng(-12.078943, -77.046872), LatLng(-12.079005, -77.046818), LatLng(-12.079102, -77.04677), LatLng(-12.079227, -77.046745), LatLng(-12.079341, -77.046739), LatLng(-12.079508, -77.046743), LatLng(-12.081131, -77.046812), LatLng(-12.081164, -77.04596), LatLng(-12.081171, -77.045777), LatLng(-12.081174, -77.045752), LatLng(-12.0812, -77.045757), LatLng(-12.081213, -77.045749), LatLng(-12.081261, -77.045743), LatLng(-12.081352, -77.045755), LatLng(-12.081795, -77.045813), LatLng(-12.082242, -77.045871), LatLng(-12.082279, -77.04578), LatLng(-12.08234, -77.045698), LatLng(-12.082404, -77.045641), LatLng(-12.082525, -77.045562), LatLng(-12.082589, -77.04554), LatLng(-12.082757, -77.04584), LatLng(-12.08306, -77.046204), LatLng(-12.083075, -77.045802), LatLng(-12.083097, -77.045324), LatLng(-12.083125, -77.044784), LatLng(-12.083157, -77.044244), LatLng(-12.083187, -77.04366), LatLng(-12.083061, -77.042798), LatLng(-12.08298, -77.042187), LatLng(-12.082937, -77.041972), LatLng(-12.082857, -77.041967), LatLng(-12.082558, -77.041947), LatLng(-12.081896, -77.041898), LatLng(-12.081129, -77.041836), LatLng(-12.080555, -77.041799), LatLng(-12.07977, -77.041735), LatLng(-12.079744, -77.041989), LatLng(-12.079721, -77.04222), LatLng(-12.079717, -77.042287), LatLng(-12.079729, -77.042366), LatLng(-12.079747, -77.042441), LatLng(-12.079663, -77.042433), LatLng(-12.079576, -77.042426), LatLng(-12.079335, -77.04242), LatLng(-12.078506, -77.042403), LatLng(-12.077404, -77.042384), LatLng(-12.076461, -77.042345), LatLng(-12.07607, -77.042338), LatLng(-12.075653, -77.042308), LatLng(-12.075321, -77.042265), LatLng(-12.075039, -77.042214), LatLng(-12.073779, -77.042067), LatLng(-12.073564, -77.042017), LatLng(-12.073361, -77.041941), LatLng(-12.073202, -77.041858),
];

const List<LatLng> _sector4Polygon = [
  LatLng(-12.07021, -77.04975), LatLng(-12.07028, -77.049814), LatLng(-12.070403, -77.049918), LatLng(-12.070856, -77.050296), LatLng(-12.071251, -77.050624), LatLng(-12.071656, -77.050956), LatLng(-12.072099, -77.051318), LatLng(-12.072368, -77.051539), LatLng(-12.072702, -77.051811), LatLng(-12.073117, -77.052152), LatLng(-12.073485, -77.052456), LatLng(-12.073909, -77.052809), LatLng(-12.074084, -77.052955), LatLng(-12.074141, -77.052859), LatLng(-12.074937, -77.051869), LatLng(-12.075567, -77.051077), LatLng(-12.076178, -77.050301), LatLng(-12.076816, -77.049517), LatLng(-12.077409, -77.048783), LatLng(-12.077491, -77.048702), LatLng(-12.078072, -77.04796), LatLng(-12.078556, -77.047367), LatLng(-12.077634, -77.046579), LatLng(-12.077248, -77.047036), LatLng(-12.077165, -77.046953), LatLng(-12.076328, -77.046933), LatLng(-12.075017, -77.04693), LatLng(-12.073747, -77.046915), LatLng(-12.072498, -77.046913), LatLng(-12.072281, -77.047174), LatLng(-12.071671, -77.047933), LatLng(-12.07104, -77.048727), LatLng(-12.070296, -77.049647),
];

const List<LatLng> _sector5Polygon = [
  LatLng(-12.076871, -77.049562), LatLng(-12.076943, -77.049622), LatLng(-12.076992, -77.049663), LatLng(-12.077125, -77.049775), LatLng(-12.077365, -77.049973), LatLng(-12.077649, -77.050209), LatLng(-12.077736, -77.050283), LatLng(-12.07786, -77.050393), LatLng(-12.078818, -77.051189), LatLng(-12.079786, -77.052013), LatLng(-12.080773, -77.052843), LatLng(-12.080911, -77.052953), LatLng(-12.081179, -77.053168), LatLng(-12.081393, -77.053344), LatLng(-12.08143, -77.053378), LatLng(-12.081496, -77.053445), LatLng(-12.081521, -77.053477), LatLng(-12.081578, -77.053551), LatLng(-12.081639, -77.053654), LatLng(-12.081662, -77.053702), LatLng(-12.081745, -77.053888), LatLng(-12.081775, -77.053873), LatLng(-12.081825, -77.05386), LatLng(-12.081895, -77.05384), LatLng(-12.081969, -77.053815), LatLng(-12.082099, -77.053793), LatLng(-12.082162, -77.053781), LatLng(-12.082206, -77.053774), LatLng(-12.08269, -77.053767), LatLng(-12.082335, -77.05377), LatLng(-12.082385, -77.05377), LatLng(-12.082461, -77.053776), LatLng(-12.082563, -77.053789), LatLng(-12.082698, -77.053812), LatLng(-12.08283, -77.053848), LatLng(-12.083006, -77.053923), LatLng(-12.083287, -77.054084), LatLng(-12.083299, -77.053992), LatLng(-12.083327, -77.053768), LatLng(-12.083333, -77.053564), LatLng(-12.083318, -77.053218), LatLng(-12.083246, -77.052768), LatLng(-12.083136, -77.052357), LatLng(-12.083054, -77.052137), LatLng(-12.082719, -77.051272), LatLng(-12.082511, -77.050724), LatLng(-12.082374, -77.050381), LatLng(-12.082213, -77.049953), LatLng(-12.082096, -77.049649), LatLng(-12.081984, -77.049307), LatLng(-12.081934, -77.04911), LatLng(-12.081877, -77.048822), LatLng(-12.081835, -77.048487), LatLng(-12.081822, -77.048176), LatLng(-12.081835, -77.0478), LatLng(-12.081858, -77.047573), LatLng(-12.081899, -77.047314), LatLng(-12.081969, -77.046983), LatLng(-12.082113, -77.046381), LatLng(-12.082223, -77.045928), LatLng(-12.081266, -77.045798), LatLng(-12.081234, -77.0458), LatLng(-12.081223, -77.045817), LatLng(-12.081211, -77.046144), LatLng(-12.081195, -77.046594), LatLng(-12.081187, -77.046867), LatLng(-12.081133, -77.046868), LatLng(-12.080925, -77.046864), LatLng(-12.080586, -77.046854), LatLng(-12.08022, -77.046835), LatLng(-12.079911, -77.046821), LatLng(-12.079423, -77.046799), LatLng(-12.079292, -77.046795), LatLng(-12.079169, -77.046812), LatLng(-12.079051, -77.046859), LatLng(-12.07899, -77.046905), LatLng(-12.07893, -77.046986), LatLng(-12.078645, -77.047339), LatLng(-12.078598, -77.047402), LatLng(-12.078082, -77.04804), LatLng(-12.077764, -77.048438), LatLng(-12.077499, -77.048775), LatLng(-12.077442, -77.048862),
];

const List<LatLng> _sector6Polygon = [
  LatLng(-12.074142, -77.052997), LatLng(-12.074174, -77.053026), LatLng(-12.074187, -77.053037), LatLng(-12.074345, -77.053168), LatLng(-12.074456, -77.053263), LatLng(-12.074592, -77.053376), LatLng(-12.074704, -77.053469), LatLng(-12.074806, -77.053555), LatLng(-12.074942, -77.053669), LatLng(-12.075095, -77.053799), LatLng(-12.075146, -77.053841), LatLng(-12.075203, -77.053887), LatLng(-12.075314, -77.053977), LatLng(-12.075482, -77.054114), LatLng(-12.075655, -77.054257), LatLng(-12.075778, -77.054357), LatLng(-12.07581, -77.054382), LatLng(-12.075864, -77.054428), LatLng(-12.076038, -77.05457), LatLng(-12.076157, -77.05467), LatLng(-12.076279, -77.054772), LatLng(-12.076451, -77.054915), LatLng(-12.076614, -77.055052), LatLng(-12.07681, -77.055216), LatLng(-12.077019, -77.055392), LatLng(-12.077246, -77.055577), LatLng(-12.077495, -77.055782), LatLng(-12.077728, -77.055974), LatLng(-12.077919, -77.056131), LatLng(-12.078161, -77.056332), LatLng(-12.078372, -77.056508), LatLng(-12.078595, -77.056695), LatLng(-12.078669, -77.056755), LatLng(-12.078808, -77.05687), LatLng(-12.079027, -77.05705), LatLng(-12.079275, -77.057253), LatLng(-12.079488, -77.05743), LatLng(-12.079742, -77.057641), LatLng(-12.079962, -77.057823), LatLng(-12.080255, -77.058067), LatLng(-12.080439, -77.05822), LatLng(-12.080541, -77.058304), LatLng(-12.080558, -77.058285), LatLng(-12.080623, -77.058206), LatLng(-12.080727, -77.058071), LatLng(-12.080823, -77.057947), LatLng(-12.080899, -77.057851), LatLng(-12.081011, -77.057709), LatLng(-12.081043, -77.057666), LatLng(-12.081362, -77.057264), LatLng(-12.081409, -77.057204), LatLng(-12.082051, -77.056413), LatLng(-12.082121, -77.056322), LatLng(-12.082226, -77.056191), LatLng(-12.082385, -77.05598), LatLng(-12.082584, -77.055725), LatLng(-12.082685, -77.055578), LatLng(-12.082775, -77.055437), LatLng(-12.082859, -77.055299), LatLng(-12.082942, -77.055146), LatLng(-12.083025, -77.054961), LatLng(-12.083106, -77.054764), LatLng(-12.0832, -77.054466), LatLng(-12.083277, -77.054151), LatLng(-12.083018, -77.053995), LatLng(-12.082861, -77.05392), LatLng(-12.082736, -77.05388), LatLng(-12.082677, -77.053866), LatLng(-12.082527, -77.053839), LatLng(-12.082266, -77.053823), LatLng(-12.081987, -77.053868), LatLng(-12.081788, -77.053929), LatLng(-12.081717, -77.053961), LatLng(-12.081693, -77.053915), LatLng(-12.081658, -77.053819), LatLng(-12.081605, -77.053705), LatLng(-12.081542, -77.053596), LatLng(-12.081508, -77.053548), LatLng(-12.0816, -77.053485), LatLng(-12.081362, -77.053386), LatLng(-12.081234, -77.05328), LatLng(-12.081194, -77.053248), LatLng(-12.081044, -77.053131), LatLng(-12.080735, -77.052884), LatLng(-12.080694, -77.052849), LatLng(-12.08031, -77.052521), LatLng(-12.079947, -77.052215), LatLng(-12.079647, -77.051961), LatLng(-12.079269, -77.05164), LatLng(-12.079053, -77.051458), LatLng(-12.078803, -77.051246), LatLng(-12.078738, -77.051191), LatLng(-12.078495, -77.050991), LatLng(-12.07818, -77.050727), LatLng(-12.077826, -77.050432), LatLng(-12.077777, -77.050388), LatLng(-12.077668, -77.050298), LatLng(-12.076835, -77.049607), LatLng(-12.076561, -77.049944), LatLng(-12.076402, -77.050142), LatLng(-12.07623, -77.050351), LatLng(-12.076196, -77.050398), LatLng(-12.075967, -77.050686), LatLng(-12.075624, -77.051117), LatLng(-12.075581, -77.051175), LatLng(-12.07534, -77.051479), LatLng(-12.074988, -77.051915), LatLng(-12.074943, -77.051973), LatLng(-12.074578, -77.05243), LatLng(-12.074199, -77.0529),
];

const List<LatLng> _sector7Polygon = [
  LatLng(-12.080656, -77.058394), LatLng(-12.080684, -77.058417), LatLng(-12.080729, -77.058454), LatLng(-12.080852, -77.058555), LatLng(-12.081025, -77.058696), LatLng(-12.081182, -77.058825), LatLng(-12.081339, -77.058954), LatLng(-12.081516, -77.059099), LatLng(-12.081684, -77.059236), LatLng(-12.082002, -77.059494), LatLng(-12.08213, -77.059598), LatLng(-12.082273, -77.059713), LatLng(-12.082393, -77.059809), LatLng(-12.082534, -77.059923), LatLng(-12.082676, -77.060039), LatLng(-12.082834, -77.060171), LatLng(-12.082983, -77.060293), LatLng(-12.083141, -77.060426), LatLng(-12.083282, -77.060542), LatLng(-12.083458, -77.060689), LatLng(-12.083602, -77.060808), LatLng(-12.083774, -77.060949), LatLng(-12.083934, -77.061081), LatLng(-12.084074, -77.061196), LatLng(-12.084229, -77.061324), LatLng(-12.084313, -77.061392), LatLng(-12.084395, -77.061461), LatLng(-12.084503, -77.061552), LatLng(-12.084551, -77.061593), LatLng(-12.084571, -77.061609), LatLng(-12.084625, -77.061653), LatLng(-12.084794, -77.061794), LatLng(-12.085129, -77.062055), LatLng(-12.085455, -77.062312), LatLng(-12.085688, -77.062495), LatLng(-12.085728, -77.06254), LatLng(-12.085746, -77.062543), LatLng(-12.085885, -77.062665), LatLng(-12.086149, -77.062896), LatLng(-12.086396, -77.063111), LatLng(-12.086455, -77.063161), LatLng(-12.086648, -77.062912), LatLng(-12.086688, -77.06285), LatLng(-12.086746, -77.062761), LatLng(-12.086826, -77.062632), LatLng(-12.086919, -77.062488), LatLng(-12.086987, -77.062379), LatLng(-12.087036, -77.062303), LatLng(-12.087109, -77.062188), LatLng(-12.087164, -77.062103), LatLng(-12.087204, -77.062038), LatLng(-12.08732, -77.061856), LatLng(-12.087431, -77.061686), LatLng(-12.087476, -77.061603), LatLng(-12.087537, -77.061491), LatLng(-12.087591, -77.061391), LatLng(-12.087629, -77.06133), LatLng(-12.087695, -77.061226), LatLng(-12.08779, -77.061077), LatLng(-12.087818, -77.061038), LatLng(-12.087855, -77.060981), LatLng(-12.087878, -77.060937), LatLng(-12.088004, -77.060751), LatLng(-12.088117, -77.060579), LatLng(-12.088226, -77.060414), LatLng(-12.088327, -77.060259), LatLng(-12.088466, -77.060048), LatLng(-12.088578, -77.059878), LatLng(-12.088677, -77.059727), LatLng(-12.088617, -77.059678), LatLng(-12.088306, -77.05942), LatLng(-12.088257, -77.059384), LatLng(-12.087504, -77.058759), LatLng(-12.08746, -77.05872), LatLng(-12.087146, -77.058462), LatLng(-12.08709, -77.058415), LatLng(-12.08726, -77.058201), LatLng(-12.087001, -77.057987), LatLng(-12.086785, -77.057809), LatLng(-12.086817, -77.057769), LatLng(-12.086927, -77.057632), LatLng(-12.087047, -77.057485), LatLng(-12.087112, -77.05741), LatLng(-12.087187, -77.057323), LatLng(-12.087307, -77.057257), LatLng(-12.087336, -77.05725), LatLng(-12.087366, -77.057241), LatLng(-12.087394, -77.057228), LatLng(-12.087417, -77.057211), LatLng(-12.087434, -77.057193), LatLng(-12.087443, -77.057173), LatLng(-12.087444, -77.057144), LatLng(-12.087436, -77.057122), LatLng(-12.08742, -77.057094), LatLng(-12.087402, -77.057077), LatLng(-12.087364, -77.057068), LatLng(-12.087304, -77.057075), LatLng(-12.087246, -77.057088), LatLng(-12.087214, -77.05706), LatLng(-12.087033, -77.056907), LatLng(-12.086785, -77.056705), LatLng(-12.086558, -77.056521), LatLng(-12.086327, -77.056315), LatLng(-12.086295, -77.056266), LatLng(-12.086272, -77.056215), LatLng(-12.086247, -77.056168), LatLng(-12.086205, -77.056122), LatLng(-12.086126, -77.056054), LatLng(-12.085865, -77.055851), LatLng(-12.085817, -77.055816), LatLng(-12.08567, -77.055719), LatLng(-12.08529, -77.055467), LatLng(-12.085235, -77.055432), LatLng(-12.084801, -77.055147), LatLng(-12.08454, -77.054978), LatLng(-12.084486, -77.054945), LatLng(-12.084285, -77.054814), LatLng(-12.083926, -77.054577), LatLng(-12.083584, -77.054353), LatLng(-12.083443, -77.054253), LatLng(-12.083407, -77.054417), LatLng(-12.083313, -77.054766), LatLng(-12.083178, -77.055096), LatLng(-12.083102, -77.055251), LatLng(-12.083076, -77.055299), LatLng(-12.083006, -77.055419), LatLng(-12.082817, -77.055693), LatLng(-12.082445, -77.056166), LatLng(-12.082132, -77.056555), LatLng(-12.082044, -77.056662), LatLng(-12.08202, -77.056700), LatLng(-12.08183, -77.056915), LatLng(-12.081798, -77.056955), LatLng(-12.08166, -77.057135), LatLng(-12.081534, -77.057294), LatLng(-12.081501, -77.057334), LatLng(-12.081369, -77.0575), LatLng(-12.081236, -77.057669), LatLng(-12.081086, -77.057856), LatLng(-12.08097, -77.058002), LatLng(-12.080841, -77.058164), LatLng(-12.08079, -77.058232), LatLng(-12.08074, -77.058293), LatLng(-12.080691, -77.058353), LatLng(-12.080674, -77.058375),
];

const List<LatLng> _sector8Polygon = [
  LatLng(-12.08258, -77.045936), LatLng(-12.0825, -77.046002), LatLng(-12.082433, -77.046057), LatLng(-12.082393, -77.046113), LatLng(-12.08235, -77.046286), LatLng(-12.082247, -77.046657), LatLng(-12.082148, -77.04701), LatLng(-12.082086, -77.04729), LatLng(-12.082037, -77.047596), LatLng(-12.082005, -77.048093), LatLng(-12.08202, -77.048433), LatLng(-12.082064, -77.048825), LatLng(-12.082123, -77.049088), LatLng(-12.082207, -77.049373), LatLng(-12.082331, -77.049729), LatLng(-12.082458, -77.050056), LatLng(-12.082609, -77.050466), LatLng(-12.082698, -77.050695), LatLng(-12.082839, -77.051067), LatLng(-12.083027, -77.051554), LatLng(-12.083153, -77.051858), LatLng(-12.083246, -77.052121), LatLng(-12.083349, -77.052434), LatLng(-12.083426, -77.052749), LatLng(-12.083494, -77.053144), LatLng(-12.083507, -77.05345), LatLng(-12.083506, -77.053703), LatLng(-12.083485, -77.053995), LatLng(-12.083454, -77.054198), LatLng(-12.083792, -77.054418), LatLng(-12.083822, -77.054438), LatLng(-12.084153, -77.054653), LatLng(-12.08453, -77.054903), LatLng(-12.084581, -77.054933), LatLng(-12.084662, -77.054985), LatLng(-12.085308, -77.055407), LatLng(-12.085849, -77.055772), LatLng(-12.085896, -77.055808), LatLng(-12.086175, -77.056024), LatLng(-12.086234, -77.056078), LatLng(-12.086283, -77.056129), LatLng(-12.086323, -77.056189), LatLng(-12.086348, -77.056263), LatLng(-12.086397, -77.056305), LatLng(-12.086597, -77.056484), LatLng(-12.08675, -77.05661), LatLng(-12.08678, -77.056634), LatLng(-12.087015, -77.056824), LatLng(-12.087164, -77.056947), LatLng(-12.087219, -77.056993), LatLng(-12.087251, -77.057023), LatLng(-12.087327, -77.057019), LatLng(-12.087367, -77.057017), LatLng(-12.087416, -77.057026), LatLng(-12.087449, -77.057046), LatLng(-12.087461, -77.057062), LatLng(-12.087477, -77.057085), LatLng(-12.087493, -77.057117), LatLng(-12.087501, -77.057164), LatLng(-12.087487, -77.057215), LatLng(-12.087454, -77.057249), LatLng(-12.087427, -77.05727), LatLng(-12.087395, -77.057285), LatLng(-12.087337, -77.057306), LatLng(-12.087258, -77.057326), LatLng(-12.08719, -77.057396), LatLng(-12.087065, -77.057545), LatLng(-12.086857, -77.057802), LatLng(-12.08729, -77.058161), LatLng(-12.08734, -77.058204), LatLng(-12.087338, -77.058207), LatLng(-12.087175, -77.058418), LatLng(-12.087259, -77.058486), LatLng(-12.087524, -77.058708), LatLng(-12.087726, -77.058874), LatLng(-12.088012, -77.059107), LatLng(-12.088311, -77.059352), LatLng(-12.088587, -77.059584), LatLng(-12.088705, -77.059679), LatLng(-12.088809, -77.059526), LatLng(-12.088933, -77.059343), LatLng(-12.089064, -77.059147), LatLng(-12.089193, -77.058954), LatLng(-12.089306, -77.058779), LatLng(-12.089363, -77.058689), LatLng(-12.08946, -77.058546), LatLng(-12.08956, -77.058399), LatLng(-12.089685, -77.058214), LatLng(-12.089815, -77.0582), LatLng(-12.089981, -77.057772), LatLng(-12.089921, -77.057728), LatLng(-12.089719, -77.057584), LatLng(-12.089387, -77.057347), LatLng(-12.089155, -77.057187), LatLng(-12.088578, -77.056798), LatLng(-12.088294, -77.056608), LatLng(-12.087951, -77.056375), LatLng(-12.087709, -77.05619), LatLng(-12.087683, -77.056166), LatLng(-12.087629, -77.05611), LatLng(-12.087476, -77.055927), LatLng(-12.087234, -77.055660), LatLng(-12.087001, -77.055346), LatLng(-12.0867, -77.054973), LatLng(-12.0866, -77.054846), LatLng(-12.086521, -77.054747), LatLng(-12.086349, -77.054531), LatLng(-12.086054, -77.054162), LatLng(-12.085891, -77.053958), LatLng(-12.085744, -77.053776), LatLng(-12.085618, -77.053618), LatLng(-12.085249, -77.053162), LatLng(-12.084942, -77.052777), LatLng(-12.084762, -77.05255), LatLng(-12.084656, -77.052421), LatLng(-12.084428, -77.052143), LatLng(-12.08425, -77.051927), LatLng(-12.08423, -77.0519), LatLng(-12.084114, -77.051753), LatLng(-12.084095, -77.051729), LatLng(-12.084054, -77.051678), LatLng(-12.084024, -77.051617), LatLng(-12.084084, -77.051585), LatLng(-12.084152, -77.051547), LatLng(-12.08427, -77.051483), LatLng(-12.084411, -77.051406), LatLng(-12.084519, -77.051345), LatLng(-12.084653, -77.051273), LatLng(-12.084768, -77.051211), LatLng(-12.084885, -77.051149), LatLng(-12.084983, -77.051097), LatLng(-12.0851, -77.051034), LatLng(-12.085217, -77.050967), LatLng(-12.085329, -77.050908), LatLng(-12.085381, -77.050877), LatLng(-12.085411, -77.050861), LatLng(-12.085629, -77.050753), LatLng(-12.085932, -77.050594), LatLng(-12.086163, -77.050472), LatLng(-12.086479, -77.050304), LatLng(-12.086701, -77.050176), LatLng(-12.086822, -77.050165), LatLng(-12.086763, -77.050129), LatLng(-12.086728, -77.050106), LatLng(-12.086481, -77.049955), LatLng(-12.08623, -77.049797), LatLng(-12.086013, -77.049658), LatLng(-12.085834, -77.049523), LatLng(-12.085622, -77.049351), LatLng(-12.085538, -77.049269), LatLng(-12.085349, -77.049082), LatLng(-12.085183, -77.048901), LatLng(-12.085129, -77.048847), LatLng(-12.085113, -77.048828), LatLng(-12.085051, -77.048761), LatLng(-12.084981, -77.048682), LatLng(-12.084805, -77.04848), LatLng(-12.084482, -77.04811), LatLng(-12.0842, -77.047783), LatLng(-12.084015, -77.047588), LatLng(-12.083963, -77.04753), LatLng(-12.083816, -77.047366), LatLng(-12.08332, -77.046802), LatLng(-12.082994, -77.046435), LatLng(-12.082757, -77.046156),
];

const List<LatLng> _sector9Polygon = [
  LatLng(-12.084276, -77.05167), LatLng(-12.084305, -77.051713), LatLng(-12.084363, -77.051788), LatLng(-12.084538, -77.052), LatLng(-12.08484, -77.052371), LatLng(-12.085089, -77.052675), LatLng(-12.085107, -77.052699), LatLng(-12.085374, -77.053029), LatLng(-12.085591, -77.053307), LatLng(-12.085757, -77.053524), LatLng(-12.085776, -77.05355), LatLng(-12.085944, -77.053669), LatLng(-12.086141, -77.05401), LatLng(-12.086363, -77.054286), LatLng(-12.086558, -77.054527), LatLng(-12.08673, -77.054738), LatLng(-12.086896, -77.054941), LatLng(-12.087103, -77.055195), LatLng(-12.087255, -77.055378), LatLng(-12.087439, -77.055603), LatLng(-12.087557, -77.055755), LatLng(-12.08767, -77.055896), LatLng(-12.08774, -77.055985), LatLng(-12.087818, -77.056058), LatLng(-12.087842, -77.056077), LatLng(-12.08789, -77.056113), LatLng(-12.087943, -77.056154), LatLng(-12.088166, -77.0563), LatLng(-12.08842, -77.056473), LatLng(-12.088699, -77.056668), LatLng(-12.088986, -77.056864), LatLng(-12.09023, -77.05703), LatLng(-12.089505, -77.057215), LatLng(-12.089759, -77.057388), LatLng(-12.090024, -77.057572), LatLng(-12.090085, -77.057615), LatLng(-12.090152, -77.057519), LatLng(-12.090247, -77.057378), LatLng(-12.090334, -77.057245), LatLng(-12.090411, -77.057131), LatLng(-12.090509, -77.056982), LatLng(-12.090653, -77.056767), LatLng(-12.090748, -77.056625), LatLng(-12.090846, -77.05647), LatLng(-12.090929, -77.056321), LatLng(-12.091049, -77.05614), LatLng(-12.091166, -77.055964), LatLng(-12.091276, -77.0558), LatLng(-12.091395, -77.055619), LatLng(-12.09147, -77.055509), LatLng(-12.091543, -77.055399), LatLng(-12.091573, -77.055352), LatLng(-12.091716, -77.055143), LatLng(-12.091805, -77.055007), LatLng(-12.09191, -77.054847), LatLng(-12.092106, -77.054555), LatLng(-12.092256, -77.05433), LatLng(-12.092368, -77.054158), LatLng(-12.09249, -77.053977), LatLng(-12.092604, -77.053804), LatLng(-12.092725, -77.053623), LatLng(-12.092838, -77.053452), LatLng(-12.092908, -77.053349), LatLng(-12.092947, -77.05329), LatLng(-12.092878, -77.053258), LatLng(-12.09261, -77.053122), LatLng(-12.092132, -77.052877), LatLng(-12.09181, -77.052713), LatLng(-12.091411, -77.05251), LatLng(-12.091008, -77.052304), LatLng(-12.09068, -77.052135), LatLng(-12.090348, -77.051965), LatLng(-12.089968, -77.051768), LatLng(-12.089705, -77.051635), LatLng(-12.089124, -77.051342), LatLng(-12.088569, -77.051059), LatLng(-12.088172, -77.050854), LatLng(-12.087959, -77.050749), LatLng(-12.087663, -77.050601), LatLng(-12.087304, -77.050417), LatLng(-12.086978, -77.050249), LatLng(-12.086896, -77.050294), LatLng(-12.086635, -77.050427), LatLng(-12.08635, -77.050578), LatLng(-12.086013, -77.050753), LatLng(-12.085755, -77.050892), LatLng(-12.085506, -77.051024), LatLng(-12.085288, -77.051142), LatLng(-12.08505, -77.051267), LatLng(-12.084908, -77.051347), LatLng(-12.084682, -77.051463), LatLng(-12.084471, -77.051572),
];

final Map<String, List<LatLng>> _sectorPolygons = {
  '1': _sector1Polygon,
  '2': _sector2Polygon,
  '3': _sector3Polygon,
  '4': _sector4Polygon,
  '5': _sector5Polygon,
  '6': _sector6Polygon,
  '7': _sector7Polygon,
  '8': _sector8Polygon,
  '9': _sector9Polygon,
};

class MapaScreen extends StatefulWidget {
  const MapaScreen({super.key});

  @override
  State<MapaScreen> createState() => _MapaScreenState();
}

class _MapaScreenState extends State<MapaScreen> {
  final MapController _mapController = MapController();
  final IncidentesService _incidentesService = IncidentesService();
  final PrediccionesService _prediccionesService = PrediccionesService();

  // Coordenadas de incidentes para el KDE del heatmap (solo lat/lng, sin modelo completo)
  List<List<double>> _coordenadasHeatmap = [];

  List<Prediccion> _prediccionesPorCuadrante = [];
  bool _isLoading = true;
  bool _isDarkMode = true;

  // Toggles de capas del mapa (coincidentes con el dashboard web)
  bool _mostrarRiesgo = true;
  bool _mostrarHeatmap = false;

  // Leyenda cerrada por defecto
  bool _mostrarLeyenda = false;

  // Zoom actual del mapa (para visibilidad de etiquetas de cuadrante desde zoom 14)
  double _zoomActual = 14.5;

  // Búsqueda de direcciones con Nominatim
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  // Imagen del heatmap generada en memoria
  MemoryImage? _heatmapImage;


  // Centroides y geometría pre-calculada para optimización masiva de FPS
  final Map<String, LatLng> _cuadranteCentroids = {};
  final Map<String, LatLng> _sectorCentroids = {};
  final Map<String, List<LatLng>> _cuadrantePoints = {};

  // Franja horaria actual de Lima (UTC-5)
  late Timer _clockTimer;
  String _franjaActual = '';

  @override
  void initState() {
    super.initState();
    _franjaActual = AppConstants.getFranjaActual();
    _clockTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) {
          setState(() => _franjaActual = AppConstants.getFranjaActual());
        }
      },
    );
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _clockTimer.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _loadGeoJson(),
        _prediccionesService.getPrediccionesMapa(franjaHoraria: _franjaActual),
        _incidentesService.getCoordenadasHeatmap(),
      ]);

      if (mounted) {
        final geoData = results[0] as Map<String, dynamic>?;
        if (geoData != null) {
          _calculateGeometryCentroids(geoData);
        }

        setState(() {
          _prediccionesPorCuadrante = results[1] as List<Prediccion>;
          _coordenadasHeatmap = results[2] as List<List<double>>;
          _isLoading = false;
        });
        _generateHeatmap();
      }
    } catch (e) {
      debugPrint('ERROR _loadData: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Carga el GeoJSON de los 52 cuadrantes desde los assets de la app
  Future<Map<String, dynamic>?> _loadGeoJson() async {
    try {
      final String data = await rootBundle.loadString('assets/Cuadrantes.geojson');
      return json.decode(data) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ERROR cargando GeoJSON: $e');
      return null;
    }
  }

  /// Cálculo geométrico exacto de centroides (Teorema de Green / Polígonos de Mapa.jsx)
  void _calculateGeometryCentroids(Map<String, dynamic> geojson) {
    _cuadranteCentroids.clear();
    _sectorCentroids.clear();
    _cuadrantePoints.clear();

    final features = geojson['features'] as List<dynamic>;
    final Map<String, List<LatLng>> sectorQuadrantPoints = {};

    for (final f in features) {
      final props = f['properties'] as Map<String, dynamic>;
      final nombre = props['cuadrante']?.toString() ?? '';
      final sectorMatch = RegExp(r'^\d+').firstMatch(nombre);
      final sectorId = sectorMatch?.group(0) ?? '';

      final geometry = f['geometry'] as Map<String, dynamic>;
      final type = geometry['type'] as String;
      final coordinates = geometry['coordinates'] as List<dynamic>;
      
      if (type == 'Polygon') {
        final ring = coordinates[0] as List<dynamic>;
        
        // Cachear las coordenadas para evitar reconstrucción en 60fps
        final parsedPoints = ring
            .map((c) => LatLng(
                  (c[1] as num).toDouble(),
                  (c[0] as num).toDouble(),
                ))
            .toList();
        _cuadrantePoints[nombre] = parsedPoints;

        final n = ring.length - 1;
        double cx = 0, cy = 0, area = 0;
        for (int i = 0; i < n; i++) {
          final double x0 = (ring[i][0] as num).toDouble();
          final double y0 = (ring[i][1] as num).toDouble();
          final double x1 = (ring[i + 1][0] as num).toDouble();
          final double y1 = (ring[i + 1][1] as num).toDouble();
          final double a = x0 * y1 - x1 * y0;
          area += a;
          cx += (x0 + x1) * a;
          cy += (y0 + y1) * a;
        }
        area /= 2;
        double centroidLng, centroidLat;
        if (area != 0) {
          centroidLng = cx / (6 * area);
          centroidLat = cy / (6 * area);
        } else {
          centroidLng = ring.fold<double>(0, (s, p) => s + (p[0] as num).toDouble()) / ring.length;
          centroidLat = ring.fold<double>(0, (s, p) => s + (p[1] as num).toDouble()) / ring.length;
        }

        final centroid = LatLng(centroidLat, centroidLng);
        _cuadranteCentroids[nombre] = centroid;

        sectorQuadrantPoints.putIfAbsent(sectorId, () => []).add(centroid);
      }
    }

    // Calcula los centroides de sector promediando sus cuadrantes
    sectorQuadrantPoints.forEach((sectorId, centroids) {
      double latSum = 0, lngSum = 0;
      for (final c in centroids) {
        latSum += c.latitude;
        lngSum += c.longitude;
      }
      double sLat = latSum / centroids.length;
      double sLng = lngSum / centroids.length;

      // Ajuste específico para el Sector 8 (forma cóncava) idéntico a Mapa.jsx
      if (sectorId == '8') {
        final mid8 = ['8B1', '8B2'].map((id) => _cuadranteCentroids[id]).whereType<LatLng>().toList();
        if (mid8.isNotEmpty) {
          sLat = mid8.fold<double>(0, (s, p) => s + p.latitude) / mid8.length;
          sLng = mid8.fold<double>(0, (s, p) => s + p.longitude) / mid8.length;
        }
      }
      _sectorCentroids[sectorId] = LatLng(sLat, sLng);
    });
  }

  /// Genera el heatmap KDE de densidad de incidentes históricos en isolate separado.
  /// Idéntico al algoritmo getKdeColor de Mapa.jsx — misma paleta y bandwidth h=0.0028.
  Future<void> _generateHeatmap() async {
    if (!_mostrarHeatmap || _coordenadasHeatmap.isEmpty) {
      if (mounted) setState(() => _heatmapImage = null);
      return;
    }

    final pixels = await compute(_calcularHeatmapPixels, _coordenadasHeatmap);

    ui.decodeImageFromPixels(
      pixels,
      150,
      150,
      ui.PixelFormat.rgba8888,
      (ui.Image img) async {
        final ByteData? byteData =
            await img.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null && mounted) {
          setState(() {
            _heatmapImage = MemoryImage(byteData.buffer.asUint8List());
          });
        }
      },
    );
  }

  // Búsqueda de direcciones usando Nominatim
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchNominatim(query);
    });
  }

  Future<void> _searchNominatim(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': '$query, Jesús María, Lima, Perú',
          'format': 'json',
          'limit': 5,
          'bounded': 1,
          'viewbox': '-77.070,-12.055,-77.025,-12.095',
        },
        options: Options(headers: {'User-Agent': 'SafePointApp/1.0'}),
      );
      if (response.statusCode == 200 && response.data is List) {
        if (mounted) setState(() => _searchResults = response.data as List);
      }
    } catch (e) {
      debugPrint('ERROR búsqueda Nominatim: $e');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(dynamic result) {
    final lat = double.parse(result['lat']);
    final lon = double.parse(result['lon']);
    _mapController.move(LatLng(lat, lon), 17);
    setState(() {
      _searchResults = [];
      _searchController.clear();
    });
    _searchFocus.unfocus();
  }

  void _zoomIn() => _mapController.move(
      _mapController.camera.center, _mapController.camera.zoom + 1);

  void _zoomOut() => _mapController.move(
      _mapController.camera.center, _mapController.camera.zoom - 1);

  void _resetRotation() => _mapController.rotate(0.0);

  // Capa de Estructura de cuadrantes (siempre visible):
  // Con riesgo ON: relleno de riesgo (0.21 opacidad) y bordes sólidos de riesgo (#1.5px)
  // Con riesgo OFF: relleno transparente (0.03 azul) y divisiones finas sólidas rojas (#F87171, 1.2px) idéntico a Mapa.jsx
  List<Polygon> _buildEstructuraPoligonos() {
    if (_cuadrantePoints.isEmpty) return [];

    return _cuadrantePoints.entries.map((entry) {
      final cuadranteId = entry.key;
      final points = entry.value;

      final pred = _prediccionesPorCuadrante.firstWhere(
        (p) => p.cuadrante == cuadranteId,
        orElse: () => Prediccion(
          id: 0,
          fechaPrediccion: DateTime.now(),
          probabilidad: 0,
          creadoEn: DateTime.now(),
        ),
      );

      if (_mostrarRiesgo) {
        Color color;
        final nivelRiesgo = pred.nivelRiesgo;
        if (nivelRiesgo == 2) {
          color = AppTheme.riskHigh;
        } else if (nivelRiesgo == 1) {
          color = AppTheme.riskMed;
        } else if (nivelRiesgo == 0) {
          color = AppTheme.riskLow;
        } else {
          color = AppTheme.textMuted;
        }

        return Polygon(
          points: points,
          color: color.withValues(alpha: 0.21),
          borderStrokeWidth: 1.5,
          borderColor: color.withValues(alpha: 1.0),
          isDotted: false,
        );
      } else {
        return Polygon(
          points: points,
          color: const Color(0xFF3B82F6).withValues(alpha: 0.03),
          borderStrokeWidth: 1.2,
          borderColor: const Color(0xFFF87171),
          isDotted: false,
        );
      }
    }).toList();
  }

  // Capa de Bordes de sector (Sector Outlines):
  // Solo se muestran cuando riesgo está OFF (#1E40AF sólido, 3.0px)
  List<Polygon> _buildSectorOutlines() {
    if (_mostrarRiesgo) return [];

    return _sectorPolygons.entries.map((entry) {
      return Polygon(
        points: entry.value,
        color: Colors.transparent,
        borderStrokeWidth: 3.0,
        borderColor: const Color(0xFF1E40AF),
        isDotted: false,
      );
    }).toList();
  }

  // Panel inferior para activar o desactivar capas del mapa
  void _showFilterPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Capas del Mapa',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Activa o desactiva las capas visuales',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 20),
              _LayerToggle(
                icon: Icons.warning_amber_rounded,
                label: 'Predicción de Riesgo',
                sublabel: 'Coloreado por nivel de riesgo (Alto, Medio, Bajo)',
                value: _mostrarRiesgo,
                onChanged: (val) {
                  setModalState(() => _mostrarRiesgo = val);
                  setState(() {});
                },
              ),
              const SizedBox(height: 12),
              _LayerToggle(
                icon: Icons.whatshot_rounded,
                label: 'Mapa de Calor',
                sublabel: 'Densidad de incidentes históricos',
                value: _mostrarHeatmap,
                onChanged: (val) {
                  setModalState(() => _mostrarHeatmap = val);
                  setState(() {});
                  _generateHeatmap();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const darkTile = 'https://api.maptiler.com/maps/basic-v2-dark/256/{z}/{x}/{y}.png?key=jPBrASxMmEi3FPAa6tvR';
    const lightTile = 'https://api.maptiler.com/maps/streets-v2/256/{z}/{x}/{y}.png?key=jPBrASxMmEi3FPAa6tvR';
    final tileUrl = _isDarkMode ? darkTile : lightTile;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Mapa principal
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(
                      AppConstants.jesusMariaLat,
                      AppConstants.jesusMariaLng,
                    ),
                    initialZoom: 14.5,
                    maxZoom: 16,
                    minZoom: 12,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
                    // Manejo dinámico del nivel de zoom en cualquier gesto de mapa
                    onMapEvent: (event) {
                      final currentZoom = event.camera.zoom;
                      final wasAbove = _zoomActual >= 14.8;
                      final isAbove = currentZoom >= 14.8;
                      _zoomActual = currentZoom;
                      if (wasAbove != isAbove) {
                        setState(() {});
                      }
                    },
                  ),
                  children: [
                    // 1. Capa base del mapa (MapTiler Dark / Streets)
                    TileLayer(
                      urlTemplate: tileUrl,
                      userAgentPackageName: 'com.safepoint.mobile',
                      maxZoom: 19,
                    ),
                    // 2. Capa de heatmap de densidad de incidentes (si activo)
                    if (_mostrarHeatmap && _heatmapImage != null)
                      OverlayImageLayer(
                        overlayImages: [
                          OverlayImage(
                            bounds: LatLngBounds(
                              const LatLng(-12.095, -77.070),
                              const LatLng(-12.055, -77.025),
                            ),
                            imageProvider: _heatmapImage!,
                            opacity: 0.65,
                          ),
                        ],
                      ),
                    // 3. Capa de Estructura de cuadrantes (rellenos y bordes)
                    PolygonLayer(polygons: _buildEstructuraPoligonos()),
                    // 4. Capa de Bordes de sector (solo si riesgo OFF)
                    if (!_mostrarRiesgo)
                      PolygonLayer(polygons: _buildSectorOutlines()),
                    // 5. Capa de Labels de sector (visibles únicamente cuando zoom < 14.8 para evitar solapamientos)
                    if (_zoomActual < 14.8)
                      MarkerLayer(
                        markers: AppConstants.nombresSectores.entries.map((entry) {
                          final sectorId = entry.key;
                          final centroide = _sectorCentroids[sectorId] ??
                              LatLng(
                                AppConstants.centroideSector(sectorId)[0],
                                AppConstants.centroideSector(sectorId)[1],
                              );
                          return Marker(
                            point: centroide,
                            width: 100,
                            height: 22,
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Halo (Borde exterior optimizado)
                                  Text(
                                    'SECTOR $sectorId',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = 3.0
                                        ..color = const Color.fromRGBO(15, 23, 42, 0.95),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  // Texto interior
                                  Text(
                                    'SECTOR $sectorId',
                                    style: const TextStyle(
                                      color: Color(0xFFF8FAFC),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    // 6. Capa de Labels de cuadrante (visibles cuando zoom >= 14.8 al acercarse)
                    if (_zoomActual >= 14.8)
                      MarkerLayer(
                        markers: _cuadranteCentroids.entries.map((entry) {
                          return Marker(
                            point: entry.value,
                            width: 44,
                            height: 20,
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Halo (Borde exterior optimizado)
                                  Text(
                                    entry.key,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      foreground: Paint()
                                        ..style = PaintingStyle.stroke
                                        ..strokeWidth = 2.0
                                        ..color = const Color.fromRGBO(0, 0, 0, 0.8),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  // Texto interior
                                  Text(
                                    entry.key,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                  ],
                ),

          // Barra de búsqueda superior
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search,
                                color: AppTheme.textMuted, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocus,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: 'Buscar zona o dirección...',
                                  hintStyle: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 13),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      EdgeInsets.symmetric(vertical: 10),
                                ),
                                onChanged: _onSearchChanged,
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                  _searchFocus.unfocus();
                                },
                                child: const Icon(Icons.close,
                                    color: AppTheme.textMuted, size: 18),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Botón para abrir el panel de capas
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.tune, color: Colors.white),
                        onPressed: _showFilterPanel,
                      ),
                    ),
                  ],
                ),
                // Resultados de búsqueda desplegables
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.98),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _searchResults.take(5).map((result) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on_outlined,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                          title: Text(
                            result['display_name'] ?? '',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),

          // Franja horaria activa (formato corto)
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 8),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time,
                      color: AppTheme.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    AppConstants.franjaCorta(_franjaActual),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Controles del mapa (zoom, rotación, modo día/noche)
          Positioned(
            right: 16,
            bottom: 30,
            child: Column(
              children: [
                MapControlButton(
                  icon: _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  onPressed: () {
                    setState(() => _isDarkMode = !_isDarkMode);
                    _generateHeatmap();
                  },
                ),
                const SizedBox(height: 8),
                MapControlButton(
                  icon: Icons.explore_outlined,
                  onPressed: _resetRotation,
                ),
                const SizedBox(height: 8),
                MapControlButton(icon: Icons.add, onPressed: _zoomIn),
                const SizedBox(height: 4),
                MapControlButton(icon: Icons.remove, onPressed: _zoomOut),
                const SizedBox(height: 8),
                // Vuelve al centro del distrito
                MapControlButton(
                  icon: Icons.my_location,
                  onPressed: () {
                    _mapController.move(
                      const LatLng(AppConstants.jesusMariaLat,
                          AppConstants.jesusMariaLng),
                      14.5,
                    );
                    _resetRotation();
                  },
                ),
              ],
            ),
          ),

          // Leyenda de niveles de riesgo o modo estructura
          Positioned(
            left: 16,
            bottom: 30,
            child: _mostrarLeyenda
                ? Container(
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 190),
                    decoration: BoxDecoration(
                      color: AppTheme.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _mostrarRiesgo
                                  ? 'NIVEL DE RIESGO'
                                  : 'MODO ESTRUCTURA',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _mostrarLeyenda = false),
                              child: const Icon(Icons.close,
                                  color: AppTheme.textMuted, size: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_mostrarRiesgo) ...[
                          const MapLegendItem(
                            color: AppTheme.riskHigh,
                            label: 'Alto',
                            description: 'Mayor actividad delictiva',
                          ),
                          const SizedBox(height: 6),
                          const MapLegendItem(
                            color: AppTheme.riskMed,
                            label: 'Medio',
                            description: 'Actividad moderada',
                          ),
                          const SizedBox(height: 6),
                          const MapLegendItem(
                            color: AppTheme.riskLow,
                            label: 'Bajo',
                            description: 'Menor actividad delictiva',
                          ),
                        ] else ...[
                          const Row(
                            children: [
                              Icon(Icons.crop_free,
                                  color: Color(0xFF1E40AF), size: 14),
                              SizedBox(width: 6),
                              Text('Sectores (1-9)',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(Icons.grid_on,
                                  color: Color(0xFFF87171), size: 14),
                              SizedBox(width: 6),
                              Text('52 Cuadrantes',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 11)),
                            ],
                          ),
                        ],
                        if (_mostrarHeatmap) ...[
                          const SizedBox(height: 10),
                          const Divider(color: AppTheme.border, height: 1),
                          const SizedBox(height: 8),
                          const Text(
                            'DENSIDAD HISTÓRICA',
                            style: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF22c55e),
                                  Color(0xFFfacc15),
                                  Color(0xFFf97316),
                                  Color(0xFFef4444),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Baja',
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 9)),
                              Text('Alta',
                                  style: TextStyle(
                                      color: AppTheme.textMuted, fontSize: 9)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  )
                : MapControlButton(
                    icon: Icons.info_outline,
                    onPressed: () => setState(() => _mostrarLeyenda = true),
                  ),
          ),

          // Indicador de búsqueda en progreso
          if (_isSearching)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: const LinearProgressIndicator(
                color: AppTheme.primary,
                minHeight: 2,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Cálculo del heatmap en isolate separado (top-level para compute) ────────
Uint8List _calcularHeatmapPixels(List<List<double>> incidentes) {
  const double minLat = -12.095, maxLat = -12.055;
  const double minLng = -77.070, maxLng = -77.025;
  const int gridWidth = 150, gridHeight = 150;
  const double dLat = (maxLat - minLat) / gridHeight;
  const double dLng = (maxLng - minLng) / gridWidth;
  final List<Float32List> grid =
      List.generate(gridHeight, (_) => Float32List(gridWidth));
  const double h = 0.0028;
  const double radiusY = h / dLat;
  const double radiusX = h / dLng;

  for (final inc in incidentes) {
    final lat = inc[0];
    final lng = inc[1];
    if (lat < minLat || lat > maxLat || lng < minLng || lng > maxLng) continue;
    final double ix = (lng - minLng) / dLng;
    final double iy = (lat - minLat) / dLat;
    final int minY = (iy - radiusY).floor().clamp(0, gridHeight - 1);
    final int maxY2 = (iy + radiusY).ceil().clamp(0, gridHeight - 1);
    final int minX = (ix - radiusX).floor().clamp(0, gridWidth - 1);
    final int maxX2 = (ix + radiusX).ceil().clamp(0, gridWidth - 1);
    for (int y = minY; y <= maxY2; y++) {
      for (int x = minX; x <= maxX2; x++) {
        final double clat = minLat + (y + 0.5) * dLat;
        final double clng = minLng + (x + 0.5) * dLng;
        final double dy = clat - lat;
        final double dx = (clng - lng) * 0.978;
        final double dist = dx * dx + dy * dy;
        if (dist < h * h) {
          final double u = math.sqrt(dist) / h;
          grid[y][x] += (1 - u * u) * (1 - u * u);
        }
      }
    }
  }

  double maxVal = 0.0001;
  for (int y = 0; y < gridHeight; y++) {
    for (int x = 0; x < gridWidth; x++) {
      if (grid[y][x] > maxVal) maxVal = grid[y][x];
    }
  }

  final Uint8List pixels = Uint8List(gridWidth * gridHeight * 4);
  for (int y = 0; y < gridHeight; y++) {
    for (int x = 0; x < gridWidth; x++) {
      final double val = grid[y][x] / maxVal;
      final int pixelY = gridHeight - 1 - y;
      final int pixelIdx = (pixelY * gridWidth + x) * 4;
      if (val > 0.015) {
        int r, g, b, a;
        if (val < 0.15) {
          final double t = val / 0.15;
          r = 250;
          g = 204;
          b = 21;
          a = (t * 0.35 * 255).round();
        } else if (val < 0.5) {
          final double t = (val - 0.15) / 0.35;
          r = (250 + t * (249 - 250)).round();
          g = (204 + t * (115 - 204)).round();
          b = (21 + t * (22 - 21)).round();
          a = ((0.35 + t * 0.40) * 255).round();
        } else {
          final double t = (val - 0.5) / 0.5;
          r = (249 + t * (239 - 249)).round();
          g = (115 + t * (68 - 115)).round();
          b = (22 + t * (68 - 22)).round();
          a = ((0.75 + t * 0.15) * 255).round();
        }
        final double alphaFactor = a / 255.0;
        pixels[pixelIdx] = (r * alphaFactor).round().clamp(0, 255);
        pixels[pixelIdx + 1] = (g * alphaFactor).round().clamp(0, 255);
        pixels[pixelIdx + 2] = (b * alphaFactor).round().clamp(0, 255);
        pixels[pixelIdx + 3] = a.clamp(0, 255);
      }
    }
  }
  return pixels;
}

// ── Toggle de capa del mapa ──────────────────────────────────────────────────
class _LayerToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LayerToggle({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value
              ? AppTheme.primary.withValues(alpha: 0.5)
              : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: value ? AppTheme.primary : AppTheme.textMuted, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: value ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  sublabel,
                  style:
                      const TextStyle(color: AppTheme.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primary,
            inactiveThumbColor: AppTheme.textMuted,
            inactiveTrackColor: AppTheme.border,
          ),
        ],
      ),
    );
  }
}
