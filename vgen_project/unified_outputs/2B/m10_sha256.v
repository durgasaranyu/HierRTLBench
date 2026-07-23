// SHA-256 hash core
// Message schedule: W[0..15] from input block; W[i] = sigma1(W[i-2]) + W[i-7]
//                   + sigma0(W[i-15]) + W[i-16]  for i=16..63
// sigma0(x) = ROTR(x,7)  XOR ROTR(x,18) XOR SHR(x,3)
// sigma1(x) = ROTR(x,17) XOR ROTR(x,19) XOR SHR(x,10)
// Compression: 64 rounds using working vars a,b,c,d,e,f,g,h
// T1 = h + Sigma1(e) + Ch(e,f,g) + K[i] + W[i]
// T2 = Sigma0(a) + Maj(a,b,c)
// Sigma0(x)=ROTR(x,2)^ROTR(x,13)^ROTR(x,22)
// Sigma1(x)=ROTR(x,6)^ROTR(x,11)^ROTR(x,25)
// Ch(e,f,g)=(e&f)^(~e&g)   Maj(a,b,c)=(a&b)^(a&c)^(b&c)
// Initial hash values H0..H7 (first 32 bits of fractional parts of sqrt of primes)
// K constants: first 32 bits of fractional parts of cube roots of first 64 primes
// All additions are mod 2^32
module sha256 (
    input  wire          clk,
    input  wire          reset,
    input  wire          start,
    input  wire [511:0]  block_in,   // one 512-bit message block
    output reg  [255:0]  hash_out,
    output reg           done
);
    // Registers: W[63:0][31:0], K[63:0][31:0] (ROM), a..h, round counter
    reg [7:0]     W0, W1, W2, W3, W4, W5, W6, W7, W8, W9, W10, W11, W12, W13, W14, W15;
    reg [7:0]     W16, W17, W18, W19, W20, W21, W22, W23, W24, W25, W26, W27, W28, W29, W30, W31;
    reg [7:0]     W32, W33, W34, W35, W36, W37, W38, W39, W40, W41, W42, W43, W44, W45, W46, W47;
    reg [7:0]     W48, W49, W50, W51, W52, W53, W54, W55, W56, W57, W58, W59, W60, W61, W62, W63;
    reg [7:0]     W64, W65, W66, W67, W68, W69, W70, W71, W72, W73, W74, W75, W76, W77, W78, W79;
    reg [7:0]     W80, W81, W82, W83, W84, W85, W86, W87, W88, W89, W90, W91, W92, W93, W94, W95;
    reg [7:0]     W96, W97, W98, W99, W100, W101, W102, W103, W104, W105, W106, W107, W108, W109, W110, W111;
    reg [7:0]     W112, W113, W114, W115, W116, W117, W118, W119, W120, W121, W122, W123, W124, W125, W126, W127;
    reg [7:0]     W128, W129, W130, W131, W132, W133, W134, W135, W136, W137, W138, W139, W140, W141, W142, W143;
    reg [7:0]     W144, W145, W146, W147, W148, W149, W150, W151, W152, W153, W154, W155, W156, W157, W158, W159;
    reg [7:0]     W160, W161, W162, W163, W164, W165, W166, W167, W168, W169, W170, W171, W172, W173, W174, W175;
    reg [7:0]     W176, W177, W178, W179, W180, W181, W182, W183, W184, W185, W186, W187, W188, W189, W190, W191;
    reg [7:0]     W192, W193, W194, W195, W196, W197, W198, W199, W200, W201, W202, W203, W204, W205, W206, W207;
    reg [7:0]     W208, W209, W210, W211, W212, W213, W214, W215, W216, W217, W218, W219, W220, W221, W222, W223;
    reg [7:0]     W224, W225, W226, W227, W228, W229, W230, W231, W232, W233, W234, W235, W236, W237, W238, W239;
    reg [7:0]     W240, W241, W242, W243, W244, W245, W246, W247, W248, W249, W250, W251, W252, W253, W254, W255;
    reg [7:0]     W256, W257, W258, W259, W260, W261, W262, W263, W264, W265, W266, W267, W268, W269, W270, W271;
    reg [7:0]     W272, W273, W274, W275, W276, W277, W278, W279, W280, W281, W282, W283, W284, W285, W286, W287;
    reg [7:0]     W288, W289, W290, W291, W292, W293, W294, W295, W296, W297, W298, W299, W300, W301, W302, W303;
    reg [7:0]     W304, W305, W306, W307, W308, W309, W310, W311, W312, W313, W314, W315, W316, W317, W318, W319;
    reg [7:0]     W320, W321, W322, W323, W324, W325, W326, W327, W328, W329, W330, W331, W332, W333, W334, W335;
    reg [7:0]     W336, W337, W338, W339, W340, W341, W342, W343, W344, W345, W346, W347, W348, W349, W350, W351;
    reg [7:0]     W352, W353, W354, W355, W356, W357, W358, W359, W360, W361, W362, W363, W364, W365, W366, W367;
    reg [7:0]     W368, W369, W370, W371, W372, W373, W374, W375, W376, W377, W378, W379, W380, W381, W382, W383;
    reg [7:0]     W384, W385, W386, W387, W388, W389, W390, W391, W392, W393, W394, W395, W396, W397, W398, W399;
    reg [7:0]     W400, W401, W402, W403, W404, W405, W406, W407, W408, W409, W410, W411, W412, W413, W414, W415;
    reg [7:0]     W416, W417, W418, W419, W420, W421, W422, W423, W424, W425, W426, W427, W428, W429, W430, W431;
    reg [7:0]     W
endmodule
