// FFT stages 2 and 3 combined. Stage2: pairs (0,2),(1,3),(4,6),(5,7).
// Stage3: pairs (0,1),(2,3),(4,5),(6,7) with respective twiddles.
module fft_stage23 (
    input  signed [127:0] s1re_flat, s1im_flat,
    output signed [127:0] s3re_flat, s3im_flat
);
    // input data
    reg signed [127:0] s1re, s1im;
    reg signed [127:0] s2re, s2im;
    // stage 1
    reg signed [127:0] s11re, s11im;
    reg signed [127:0] s12re, s12im;
    // stage 2
    reg signed [127:0] s21re, s21im;
    reg signed [127:0] s22re, s22im;
    // stage 3
    reg signed [127:0] s31re, s31im;
    reg signed [127:0] s32re, s32im;
    // stage 4
    reg signed [127:0] s41re, s41im;
    reg signed [127:0] s42re, s42im;
    // stage 5
    reg signed [127:0] s51re, s51im;
    reg signed [127:0] s52re, s52im;
    // stage 6
    reg signed [127:0] s61re, s61im;
    reg signed [127:0] s62re, s62im;
    // stage 7
    reg signed [127:0] s71re, s71im;
    reg signed [127:0] s72re, s72im;
    // stage 8
    reg signed [127:0] s81re, s81im;
    reg signed [127:0] s82re, s82im;
    // stage 9
    reg signed [127:0] s91re, s91im;
    reg signed [127:0] s92re, s92im;
    // stage 10
    reg signed [127:0] s101re, s101im;
    reg signed [127:0] s102re, s102im;
    // stage 11
    reg signed [127:0] s111re, s111im;
    reg signed [127:0] s112re, s112im;
    // stage 12
    reg signed [127:0] s121re, s121im;
    reg signed [127:0] s122re, s122im;
    // stage 13
    reg signed [127:0] s131re, s131im;
    reg signed [127:0] s132re, s132im;
    // stage 14
    reg signed [127:0] s141re, s141im;
    reg signed [127:0] s142re, s142im;
    // stage 15
    reg signed [127:0] s151re, s151im;
    reg signed [127:0] s152re, s152im;
    // stage 16
    reg signed [127:0] s161re, s161im;
    reg signed [127:0] s162re, s162im;
    // stage 17
    reg signed [127:0] s171re, s171im;
    reg signed [127:0] s172re, s172im;
    // stage 18
    reg signed [127:0] s181re, s181im;
    reg signed [127:0] s182re, s182im;
    // stage 19
    reg signed [127:0] s191re, s191im;
    reg signed [127:0] s192re, s192im;
    // stage 20
    reg signed [127:0] s201re, s201im;
    reg signed [127:0] s202re, s202im;
    // stage 21
    reg signed [127:0] s211re, s211im;
    reg signed [127:0] s212re, s212im;
    // stage 22
    reg signed [127:0] s221re, s221im;
    reg signed [127:0] s222re, s222im;
    // stage 23
    reg signed [127:0] s231re, s231im;
    reg signed [127:0] s232re, s232im;
    // stage 24
    reg signed [127:0] s241re, s241im;
    reg signed [127:0] s242re, s242im;
    // stage 25
    reg signed [127:0] s251re, s251im;
    reg signed [127:0] s252re, s252im;
    // stage 26
    reg signed [127:0] s261re, s261im;
    reg signed [127:0] s262re, s262im;
    // stage 27
    reg signed [127:0] s271re, s271im;
    reg signed [127:0] s272re, s272im;
    // stage 28
    reg signed [127:0] s281re, s281im;
    reg signed [127:0] s282re, s282im;
    // stage 29
    reg signed [127:0] s291re, s291im;
    reg signed [127:0] s292re, s292im;
    // stage 30
    reg signed [127:0] s301re, s301im;
    reg signed [127:0] s302re, s302im;
    // stage 31
    reg signed [127:0] s311re, s311im;
    reg signed [127:0] s312re, s312im;
    // stage 32
    reg signed [127:0] s321re, s321im;
    reg signed [127:0] s322re, s322im;
    // stage 33
    reg signed [127:0] s331re, s331im;
    reg signed [127:0] s332re, s332im;
    // stage 34
    reg signed [127:0] s341re, s341im;
    reg signed [127:0] s342re, s342im;
    // stage 35
    reg signed [127:0] s351re, s351im;
    reg signed [127:0] s352re, s352im;
    // stage 36
    reg signed [127:0] s361re, s361im;
    reg signed [127:0] s362re, s362im;
    // stage 37
    reg signed [127:0] s371re, s371im;
    reg signed [127:0] s372re, s372im;
    // stage 38
    reg signed [127:0] s381re, s381im;
    reg signed [127:0] s382re, s382im;
    // stage 39
    reg signed [127:0] s391re, s391im;
    reg signed [127:0] s392re, s392im;
    // stage 40
    reg signed [127:0] s401re, s401im;
    reg signed [127:0] s402re, s402im;
    // stage 41
    reg signed [127:0] s411re, s411im;
    reg signed [127:0] s412re, s412im;
    // stage 42
    reg signed [127:0] s421re, s421im;
    reg signed [127:0] s422re, s422im;
    // stage 43
    reg signed [127:0] s431re, s431im;
    reg signed [127:0] s432re, s432im;
    // stage 44
    reg signed [127:0] s441re, s441im;
    reg signed [127:0] s442re, s442im;
    // stage 45
    reg signed [127:0] s451re, s451im;
    reg signed [127:0] s452re, s452im;
    // stage 46
    reg signed [127:0] s461re, s461im;
    reg signed [127:0] s462re, s462im;
    // stage 47
    reg signed [127:0] s471re, s471im;
    reg signed [127:0] s472re, s472im;
    // stage 48
    reg signed [127:0] s481re, s481im;
    reg signed [127:0] s482re, s482im;
    // stage 49
    reg signed [127:0] s491re, s491im
endmodule
