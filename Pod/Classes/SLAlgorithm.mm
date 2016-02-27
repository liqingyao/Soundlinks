//
//  SLAlgorithm.m
//  microhoneTest
//
//  Created by LiQingyao on 16/2/22.
//  Copyright © 2016年 Pheroant. All rights reserved.
//

#import "SLAlgorithm.h"
#import <QuartzCore/QuartzCore.h>

// BPF Coefficient
#define FILTAP_BPF    201         //FIR BPF taps
#define BPF_STP_NM    9           //FIR BPF steps
#define BPF_CNT_F     8000        //FIR BPF cutoff frequency
#define BPF_MIN_Q     1           //FIR BPF minimum Q
#define BPF_MAX_Q     4           //FIR BPF maximum Q

// LPF Coefficient
#define FILTAP_LPF    67          //FIR LPF taps
#define LPF_STP_NM    5           //FIR LPF steps
#define LPF_MIN_FC    1200        //FIR LPF minimum cutoff frequency
#define LPF_MAX_FC    2800        //FIR LPF maximum cutoff frequency

// LPF Setting
#define LPF_GAIN      8
#define LPF_MGN       0.9

// Time Coefficient
#define TIME_COEF     1000        // (ms) Seeking redone every 172.8ms（actual 163ms）

// PT&AT Adjusting and Seeking Value
#define LIMG_TH       0.22
#define PA_L_ATT      0.25

// Rhythm Task Value
#define RY_MIN        2
#define RY_MAX        6
#define RY_LIM        16
#define RY_EN         2

// Data Detection Number
#define DT_NUM        6           // Display number

// Standard Deviation Minimum Value
#define SD_MIN_VAL    50

// Threshold Value
#define TH_1ST        0.125
#define TH_NUM        7

// Slot number
#define F_SLOT        5           //clock number for slot (in fs clock units)
#define F_SNC_FRM_PLS 7           //sample number for comparison from signal pulse

// Pre-Amble
#define F_PRA_1ST_COMT   0        //method for estimating center position of preamble 1st pulse 0: center of gravity, 1: center of axis
#define F_PLS_DET_W      12       //preamble pulse detect width (in slot units)
#define F_PRA_NGT_MAX    10       //preamble negate max width (in fs clock units)
#define F_PRA_23P_TLE    30       //preamble 2nd & 3rd pulse tolerant level error in comparison with preamble 1st pulse (in % units)
#define F_PRA_23P_SD_ON  1        //preamble 2nd & 3rd pulse standard deviation check on 1: on, 0: off

// Pre-Amble 1st Pulse
#define F_PRA_1ST_MIN    3        //preamble 1st pulse min width (in fs clock units)
#define F_PRA_1ST_TEP    10       //preamble 1st pulse tolerant error for position (in fs clock units: less than a value is effective)
#define F_PRA_1ST_TPN    2        //preamble 1st pulse tolerant position number (a value or more are effective)

// Pre-Amble 12 Nagate
#define F_PRA_NID0_W     9        //preamble negate & id 0 width (in slot units)

// Pre-Amble 23 Nagate
#define F_PRA_NID1_W     6        //preamble negate & id 1 width (in slot units)

// Pre-Amble end Nagate
#define F_PRA_NID2_W     6        //preamble negate & id 2 width (in slot units)

// Word Packet
#define F_KEY_DET_W      6        //key detect width (in slot units)
#define F_WD_ID_SU       2        //word packet id shift unit (in slot units)
#define F_WD_ID_W        2        //word packet id width (in slot units)

// ID
#define F_WD0_POS        0        //word packet id (0: a7) position (in [wd_id_su] units)
#define F_WD1_POS        0        //word packet id (1: a6) position (in [wd_id_su] units)
#define F_WD2_POS        0        //word packet id (2: a5) position (in [wd_id_su] units)
#define F_WD3_POS        0        //word packet id (3: a4) position (in [wd_id_su] units)
#define F_WD4_POS        0        //word packet id (4: a3) position (in [wd_id_su] units)
#define F_WD5_POS        0        //word packet id (5: a2) position (in [wd_id_su] units)
#define F_WD6_POS        0        //word packet id (6: a1) position (in [wd_id_su] units)
#define F_WD7_POS        0        //word packet id (7: a0) position (in [wd_id_su] units)
#define F_WD8_POS        0        //word packet id (8: b7) position (in [wd_id_su] units)
#define F_WD9_POS        0        //word packet id (9: b6) position (in [wd_id_su] units)
#define F_WD10_POS       0        //word packet id (10: b5) position (in [wd_id_su] units)
#define F_WD11_POS       0        //word packet id (11: b4) position (in [wd_id_su] units)
#define F_WD12_POS       0        //word packet id (12: b3) position (in [wd_id_su] units)
#define F_WD13_POS       0        //word packet id (13: b2) position (in [wd_id_su] units)
#define F_WD14_POS       0        //word packet id (14: b1) position (in [wd_id_su] units)
#define F_WD15_POS       0        //word packet id (15: b0) position (in [wd_id_su] units)


// Main BPF table
static double bpf_coef[FILTAP_BPF];
// BPF table
static double bpf_coef_tbl[BPF_STP_NM][FILTAP_BPF];
// Main LPF table
static double lpf_coef[FILTAP_LPF];
// LPF table
static double lpf_coef_tbl[LPF_STP_NM][FILTAP_LPF];

// Filter Process Declaration
static double *bpf_hamw, *lpf_hamw;
static double lpf_min_frq, lpf_ivl_frq;
static double bpf_min_q, bpf_ivl_q;
static double bpf_lft_frq, bpf_rgt_frq;
static float inGain = 1.0;
static int lpf_fcnum;
static float *bpfin, *lpfin;
static float *bpfout, *bpfnext, *pre_bpfout;
static float *lpfout, *lpfnext, *pre_lpfout;
static int bufferCounter = 0;

// Data Detection Process Declaration
static int msc_cn[1] = {0};
static int det_inf[100] = {0};
static double plt_peak[1] = {0};
static int main_init = 1;

// PT&AT Seeking and Adjusting Process Declaration
static double dtctTime, crntTime;
static double dm_dtctTime, dm_crntTime;
static int pa_lock_on = 0;
static int pa_seek_task = 1;
static double ib_peak[1] = {0};
static double ib_ave[1] = {0};
static int ib_avec[1] = {0};
static int pa_crnt_q = 0;
static int pa_period_min = 500;
static int pa_period_rls = 3000;

// AGC
int optimize = 1;

// Methods declaration
void BpfAbs(float *inBuffer, float bufferSize, float bpfin[], float bpfout[], float bpfnext[], double filtr[]);
void LpfDet(float bpfout[], float bufferSize, float lpfout[], float lpfnext[], float pre_bpfout[], float lpfin[], double filtr[], int msc_cn[], int det_inf[], double plt_peak[], double ib_peak[], double ib_ave[], int ib_avec[], int main_init);
void Pra1stPcn(int pra_1st_cn[], int pra_1st_rireki[], double pra_1st_soa[], double pra_1st_cog[], int msc_cn[], float sum, int pra_1st_min, int pra_1st_comt);
int Pra1stDistinction(int pra_1st_cn[], int pra_1st_rireki[], float pre_bpfout[], float bpfout[], double key_sta_val_0[], double key_sta_val_1[], double key_sta_val_2[], double key_sta_val_3[], double pra_pls_lvl[], int jj, int pra_1st_tep, int pra_1st_tpn);
int PlsNgtPrcs(int pra_ngt_cn, float sum, int pra_ngt_max);
int Pra2ndDistinction(float pre_bpfout[], float bpfout[], double key_sta_val_0[], double key_sta_val_1[], double key_sta_val_2[], double key_sta_val_3[], double pra_pls_lvl[], int jj, int sd_on, double dev[]);
int Pra3rdDistinction(float pre_bpfout[], float bpfout[], double key_sta_val_0[], double key_sta_val_1[], double key_sta_val_2[], double key_sta_val_3[], double pra_pls_lvl[], int jj, int sd_on, double dev[]);
int WordPacketDistinction(float pre_bpfout[], float bpfout[], double key_sta_val_0[], double key_sta_val_1[], double key_sta_val_2[], double key_sta_val_3[], double pra_pls_lvl, int jj, double dev[]);
int MinimumStandardDeviation(double current_val[], double key_sta_val_0[], double key_sta_val_1[], double key_sta_val_2[], double key_sta_val_3[], double dev[]);
void HamWdwFunc(double hamwdw[], int ntaps);
void Lpfdsn(double fc, double hamwdw[], double filtr[]);
void Bpfdsn(double fleft, double fright, double hamwdw[], double filtr[]);
void agcPTATTask();
void seekPTATTask();

@implementation SLAlgorithm

+ (void)initAlgorithmWithBufferSize:(UInt32)bufferSize {
    
    bpfin = (float *) calloc(bufferSize + FILTAP_BPF, sizeof(float));
    bpfout = (float *) calloc(bufferSize, sizeof(float));
    bpfnext = (float *) calloc(bufferSize, sizeof(float));
    pre_bpfout = (float *) calloc((FILTAP_LPF - 1) / 2 + F_SLOT * F_PLS_DET_W, sizeof(float));
    lpfin = (float *) calloc(bufferSize + FILTAP_LPF, sizeof(float));
    lpfout = (float *) calloc(bufferSize, sizeof(float));
    lpfnext = (float *) calloc(bufferSize, sizeof(float));
    pre_lpfout = (float *) calloc(bufferSize, sizeof(float));
    bpf_hamw = (double *) calloc(FILTAP_BPF, sizeof(double));
    lpf_hamw = (double *) calloc(FILTAP_LPF, sizeof(double));
    int fil_i;
    
    //LPF coefficient calculation
    HamWdwFunc(lpf_hamw, FILTAP_LPF);
    lpf_min_frq = LPF_MIN_FC;
    lpf_ivl_frq = (double)(LPF_MAX_FC - LPF_MIN_FC) / (LPF_STP_NM - 1);
    for (fil_i = 0; fil_i < LPF_STP_NM; fil_i++){
        Lpfdsn(lpf_min_frq + fil_i * lpf_ivl_frq, lpf_hamw, lpf_coef_tbl[fil_i]);
    }
    lpf_fcnum = (int)(LPF_STP_NM - 1) / 2;
    Lpfdsn(lpf_min_frq + lpf_fcnum * lpf_ivl_frq, lpf_hamw, lpf_coef);
    
    //BPF coefficient calculation
    HamWdwFunc(bpf_hamw, FILTAP_BPF);
    bpf_min_q = BPF_MIN_Q;
    bpf_ivl_q = (double)(BPF_MAX_Q - BPF_MIN_Q) / (BPF_STP_NM - 1);
    for (fil_i = 0; fil_i < BPF_STP_NM; fil_i++){
        bpf_lft_frq = BPF_CNT_F - (BPF_CNT_F / (bpf_min_q + fil_i * bpf_ivl_q)) / 2;
        bpf_rgt_frq = BPF_CNT_F + (BPF_CNT_F / (bpf_min_q + fil_i * bpf_ivl_q)) / 2;
        Bpfdsn(bpf_lft_frq, bpf_rgt_frq, bpf_hamw, bpf_coef_tbl[fil_i]);
    }
    pa_crnt_q = (int)(BPF_STP_NM - 1) / 2;
    bpf_lft_frq = BPF_CNT_F - (BPF_CNT_F / (bpf_min_q + pa_crnt_q * bpf_ivl_q)) / 2;
    bpf_rgt_frq = BPF_CNT_F + (BPF_CNT_F / (bpf_min_q + pa_crnt_q * bpf_ivl_q)) / 2;
    Bpfdsn(bpf_lft_frq, bpf_rgt_frq, bpf_hamw, bpf_coef);

}

// DSP functions
//----------------------------------------------------
// Band Pass Filter and absolute calculation
// With input:  inBuffer
//              bufferSize
//              calculation arguments: bpfin bpfnext
//              BPF taps coefficients(Q selection)
// With output: bpfout
//----------------------------------------------------
void BpfAbs(float *inBuffer, float bufferSize, float bpfin[], float bpfout[], float bpfnext[], double filtr[]) {
    
    int i, fr, j, jj, read, reminder, n, ilast;
    double sum;
    int n_data = bufferSize;
    int ls = bufferSize;
    int nfilter = FILTAP_BPF;
    
    for (i = 0; i<nfilter; i++){
        bpfin[i] = bpfnext[i];
    }
    for (fr = jj = ilast = 0;; fr++){
        read = fr*ls;
        reminder = n_data - read;
        n = ls;
        if (reminder<ls){
            ilast = 1;
            n = reminder;
        }
        if (n == 0) break;
        for (i = 0; i<n; i++){
            bpfin[i + nfilter] = inBuffer[read + i];
        }
        if (ilast == 1){
            for (i = 0; i<ls - n; i++){
                bpfin[i + n + nfilter] = 0.0;
            }
        }
        for (i = 0; i<n; i++){
            sum = 0.0;
            for (j = 0; j<nfilter; j++) sum += filtr[j] * bpfin[i + (nfilter - 1) - j];
            if (sum >= 1){
                sum = 1;
            }
            else if (sum <= -1){
                sum = -1;
            }
            //sum = fabs(sum);
            bpfout[jj++] = sum;
        }
        for (i = 0; i<nfilter; i++) bpfnext[i] = bpfin[ls + i];
        if (reminder<ls) break;
    }
    
    return;
}

//----------------------------------------------------
// Low Pass Filter and Detection
// With input:  bpfout
//              bufferSize
//              calculation arguments: lpfin lpfnext
//              LPF tap coefficients(Q selection)
// With output: lpfout
//----------------------------------------------------
void LpfDet(float bpfout[], float bufferSize, float lpfout[], float lpfnext[], float pre_bpfout[], float lpfin[], double filtr[], int msc_cn[], int det_inf[], double plt_peak[], double ib_peak[], double ib_ave[], int ib_avec[], int main_init) {
    
    int i, fr, j, jj, read, reminder, n, ilast;
    int ini_cl, ini_check;
    double sum;
    int n_data = bufferSize;
    int ls = bufferSize;
    int nfilter = FILTAP_LPF;
    
    static int mask_cn;
    static double key_sta_val[4][F_SNC_FRM_PLS];
    static double pra_pls_lvl[3];
    static int pra_1st_cn[TH_NUM], pra_1st_rireki[TH_NUM], pra_1st_done;
    static double pra_1st_soa[TH_NUM], pra_1st_cog[TH_NUM];
    static int pra_12n_cn, pra_23n_cn, pra_endn_cn;
    static double dev[4];
    static int wp_a_data = 0, wp_b_data = 0, wp_c_data = 0;
    
    int pra_ngt_max;                                            //Pre Amble Negate
    int pra_1st_end, pra_1st_min, pra_1st_tep, pra_1st_tpn;     //Pre Amble 1st
    int pra_12n_str, pra_12n_end, pra_12n_ck;                    //Pre Amble 12
    int pra_2nd_cnt, pra_2nd_ck;                                //Pre Amble 2nd Pulse
    int pra_23n_str, pra_23n_end, pra_23n_ck;                    //Pre Amble 23
    int pra_3rd_cnt, pra_3rd_ck;                                //Pre Amble 3rd Pulse
    int pra_endn_str, pra_endn_end, pra_endn_ck;                //Pre Amble end
    
    // Forward 8 word packet from a7 to a0
    int wp_a7_str, wp_a7_end, wp_a7_cnt;                //Word Packet 0 (a7)
    int wp_a6_str, wp_a6_end, wp_a6_cnt;                //Word Packet 1 (a6)
    int wp_a5_str, wp_a5_end, wp_a5_cnt;                //Word Packet 2 (a5)
    int wp_a4_str, wp_a4_end, wp_a4_cnt;                //Word Packet 0 (a4)
    int wp_a3_str, wp_a3_end, wp_a3_cnt;                //Word Packet 1 (a3)
    int wp_a2_str, wp_a2_end, wp_a2_cnt;                //Word Packet 2 (a2)
    int wp_a1_str, wp_a1_end, wp_a1_cnt;                //Word Packet 3 (a1)
    int wp_a0_str, wp_a0_end, wp_a0_cnt;                //Word Packet 4 (a0)
    
    // Backward 8 word packet from b7 to b0
    int wp_b7_str, wp_b7_end, wp_b7_cnt;                //Word Packet 8 (b7)
    int wp_b6_str, wp_b6_end, wp_b6_cnt;                //Word Packet 9 (b6)
    int wp_b5_str, wp_b5_end, wp_b5_cnt;                //Word Packet 10 (b5)
    int wp_b4_str, wp_b4_end, wp_b4_cnt;                //Word Packet 11 (b4)
    int wp_b3_str, wp_b3_end, wp_b3_cnt;                //Word Packet 12 (b3)
    int wp_b2_str, wp_b2_end, wp_b2_cnt;                //Word Packet 13 (b2)
    int wp_b1_str, wp_b1_end, wp_b1_cnt;                //Word Packet 14 (b1)
    int wp_b0_str, wp_b0_end, wp_b0_cnt;                //Word Packet 15 (b0)
    
    if (main_init == 1){
        mask_cn = 0;
        for (i = 0; i < 4; i++){
            for (ini_cl = 0; ini_cl < F_SNC_FRM_PLS; ini_cl++){
                key_sta_val[i][ini_cl] = 0;
            }
        }
        for (ini_cl = 0; ini_cl < 3; ini_cl++){
            pra_pls_lvl[ini_cl] = 0;
        }
        for (ini_cl = 0; ini_cl < TH_NUM; ini_cl++){
            pra_1st_cn[ini_cl] = 0; pra_1st_rireki[ini_cl] = 0;
            pra_1st_soa[ini_cl] = 0; pra_1st_cog[ini_cl] = 0;
        }
        for (ini_cl = 0; ini_cl < 4; ini_cl++){
            dev[ini_cl] = 0;
        }
        pra_1st_done = 0; pra_12n_cn = 0; pra_23n_cn = 0; pra_endn_cn = 0;
        wp_a_data = 0; wp_b_data = 0;  wp_c_data = 0;
    }
    
    //Preamble Negate
    pra_ngt_max = F_PRA_NGT_MAX;
    
    //Preamble 1st pulse
    pra_1st_end = F_PLS_DET_W * F_SLOT;
    pra_1st_min = F_PRA_1ST_MIN;
    pra_1st_tep = F_PRA_1ST_TEP;
    pra_1st_tpn = F_PRA_1ST_TPN;
    
    //Pre-Amble 12 Nagate
    pra_12n_str = pra_1st_end - F_SLOT;
    pra_12n_end = pra_12n_str + F_PRA_NID0_W * F_SLOT;
    
    //Preamble 2nd pulse
    pra_2nd_cnt = pra_12n_end + F_PLS_DET_W * F_SLOT / 2;
    
    //Pre-Amble 23 Nagate
    pra_23n_str = pra_12n_end + F_PLS_DET_W * F_SLOT;
    pra_23n_end = pra_23n_str + F_PRA_NID1_W * F_SLOT;
    
    //Preamble 3rd pulse
    pra_3rd_cnt = pra_23n_end + F_PLS_DET_W * F_SLOT / 2;
    
    //Pre-Amble end Nagate
    pra_endn_str = pra_23n_end + F_PLS_DET_W * F_SLOT;
    pra_endn_end = pra_endn_str + F_PRA_NID2_W * F_SLOT;
    
    //Word Packet 0 (a7)
    wp_a7_str = pra_endn_end;
    wp_a7_end = wp_a7_str + F_KEY_DET_W * F_SLOT;
    wp_a7_cnt = wp_a7_str + F_WD0_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 1 (a6)
    wp_a6_str = wp_a7_end;
    wp_a6_end = wp_a6_str + F_KEY_DET_W * F_SLOT;
    wp_a6_cnt = wp_a6_str + F_WD1_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 2 (a5)
    wp_a5_str = wp_a6_end;
    wp_a5_end = wp_a5_str + F_KEY_DET_W * F_SLOT;
    wp_a5_cnt = wp_a5_str + F_WD2_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 3 (a4)
    wp_a4_str = wp_a5_end;
    wp_a4_end = wp_a4_str + F_KEY_DET_W * F_SLOT;
    wp_a4_cnt = wp_a4_str + F_WD3_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 4 (a3)
    wp_a3_str = wp_a4_end;
    wp_a3_end = wp_a3_str + F_KEY_DET_W * F_SLOT;
    wp_a3_cnt = wp_a3_str + F_WD4_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 5 (a2)
    wp_a2_str = wp_a3_end;
    wp_a2_end = wp_a2_str + F_KEY_DET_W * F_SLOT;
    wp_a2_cnt = wp_a2_str + F_WD5_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 6 (a1)
    wp_a1_str = wp_a2_end;
    wp_a1_end = wp_a1_str + F_KEY_DET_W * F_SLOT;
    wp_a1_cnt = wp_a1_str + F_WD6_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 7 (a0)
    wp_a0_str = wp_a1_end;
    wp_a0_end = wp_a0_str + F_KEY_DET_W * F_SLOT;
    wp_a0_cnt = wp_a0_str + F_WD7_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    
    //Word Packet 8 (b7)
    wp_b7_str = wp_a0_end;
    wp_b7_end = wp_b7_str + F_KEY_DET_W * F_SLOT;
    wp_b7_cnt = wp_b7_str + F_WD8_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    
    //Word Packet 9 (b6)
    wp_b6_str = wp_b7_end;
    wp_b6_end = wp_b6_str + F_KEY_DET_W * F_SLOT;
    wp_b6_cnt = wp_b6_str + F_WD9_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 10 (b5)
    wp_b5_str = wp_b6_end;
    wp_b5_end = wp_b5_str + F_KEY_DET_W * F_SLOT;
    wp_b5_cnt = wp_b5_str + F_WD10_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 11 (b4)
    wp_b4_str = wp_b5_end;
    wp_b4_end = wp_b4_str + F_KEY_DET_W * F_SLOT;
    wp_b4_cnt = wp_b4_str + F_WD11_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 12 (b3)
    wp_b3_str = wp_b4_end;
    wp_b3_end = wp_b3_str + F_KEY_DET_W * F_SLOT;
    wp_b3_cnt = wp_b3_str + F_WD12_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 13 (b2)
    wp_b2_str = wp_b3_end;
    wp_b2_end = wp_b2_str + F_KEY_DET_W * F_SLOT;
    wp_b2_cnt = wp_b2_str + F_WD13_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 14 (b1)
    wp_b1_str = wp_b2_end;
    wp_b1_end = wp_b1_str + F_KEY_DET_W * F_SLOT;
    wp_b1_cnt = wp_b1_str + F_WD14_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    //Word Packet 15 (b0)
    wp_b0_str = wp_b1_end;
    wp_b0_end = wp_b0_str + F_KEY_DET_W * F_SLOT;
    wp_b0_cnt = wp_b0_str + F_WD15_POS * F_WD_ID_SU * F_SLOT + F_WD_ID_W * F_SLOT / 2;
    
    for (i = 0; i<nfilter; i++){
        lpfin[i] = lpfnext[i];
    }
    for (fr = jj = ilast = 0;; fr++) {
        read = fr*ls;
        reminder = n_data - read;
        n = ls;
        if (reminder<ls){
            ilast = 1;
            n = reminder;
        }
        if (n == 0) break;
        for (i = 0; i<n; i++){
            lpfin[i + nfilter] = bpfout[read + i];
        }
        if (ilast == 1){
            for (i = 0; i<ls - n; i++){
                lpfin[i + n + nfilter] = 0.0;
            }
        }
        for (i = 0; i<n; i++){
            sum = 0.0;
            // LPF fabs
            for (j = 0; j<nfilter; j++) sum += filtr[j] * fabs(lpfin[i + (nfilter - 1) - j]);
            
            // Pre Amble and Word Packet Detection
            if (sum > ib_peak[0]){
                ib_peak[0] = sum;
            }
            ib_ave[0] = ib_ave[0] + LPF_GAIN * sum;
            ib_avec[0]++;
            
            if (msc_cn[0] == 0){
                pra_1st_done = 0;
                pra_12n_cn = 0;    pra_12n_ck = 0;
                pra_23n_cn = 0; pra_23n_ck = 0;
                pra_endn_cn = 0; pra_endn_ck = 0;
                wp_a_data = 0; wp_b_data = 0; wp_c_data = 0;
                
                if (mask_cn == 0 && LPF_GAIN*sum >= TH_1ST) msc_cn[0] = 1;
            }
            else if (pra_1st_done == 0 && msc_cn[0] == pra_1st_end - 1){
                ini_check = 0;
                for (ini_cl = 0; ini_cl < TH_NUM; ini_cl++){
                    ini_check += pra_1st_cn[ini_cl];
                }
                if (ini_check == 0){
                    msc_cn[0] = 0;
                }
                else{   //Pre-Amble 1st Pulse Process
                    msc_cn[0] = Pra1stDistinction(pra_1st_cn, pra_1st_rireki, pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], pra_pls_lvl, jj, pra_1st_tep, pra_1st_tpn);
                    if (msc_cn[0] != 0){
                        pra_1st_done = 1;
                        //NSLog(@"pra_1st_done");
                        msc_cn[0]++;
                    }
                }
            }
            else if (msc_cn[0] >= pra_12n_str && msc_cn[0] < pra_12n_end){  //Pre-Amble 12 Nagate Process
                pra_12n_ck = PlsNgtPrcs(pra_12n_cn, sum, pra_ngt_max);
                if (pra_12n_ck == 0){
                    msc_cn[0] = 0;
                }
                else{
                    msc_cn[0]++;
                }
            }
            else if (msc_cn[0] == pra_2nd_cnt){   //Pre-Amble 2nd Pulse Process
                pra_2nd_ck = Pra2ndDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], pra_pls_lvl, jj, F_PRA_23P_SD_ON, dev);
                if (pra_2nd_ck == 0){
                    msc_cn[0] = 0;
                }
                else{
                    //NSLog(@"pra_2nd_done");
                    msc_cn[0]++;
                }
            }
            else if (msc_cn[0] >= pra_23n_str && msc_cn[0] < pra_23n_end){  //Pre-Amble 23 Nagate Process
                pra_23n_ck = PlsNgtPrcs(pra_23n_cn, sum, pra_ngt_max);
                if (pra_23n_ck == 0){
                    msc_cn[0] = 0;
                }
                else{
                    msc_cn[0]++;
                }
            }
            else if (msc_cn[0] == pra_3rd_cnt){   //Pre-Amble 3rd Pulse Process
                pra_3rd_ck = Pra3rdDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], pra_pls_lvl, jj, F_PRA_23P_SD_ON, dev);
                if (pra_3rd_ck == 0){
                    msc_cn[0] = 0;
                }
                else{
                    //NSLog(@"pra_3rd_done");
                    msc_cn[0]++;
                }
            }
            else if (msc_cn[0] >= pra_endn_str && msc_cn[0] < pra_endn_end){    //Pre-Amble end Nagate Process
                pra_endn_ck = PlsNgtPrcs(pra_endn_cn, sum, pra_ngt_max);
                if (msc_cn[0] == pra_endn_end - 1){
                    plt_peak[0] = (pra_pls_lvl[0] + pra_pls_lvl[1] + pra_pls_lvl[2]) / 3;
                    //NSLog(@"pra_done with plt_peak[0]:%f", plt_peak[0]);
                    msc_cn[0]++;
                }
                else if (pra_endn_ck == 0){
                    msc_cn[0] = 0;
                    plt_peak[0] = 0;
                }
                else{
                    msc_cn[0]++;
                }
            }
            else if (msc_cn[0] == wp_a7_cnt){   //Word Packet 0 (a7) Process
                wp_a_data = 16384 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 2] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_a7to7_data:%d", wp_a_data);
            }
            else if (msc_cn[0] == wp_a6_cnt){   //Word Packet 1 (a6) Process
                wp_a_data += 4096 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 6] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_a7to6_data:%d", wp_a_data);
            }
            else if (msc_cn[0] == wp_a5_cnt){   //Word Packet 2 (a5) Process
                wp_a_data += 1024 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 10] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_a7to5_data:%d", wp_a_data);
            }
            else if (msc_cn[0] == wp_a4_cnt){   //Word Packet 3 (a4) Process
                wp_a_data += 256 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 14] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_a7to4_data:%d", wp_a_data);
            }
            else if (msc_cn[0] == wp_a3_cnt){   //Word Packet 4 (a3) Process
                wp_a_data += 64 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 18] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_a7to3_data:%d", wp_a_data);
            }
            else if (msc_cn[0] == wp_a2_cnt){   //Word Packet 5 (a2) Process
                wp_a_data += 16 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 22] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_a7to2_data:%d", wp_a_data);
            }
            else if (msc_cn[0] == wp_a1_cnt){   //Word Packet 6 (a1) Process
                wp_a_data += 4 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 26] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_a7to1_data:%d", wp_a_data);
            }
            else if (msc_cn[0] == wp_a0_cnt){   //Word Packet 7 (a0) Process
                wp_a_data += 1 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 30] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_a7to0_data:%d", wp_a_data);
            }
            
            else if (msc_cn[0] == wp_b7_cnt){    //Word Packet 8 (b7) Process (Mirror)
                wp_b_data = 16384 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 34] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_b7to7_data:%d", wp_b_data);
            }
            else if (msc_cn[0] == wp_b6_cnt){    //Word Packet 9 (b6) Process (Mirror)
                wp_b_data += 4096 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 38] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_b7to6_data:%d", wp_b_data);
            }
            else if (msc_cn[0] == wp_b5_cnt){    //Word Packet 10 (b5) Process (Mirror)
                wp_b_data += 1024 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 42] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_b7to5_data:%d", wp_b_data);
            }
            else if (msc_cn[0] == wp_b4_cnt){    //Word Packet 11 (b4) Process (Mirror)
                wp_b_data += 256 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 46] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_b7to4_data:%d", wp_b_data);
            }
            else if (msc_cn[0] == wp_b3_cnt){    //Word Packet 12 (b3) Process (Mirror)
                wp_b_data += 64 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 50] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_b7to3_data:%d", wp_b_data);
            }
            else if (msc_cn[0] == wp_b2_cnt){    //Word Packet 13 (b2) Process (Mirror)
                wp_b_data += 16 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 54] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_b7to2_data:%d", wp_b_data);
            }
            else if (msc_cn[0] == wp_b1_cnt){    //Word Packet 14 (b1) Process (Mirror)
                wp_b_data += 4 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 58] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_b7to1_data:%d", wp_b_data);
            }
            else if (msc_cn[0] == wp_b0_cnt){    //Word Packet 15 (b0) Process (Mirror)
                wp_b_data += 1 * WordPacketDistinction(pre_bpfout, bpfout, key_sta_val[0], key_sta_val[1], key_sta_val[2], key_sta_val[3], plt_peak[0], jj, dev);
                msc_cn[0]++;
                for (ini_cl = 0; ini_cl < 4; ini_cl++){
                    det_inf[ini_cl + 62] = (int)dev[ini_cl];
                }
                //NSLog(@"wp_b7to0_data:%d", wp_b_data);
            }
            else if (msc_cn[0] == wp_b0_end){
                int forwardWordPacketDataValid = (wp_a_data <= 65535 && wp_a_data >= 0);
                int backwardWordPacketDataValid = (wp_b_data <= 65535 && wp_b_data >= 0);
                if (forwardWordPacketDataValid && backwardWordPacketDataValid && ib_ave[0]/ib_avec[0]/inGain < 0.8){
                    if (wp_a_data == 65535 - wp_b_data){
                        det_inf[0] = wp_a_data + 1;
                        det_inf[1] = plt_peak[0];
                        mask_cn = 1;
                        //NSLog(@"det_inf[0]:%d", det_inf[0]);
                    }
                    else{
                        det_inf[0] = 0;
                        det_inf[1] = 0;
                        //NSLog(@"fail:det_inf[0]:%d", det_inf[0]);
                    }
                }
                else{
                    det_inf[0] = 0;
                    det_inf[1] = 0;
                }
                msc_cn[0] = 0;
            }
            else{
                msc_cn[0]++;
            }
            
            Pra1stPcn(pra_1st_cn, pra_1st_rireki, pra_1st_soa, pra_1st_cog, msc_cn, sum, pra_1st_min, F_PRA_1ST_COMT);
            
            if (mask_cn == 44 * 100){       // 44 by default
                mask_cn = 0;
            }
            else if (mask_cn != 0){
                mask_cn++;
            }
            
            // LPF Process
            lpfout[jj++] = LPF_GAIN * sum;
        }
        for (i = 0; i<nfilter; i++) {
            lpfnext[i] = lpfin[ls + i];
        }
        for (i = 0; i < (FILTAP_LPF - 1) / 2 + F_SLOT * F_PLS_DET_W; i++) {
            pre_bpfout[i] = bpfout[ls - 1 - i];
        }
        if (reminder<ls) break;
    }
    return;
}

//-------------------------------------------------
// Pra1stPcn(Pre-Amble 1st Pulse)
//-------------------------------------------------
void Pra1stPcn(int pra_1st_cn[], int pra_1st_rireki[], double pra_1st_soa[], double pra_1st_cog[], int msc_cn[], float sum, int pra_1st_min, int pra_1st_comt){
    
    int i;
    if (msc_cn[0] == 0){
        for (i = 0; i<TH_NUM; i++){
            *pra_1st_cn = 0;
            *pra_1st_rireki = 0;
            *pra_1st_soa = 0;
            *pra_1st_cog = 0;
            pra_1st_cn++;
            pra_1st_rireki++;
            pra_1st_soa++;
            pra_1st_cog++;
        }
    }
    else{
        for (i = 0; i<TH_NUM; i++){
            if (*pra_1st_cn == 0){
                if (*pra_1st_rireki == 0 && LPF_GAIN*sum >= (TH_1ST + i*(LPF_MGN - TH_1ST) / TH_NUM)){
                    *pra_1st_cn = 1;
                    *pra_1st_soa = *pra_1st_soa + sum;                    //for sum of area
                    *pra_1st_cog = *pra_1st_cog + *pra_1st_cn * sum;    //for center of gravity
                }
            }
            else{
                *pra_1st_cn = *pra_1st_cn + 1;
                *pra_1st_soa = *pra_1st_soa + sum;                    //for sum of area
                *pra_1st_cog = *pra_1st_cog + *pra_1st_cn * sum;    //for center of gravity
                if (LPF_GAIN*sum<(TH_1ST + i*(LPF_MGN  - TH_1ST) / TH_NUM) && *pra_1st_rireki == 0){
                    if (*pra_1st_cn < pra_1st_min){
                        *pra_1st_cn = 0;
                        *pra_1st_soa = 0;
                        *pra_1st_cog = 0;
                    }
                    else{
                        if (pra_1st_comt == 0){
                            *pra_1st_cn = (int)(*pra_1st_cog / *pra_1st_soa);
                        }
                        else{
                            *pra_1st_cn = (int)(*pra_1st_cn / 2);
                        }
                        *pra_1st_rireki = 1;
                    }
                }
            }
            pra_1st_cn++;
            pra_1st_rireki++;
            pra_1st_soa++;
            pra_1st_cog++;
        }
    }
    return;
    
}

//-----------------------------------------------------
// Pra1stDistinction(Pre-Amble 1st Pulse)
//-----------------------------------------------------
int Pra1stDistinction(int pra_1st_cn[], int pra_1st_rireki[], float pre_bpfout[], float bpfout[], double key_sta_val_0[], double key_sta_val_1[], double key_sta_val_2[], double key_sta_val_3[], double pra_pls_lvl[], int jj, int pra_1st_tep, int pra_1st_tpn){
    
    int i, j;
    int dlt[TH_NUM - 1][TH_NUM];
    int pms_cn = 0;
    int min_dlt = 10000;
    int min_ave = 10000;
    double pra_1st_psn[F_SNC_FRM_PLS + 2];
    
    for (i = 0; i<TH_NUM - 1; i++){
        for (j = i + 1; j<TH_NUM; j++){
            if (pra_1st_rireki[i] == 1 && pra_1st_rireki[j] == 1){
                dlt[i][j] = abs(pra_1st_cn[i] - pra_1st_cn[j]);
            }
            else{
                dlt[i][j] = 10000;
            }
            if (dlt[i][j]<pra_1st_tep){
                pms_cn++;
                if (dlt[i][j]<min_dlt){
                    min_dlt = dlt[i][j];
                    min_ave = (pra_1st_cn[i] + pra_1st_cn[j]) / 2;
                }
            }
        }
    }
    
    if (pms_cn >= pra_1st_tpn){
        //preamble 1st pulse data getting
        for (i = 0; i < F_SNC_FRM_PLS + 2; i++){
            if (jj - min_ave - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i < 0){
                pra_1st_psn[i] = pre_bpfout[abs(jj - min_ave - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i) - 1];
            }
            else{    //fixed by Koh 2014.09.27
                pra_1st_psn[i] = bpfout[jj - min_ave - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i];
            }
        }
        //preamble 1st pulse level evaluation (pra_pls_lvl[0])
        pra_pls_lvl[0] = 0;
        j = 0;
        for (i = 0; i + 4 < F_SNC_FRM_PLS + 2; i++){
            pra_pls_lvl[0] += sqrt(pra_1st_psn[i] * pra_1st_psn[i] + pra_1st_psn[i + 4] * pra_1st_psn[i + 4]);
            j++;
        }
        if (j == 0){
            pra_pls_lvl[0] = 0;
        }
        else{
            pra_pls_lvl[0] = pra_pls_lvl[0] / j;
        }
        //NSLog(@"pra_pls_lvl[0]:%f", pra_pls_lvl[0]);
        //State 0 calculation (key_sta_val_0[])
        for (i = 0; i < F_SNC_FRM_PLS; i++){
            if (pra_pls_lvl[0] == 0){
                key_sta_val_0[i] = 0;
            }
            else{
                key_sta_val_0[i] = (100 * pra_1st_psn[i + 1] / pra_pls_lvl[0]);
                //NSLog(@"key_sta_val_0[%d]:%f", i, key_sta_val_0[i]);
            }
        }
        //State 1 calculation (key_sta_val_1[]: key_sta_val_0[] reverse])
        for (i = 0; i < F_SNC_FRM_PLS; i++){
            key_sta_val_1[i] = -key_sta_val_0[i];
        }
        //State 2 calculation (key_sta_val_2[]: squt(1 - key_sta_val_0[] ^ 2))
        for (i = 0; i < F_SNC_FRM_PLS; i++){
            if (pra_pls_lvl[0] == 0){
                key_sta_val_2[i] = 0;
            }
            else{
                if(fabs(pra_1st_psn[i + 1] / pra_pls_lvl[0]) >= 1){
                    key_sta_val_2[i] = 0;
                }
                else {
                    key_sta_val_2[i] = (100 * sqrt(1 - (pra_1st_psn[i + 1] / pra_pls_lvl[0]) * (pra_1st_psn[i + 1] / pra_pls_lvl[0])));
                }
                if (pra_1st_psn[i + 1] - pra_1st_psn[i] >= 0){
                    key_sta_val_2[i] = -key_sta_val_2[i];
                }
                //NSLog(@"pra_1st_psn[%d]:%f", i, pra_1st_psn[i + 1]);
                //NSLog(@"key_sta_val_2[%d]:%f", i, key_sta_val_2[i]);
            }
        }
        //State 3 calculation (key_sta_val_3[]: key_sta_val_2[] reverse)
        for (i = 0; i < F_SNC_FRM_PLS; i++){
            key_sta_val_3[i] = -key_sta_val_2[i];
        }
        return min_ave;
    }
    else{
        pra_pls_lvl[0] = 0;
        for (i = 0; i < F_SNC_FRM_PLS; i++){
            key_sta_val_0[i] = 0;
        }
        return 0;
    }
}

//-------------------------------------------------
// PlsNgtPrcs(Pre-Amble 12 and 23 Negate)
//-------------------------------------------------
int PlsNgtPrcs(int pra_ngt_cn, float sum, int pra_ngt_max){
    
    if (pra_ngt_cn == pra_ngt_max){
        pra_ngt_cn = 0;
        return 0;
    }
    else{
        if (LPF_GAIN*sum >= TH_1ST){
            pra_ngt_cn++;
        }
        return 1;
    }
}

//-----------------------------------------------------------
// Pls2ndDistinction(Pre-Amble 2nd Pulse)
//-----------------------------------------------------------
int Pra2ndDistinction(float pre_bpfout[], float bpfout[], double key_sta_val_0[], double key_sta_val_1[], double key_sta_val_2[], double key_sta_val_3[], double pra_pls_lvl[], int jj, int sd_on, double dev[]){
    
    int i, j, hanbetsu;
    double pra_2nd_psn[F_SNC_FRM_PLS + 2];
    double pra_2nd_lvl;
    double current_val[F_SNC_FRM_PLS];
    
    //preamble 2nd pulse data getting
    for (i = 0; i < F_SNC_FRM_PLS + 2; i++){
        if (jj - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i < 0){
            pra_2nd_psn[i] = pre_bpfout[abs(jj - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i) - 1];
        }
        else{    //fixed by Koh 2014.09.27
            pra_2nd_psn[i] = bpfout[jj - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i];
        }
    }
    //preamble 2nd pulse level evaluation (pra_2nd_lvl)
    pra_2nd_lvl = 0;
    j = 0;
    for (i = 0; i + 4 < F_SNC_FRM_PLS + 2; i++){
        pra_2nd_lvl += sqrt(pra_2nd_psn[i] * pra_2nd_psn[i] + pra_2nd_psn[i + 4] * pra_2nd_psn[i + 4]);
        j++;
    }
    if (j == 0){
        pra_2nd_lvl = 0;
    }
    else{
        pra_2nd_lvl = pra_2nd_lvl / j;
    }
    
    //preamble 2nd pulse distinction
    if (pra_2nd_lvl == 0){
        return 0;
    }
    else if (pra_2nd_lvl < pra_pls_lvl[0] * F_PRA_23P_TLE / 100){
        return 0;
    }
    //standard deviation evaluation
    else{
        pra_pls_lvl[1] = pra_2nd_lvl;
        if (sd_on != 1){
            return 1;
        }
        else{
            for (i = 0; i < F_SNC_FRM_PLS; i++){
                current_val[i] = (100 * pra_2nd_psn[i + 1] / pra_2nd_lvl);
            }
            hanbetsu = MinimumStandardDeviation(current_val, key_sta_val_0, key_sta_val_1, key_sta_val_2, key_sta_val_3, dev);
            //NSLog(@"MinimumStandardDeviation:%d",hanbetsu);
            if (MinimumStandardDeviation(current_val, key_sta_val_0, key_sta_val_1, key_sta_val_2, key_sta_val_3, dev) == 0){
                //State 0 calculation (key_sta_val_0[])
                for (i = 0; i < F_SNC_FRM_PLS; i++){
                    key_sta_val_0[i] = (key_sta_val_0[i] + current_val[i]) / 2;
                    //NSLog(@"key_sta_val_0[%d]:%f", i, key_sta_val_0[i]);
                }
                //State 1 calculation (key_sta_val_1[]: key_sta_val_0[] reverse)
                for (i = 0; i < F_SNC_FRM_PLS; i++){
                    key_sta_val_1[i] = -key_sta_val_0[i];
                }
                //State 2 calculation (key_sta_val_2[]: squt(1 - key_sta_val_0[] ^ 2))
                for (i = 0; i < F_SNC_FRM_PLS; i++){
                    if(fabs(pra_2nd_psn[i + 1] / ((pra_pls_lvl[0] + pra_pls_lvl[1]) / 2)) >= 1){
                        key_sta_val_2[i] = 0;
                    }
                    else {
                        key_sta_val_2[i] = (100 * sqrt(1 - (pra_2nd_psn[i + 1] / ((pra_pls_lvl[0] + pra_pls_lvl[1]) / 2)) * (pra_2nd_psn[i + 1] / ((pra_pls_lvl[0] + pra_pls_lvl[1]) / 2))));
                    }
                    //                    key_sta_val_2[i] = (100 * sqrt(1 - (pra_2nd_psn[i + 1] / ((pra_pls_lvl[0] + pra_pls_lvl[1]) / 2)) * (pra_2nd_psn[i + 1] / ((pra_pls_lvl[0] + pra_pls_lvl[1]) / 2))));
                    if (pra_2nd_psn[i + 1] - pra_2nd_psn[i] >= 0){
                        key_sta_val_2[i] = -key_sta_val_2[i];
                    }
                    //NSLog(@"key_sta_val_2[%d]:%f", i, key_sta_val_2[i]);
                }
                //State 3 calculation (key_sta_val_3[]: key_sta_val_2[] reverse)
                for (i = 0; i < F_SNC_FRM_PLS; i++){
                    key_sta_val_3[i] = -key_sta_val_2[i];
                }
                return 1;
            }
            else{
                return 0;
            }
        }
    }
}

//-----------------------------------------------------
// Pra3rdDistinction (Pre-Amble 3rd Pulse)
//-----------------------------------------------------
int Pra3rdDistinction(float pre_bpfout[], float bpfout[], double key_sta_val_0[], double key_sta_val_1[], double key_sta_val_2[], double key_sta_val_3[], double pra_pls_lvl[], int jj, int sd_on, double dev[]){
    
    int i, j, hanbetsu;
    double pra_3rd_psn[F_SNC_FRM_PLS + 2];
    double pra_3rd_lvl;
    double current_val[F_SNC_FRM_PLS];
    
    //preamble 3rd pulse data getting
    for (i = 0; i < F_SNC_FRM_PLS + 2; i++){
        if (jj - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i < 0){
            pra_3rd_psn[i] = pre_bpfout[abs(jj - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i) - 1];
        }
        else{    //fixed by Koh 2014.09.27
            pra_3rd_psn[i] = bpfout[jj - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i];
        }
    }
    //preamble 3rd pulse level evaluation (pra_3rd_lvl)
    pra_3rd_lvl = 0;
    j = 0;
    for (i = 0; i + 4 < F_SNC_FRM_PLS + 2; i++){
        pra_3rd_lvl += sqrt(pra_3rd_psn[i] * pra_3rd_psn[i] + pra_3rd_psn[i + 4] * pra_3rd_psn[i + 4]);
        j++;
    }
    if (j == 0){
        pra_3rd_lvl = 0;
    }
    else{
        pra_3rd_lvl = pra_3rd_lvl / j;
    }
    
    //preamble 3rd pulse distinction
    if (pra_3rd_lvl == 0){
        return 0;
    }
    else if (pra_3rd_lvl < pra_pls_lvl[0] * F_PRA_23P_TLE / 100){
        return 0;
    }
    //standard deviation calculation
    else{
        pra_pls_lvl[2] = pra_3rd_lvl;
        if (sd_on != 1){
            return 1;
        }
        else{
            for (i = 0; i < F_SNC_FRM_PLS; i++){
                current_val[i] = (100 * pra_3rd_psn[i + 1] / pra_3rd_lvl);
            }
            hanbetsu = MinimumStandardDeviation(current_val, key_sta_val_0, key_sta_val_1, key_sta_val_2, key_sta_val_3, dev);
            //NSLog(@"MinimumStandardDeviation:%d",hanbetsu);
            if (hanbetsu == 2 || hanbetsu == 3){
                //State 2 calculation (key_sta_val_2[]: current_val[i])
                for (i = 0; i < F_SNC_FRM_PLS; i++){
                    key_sta_val_2[i] = current_val[i];
                    //NSLog(@"key_sta_val_0[%d]:%f", i, key_sta_val_0[i]);
                    //NSLog(@"key_sta_val_2[%d]:%f", i, key_sta_val_2[i]);
                }
                //State 3 calculation (key_sta_val_3[]: key_sta_val_2[] reverse)
                for (i = 0; i < F_SNC_FRM_PLS; i++){
                    key_sta_val_3[i] = -key_sta_val_2[i];
                }
                return 1;
            }
            else{
                return 0;
            }
        }
    }
}

//-----------------------------------------------------
// WordPacketDistinction(Word Packet Key)
//-----------------------------------------------------
int WordPacketDistinction(float pre_bpfout[], float bpfout[], double key_sta_val_0[], double key_sta_val_1[], double key_sta_val_2[], double key_sta_val_3[], double pra_pls_lvl, int jj, double dev[]){
    
    int i, j, hanbetsu, pre_hanbetsu;
    double wp_key_psn[F_SNC_FRM_PLS + 2], pre_wp_key_psn[F_SNC_FRM_PLS + 2];
    double wp_key_lvl, pre_wp_key_lvl;
    double current_val[F_SNC_FRM_PLS], previous_val[F_SNC_FRM_PLS];
    double crn_dev[4], pre_dev[4];
    
    //word packet key data getting (key_sta_val)
    for (i = 0; i < F_SNC_FRM_PLS + 2; i++){
        if (jj - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i < 0){
            wp_key_psn[i] = pre_bpfout[abs(jj - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i) - 1];
        }
        else{    //fixed by Koh 2014.09.27
            wp_key_psn[i] = bpfout[jj - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i];
        }
        //NSLog(@"wp_key_psn[%d]: %f", i, wp_key_psn[i]);
    }
    //word packet key level evaluation (wp_key_lvl)
    wp_key_lvl = 0;
    j = 0;
    for (i = 0; i + 4 < F_SNC_FRM_PLS + 2; i++){
        wp_key_lvl += sqrt(wp_key_psn[i] * wp_key_psn[i] + wp_key_psn[i + 4] * wp_key_psn[i + 4]);
        j++;
    }
    if (j == 0){
        wp_key_lvl = 0;
    }
    else{
        wp_key_lvl = wp_key_lvl / j;
    }
    //word packet key standard deviation calculation
    for (i = 0; i < F_SNC_FRM_PLS; i++){
        if (wp_key_lvl == 0){
            current_val[i] = (100 * wp_key_psn[i + 1]);
        }
        else{
            current_val[i] = (100 * wp_key_psn[i + 1] / wp_key_lvl);
        }
    }
    hanbetsu = MinimumStandardDeviation(current_val, key_sta_val_0, key_sta_val_1, key_sta_val_2, key_sta_val_3, crn_dev);
    
    //1 position word packet key data getting (key_sta_val)
    for (i = 0; i < F_SNC_FRM_PLS + 2; i++){
        if (jj - F_WD_ID_SU * F_SLOT - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i < 0){
            pre_wp_key_psn[i] = pre_bpfout[abs(jj - F_WD_ID_SU * F_SLOT - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i) - 1];
        }
        else{    //fixed by Koh 2014.09.27
            pre_wp_key_psn[i] = bpfout[jj - F_WD_ID_SU * F_SLOT - (FILTAP_LPF - 1) / 2 - (F_SNC_FRM_PLS + 2 - 1) / 2 + i];
        }
    }
    //1 position word packet key level evaluation (wp_key_lvl)
    pre_wp_key_lvl = 0;
    j = 0;
    for (i = 0; i + 4 < F_SNC_FRM_PLS + 2; i++){
        pre_wp_key_lvl += sqrt(pre_wp_key_psn[i] * pre_wp_key_psn[i] + pre_wp_key_psn[i + 4] * pre_wp_key_psn[i + 4]);
        j++;
    }
    if (j == 0){
        pre_wp_key_lvl = 0;
    }
    else{
        pre_wp_key_lvl = pre_wp_key_lvl / j;
    }
    //1 position word packet key standard deviation calculation
    for (i = 0; i < F_SNC_FRM_PLS; i++){
        if (pre_wp_key_lvl == 0){
            previous_val[i] = (100 * pre_wp_key_psn[i + 1]);
        }
        else{
            previous_val[i] = (100 * pre_wp_key_psn[i + 1] / pre_wp_key_lvl);
        }
    }
    pre_hanbetsu = MinimumStandardDeviation(previous_val, key_sta_val_0, key_sta_val_1, key_sta_val_2, key_sta_val_3, pre_dev);
    
    if (wp_key_lvl == 0){
        for (i = 0; i < 4; i++){
            dev[i] = 0.0;
        }
        //NSLog(@"wp_key_lvl == 0");
        return 1000;
    }
    else if (wp_key_lvl < pra_pls_lvl * F_PRA_23P_TLE / 100){
        for (i = 0; i < 4; i++){
            dev[i] = 0.0;
        }
        //NSLog(@"wp_key_lvl < pra_pls_lvl * F_PRA_23P_TLE / 100");
        return 1000;
    }
    else if (pre_wp_key_lvl >= wp_key_lvl && pre_hanbetsu == hanbetsu && pre_dev[pre_hanbetsu] < crn_dev[hanbetsu]){
        for (i = 0; i < 4; i++){
            dev[i] = pre_dev[i];
        }
        //NSLog(@"pre_wp_key_lvl >= wp_key_lvl && pre_hanbetsu == hanbetsu && pre_dev[pre_hanbetsu] < crn_dev[hanbetsu]");
        return 1000;
    }
    else if (crn_dev[hanbetsu] >= SD_MIN_VAL){
        //NSLog(@"crn_dev[hanbetsu] >= SD_MIN_VAL");
        return 1000;
    }
    else{
        for (i = 0; i < 4; i++){
            dev[i] = crn_dev[i];
        }
        return hanbetsu;
    }
}

//-----------------------------------------------------
// MinimumStandardDeviation
//-----------------------------------------------------
int MinimumStandardDeviation(double current_val[], double key_sta_val_0[], double key_sta_val_1[], double key_sta_val_2[], double key_sta_val_3[], double dev[]){
    int i, j;
    double sum[4], sum2[4], avg[4], ckdev;
    
    for (i = 0; i < 4; i++){
        sum[i] = 0;
        sum2[i] = 0;
    }
    for (i = 0; i < F_SNC_FRM_PLS; i++) {
        sum[0] += (current_val[i] - key_sta_val_0[i]);
        sum[1] += (current_val[i] - key_sta_val_1[i]);
        sum[2] += (current_val[i] - key_sta_val_2[i]);
        sum[3] += (current_val[i] - key_sta_val_3[i]);
        
        sum2[0] += ((current_val[i] - key_sta_val_0[i]) * (current_val[i] - key_sta_val_0[i]));
        sum2[1] += ((current_val[i] - key_sta_val_1[i]) * (current_val[i] - key_sta_val_1[i]));
        sum2[2] += ((current_val[i] - key_sta_val_2[i]) * (current_val[i] - key_sta_val_2[i]));
        sum2[3] += ((current_val[i] - key_sta_val_3[i]) * (current_val[i] - key_sta_val_3[i]));
    }
    for (i = 0; i < 4; i++){
        avg[i] = sum[i] / F_SNC_FRM_PLS;
        dev[i] = sqrt(sum2[i] / F_SNC_FRM_PLS - avg[i] * avg[i]);
    }
    
    ckdev = 100000.0;
    j = 1000;
    for (i = 0; i < 4; i++){
        if (dev[i] < ckdev){
            ckdev = dev[i];
            j = i;
        }
    }
    //NSLog(@"dev:%f",ckdev);
    return j;
}

//-----------------------------------------------------------
// HamWdwFunc
//-----------------------------------------------------------
void HamWdwFunc(double hamwdw[], int ntaps){
    int i;
    double d, pi = 3.14159265358979323846264338327950288419716939;
    
    if (ntaps>0){
        d = 2.0*pi / (double)(ntaps - 1);
        for (i = 0; i < ntaps; i++){
            hamwdw[i] = 0.54 - 0.46*cos(d*i);
        }
    }
}

//-----------------------------------------------------------
// Lpfdsn
//-----------------------------------------------------------
void Lpfdsn(double fc, double hamwdw[], double filtr[]){
    int i;
    double d, pi = 3.14159265358979323846264338327950288419716939;
    double alp, twopi, cons;
    double fs = 44100;
    int ntaps = FILTAP_LPF;
    
    twopi = 2.0*pi;
    if (ntaps>0){
        d = twopi*fc / fs;
        cons = 2.0*fc / fs;
        alp = (double)(ntaps - 1) / 2.0;
        
        //first half of the calculation
        for (i = 0; i < (ntaps - 1) / 2; i++){
            filtr[i] = hamwdw[i] * cons*sin(d*((double)i - alp)) / (d*((double)i - alp));
        }
        
        //last half of the calculation
        if ((double)((ntaps - 1) / 2) == alp){
            filtr[(ntaps - 1) / 2] = hamwdw[(ntaps - 1) / 2] * 2.0*fc / fs;
            for (i = (ntaps + 1) / 2; i < ntaps; i++){
                filtr[i] = hamwdw[i] * cons*sin(d*((double)i - alp)) / (d*((double)i - alp));
            }
        }
        else{
            for (i = (ntaps - 1) / 2; i < ntaps; i++){
                filtr[i] = hamwdw[i] * cons*sin(d*((double)i - alp)) / (d*((double)i - alp));
            }
        }
    }
    return;
}

//-----------------------------------------------------------
// Bpfdsn
//-----------------------------------------------------------
void Bpfdsn(double fleft, double fright, double hamwdw[], double filtr[]){
    int i;
    double d, pi = 3.14159265358979323846264338327950288419716939;
    double fc, fcc, alp, twopi, cons;
    double fs = 44100;
    int ntaps = FILTAP_BPF;
    
    fcc = (fleft + fright) / 2.0;
    fc = fright - fcc;
    twopi = 2.0*pi;
    if (ntaps>0){
        d = twopi*fc / fs;
        cons = 2.0*fc / fs;
        alp = (double)(ntaps - 1) / 2.0;
        
        //first half of the calculation
        for (i = 0; i < (ntaps - 1) / 2; i++){
            filtr[i] = hamwdw[i] * cons*sin(d*((double)i - alp)) / (d*((double)i - alp));
        }
        
        //last half of the calculation
        if ((double)((ntaps - 1) / 2) == alp){
            filtr[(ntaps - 1) / 2] = hamwdw[(ntaps - 1) / 2] * 2.0*fc / fs;
            for (i = (ntaps + 1) / 2; i < ntaps; i++){
                filtr[i] = hamwdw[i] * cons*sin(d*((double)i - alp)) / (d*((double)i - alp));
            }
        }
        else{
            for (i = (ntaps - 1) / 2; i < ntaps; i++){
                filtr[i] = hamwdw[i] * cons*sin(d*((double)i - alp)) / (d*((double)i - alp));
            }
        }
        // BPF
        cons = twopi*fcc / fs;
        for (i = 0; i<ntaps; i++){
            filtr[i] *= (alp = 2.0*cos(cons*(double)i));
        }
    }
    return;
}

#pragma mark - Multi-threading Tasks for seeking and adjusting PTAT

//------------------------------------------------------------------
// Multithreading of Automatic Gain Control Task
//------------------------------------------------------------------
void agcPTATTask()
{
    if (ib_avec[0] != 0 && (ib_ave[0] / ib_avec[0]) > LIMG_TH){
        inGain = (float)(PA_L_ATT * inGain);
    }
    else if (plt_peak[0] != 0){
        inGain = (float)(LPF_MGN * inGain / (LPF_GAIN * plt_peak[0]));
    }
}

//------------------------------------------------------------------
// Multithreading of Seeking Pilot Signal Task
//------------------------------------------------------------------
void seekPTATTask()
{
    int i;
    if (ib_avec[0] != 0 && (ib_ave[0] / ib_avec[0]) > LIMG_TH){
        inGain = (float)(PA_L_ATT * inGain);
    }
    else if (pa_seek_task == 1){
        //Preamble 1st loose conditions
        pa_crnt_q = 0;
        for (i = 0; i<FILTAP_BPF; i++){ bpf_coef[i] = bpf_coef_tbl[pa_crnt_q][i]; }		//BPF bandwidth minimum
        lpf_fcnum = LPF_STP_NM - 1;
        for (i = 0; i < FILTAP_LPF; i++){ lpf_coef[i] = lpf_coef_tbl[lpf_fcnum][i]; }	//LPF cutoff frequency maximum
        //Seeking Process
        if (LPF_GAIN * ib_peak[0] < TH_1ST){
            inGain = (float)(LPF_MGN * inGain / TH_1ST);
        }
        else if (ib_peak[0] != 0){
            inGain = (float)(LPF_MGN * inGain / (LPF_GAIN * ib_peak[0]));
        }
        ib_peak[0] = 0;
    }
    else if (pa_seek_task == 2){
        //Preamble 1st detective conditions
        pa_crnt_q = (int)(BPF_STP_NM - 1) / 2;
        for (i = 0; i<FILTAP_BPF; i++){ bpf_coef[i] = bpf_coef_tbl[pa_crnt_q][i]; }		//BPF bandwidth
        lpf_fcnum = (int)(LPF_STP_NM - 1) / 2;
        for (i = 0; i < FILTAP_LPF; i++){ lpf_coef[i] = lpf_coef_tbl[lpf_fcnum][i]; }	//LPF cutoff frequency
        pa_seek_task = 0;
        ib_peak[0] = 0;
        //Adusting Process
        if (plt_peak[0] != 0){
            inGain = (float)(LPF_MGN * inGain / (LPF_GAIN * plt_peak[0]));
        }
    }
}

+ (int)detectedDataWithBuffer:(float *)inBuffer andBufferSize:(UInt32)bufferSize {

    // Automatic Gain Control, buffer -> inBuffermain
    float* inBufferMain = (float *)malloc(sizeof(float)*bufferSize);
    for (int i = 0; i < bufferSize; i++){
        if (inBuffer[i] * inGain >= 1){
            inBufferMain[i] = 1;
        }
        else if (inBuffer[i] * inGain <= -1){
            inBufferMain[i] = -1;
        }
        else{
            inBufferMain[i] = inBuffer[i] * inGain;
        }
    }
    
    BpfAbs(inBufferMain, bufferSize, bpfin, bpfout, bpfnext, bpf_coef);
    
    // Reset values
    det_inf[0] = 0;
    if (msc_cn[0] == 0){
        plt_peak[0] = 0;
    }
    ib_ave[0] = 0;
    ib_avec[0] = 0;
    
    LpfDet(bpfout, bufferSize, lpfout, lpfnext, pre_bpfout, lpfin, lpf_coef, msc_cn, det_inf, plt_peak, ib_peak, ib_ave, ib_avec, main_init);
    
    main_init = 0;
    bufferCounter = 1;
    
    /*
     SEEK and AGC by PT&AT
     */
    if (optimize == 1){
        crntTime = CACurrentMediaTime() * TIME_COEF;
        dm_crntTime = CACurrentMediaTime() * TIME_COEF;
        //NSLog(@"dm_crntTime - dm_dtctTime: %d", dm_crntTime - dm_dtctTime);
        if (pa_seek_task == 1 && ib_avec[0] != 0 && (ib_ave[0] / ib_avec[0]) >= LIMG_TH){
            pa_lock_on = 0;
            //NSLog(@"1:ib_ave >= LIM_TH");
            seekPTATTask();
        }
        else if (crntTime - dtctTime > pa_period_rls){
            dtctTime = CACurrentMediaTime() * TIME_COEF;
            dm_dtctTime = CACurrentMediaTime() * TIME_COEF;
            ib_peak[0] = 0;
            pa_seek_task = 1;
            //NSLog(@"2:unlocking time over");
        }
        else if (pa_seek_task == 1 && plt_peak[0] != 0 && dm_crntTime - dm_dtctTime > pa_period_min){
            dm_dtctTime = CACurrentMediaTime() * TIME_COEF;
            pa_seek_task = 2;
            pa_lock_on = 1;
            //NSLog(@"3:pilot signal detected");
            seekPTATTask();
        }
        else if (pa_seek_task == 1 && (dm_crntTime - dm_dtctTime > pa_period_min)){
            dm_dtctTime = CACurrentMediaTime() * TIME_COEF;
            pa_lock_on = 0;
            //NSLog(@"4:signal time exceeded");
            seekPTATTask();
        }
        else if (pa_seek_task == 0 && det_inf[0] != 0){
            dtctTime = CACurrentMediaTime() * TIME_COEF;
            dm_dtctTime = CACurrentMediaTime() * TIME_COEF;
            pa_lock_on = 1;
            //NSLog(@"5:main signal detected");
            agcPTATTask();
        }
        //else {NSLog(@"did nothing");}
    }
    
    free(inBufferMain);
    
    if (det_inf[0]) {
        return (det_inf[0] - 1);
    }
    else {
        return 0;
    }
}

@end
