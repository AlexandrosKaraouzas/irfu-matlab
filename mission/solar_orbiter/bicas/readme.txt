
#############
 About BICAS
#############
BICAS = BIAS Calibration Software

This software, BICAS, is created for the calibration of the BIAS subsystem in
the RPW instrument on the Solar Orbiter spacecraft. The principle author of this
software is Erik P G Johansson, Swedish Institute of Space Physics (IRF),
Uppsala, Sweden. Software development began 2016-03-xx (March 2016).

IMPORTANT NOTE: BICAS is designed to comply with the RCS ICD. Much documentation
on how to use this software can thus be found there. For more documentation,
see RCS ICD and RUM documents (see below).



###############################################
 Abbreviations, dictionary, naming Conventions
###############################################
NOTE: This list also applies to comments and identifiers in the source code.
Some source files also define abbreviations widely used in the source code.
--
AA, aampere
    Antenna ampere. Calibrated ampere at the antenna.
AAPT
    Antenna ampere/TM
ASR, Antenna Signal Representation.
    The "physical antenna signals" which BIAS-LFR/TDS is trying to measure, or a
    measurement thereof. In reality, the terminology is:
    ASR         : Pointer to a specific physical antenna signal, e.g. V12_LF (DC
                  diff, antenna 1-2)
    ASR samples : Samples representing a specific ASR (as opposed to BLTS).
    NOTE: There are 9 ASRs, i.e. they can refer also to signals not represented
    by any single BLTS, given a chosen mux mode (and latching relay setting).
AV, avolt, Antenna Volt
    Calibrated volt at the antennas, i.e. the final calibrated (measured) value,
    including for reconstructed signals (e.g. diffs calculated from singles).
    May also refer to offsets and values without offsets.
AVPIV
    Antenna volt/interface volt
BIAS specification
    Document RPW-SYS-MEB-BIA-SPC-00001-IRF, "RPW Instrument -- BIAS
    Specification"
BIAS_1, ..., BIAS_5 (BIAS_i, i=1..5)
    Defined in BIAS specifications document. Equal to the physical signal at the
    physical boundary between BIAS and LFR/TDS. Unit: Interface volt.
    Mostly replaced by BLTS+specified unit in the implementation.
BLTS = BIAS-LFR/TDS SIGNAL
    Signals somewhere between the LFR/TDS ADCs and the non-antenna side of the
    BIAS demuxer including the BIAS transfer functions. Like BIAS_i, i=1..5, but
    includes various stages of calibration/non-calibration, including in
    particular
      - TM units (inside LFR/TDS),
      - Interface volt (at the physical boundary BIAS-LFR/TDS (BIAS_i)), and
      - Calibrated values inside BIAS but without demuxer addition and
        subtraction inside BIAS (i.e. including using BIAS offsets, BIAS
        transfer functions; volt).
    NOTE: This definition is partly created to avoid using term "BIAS_i" since
    it is easily confused with other things (the subsystem BIAS, bias currents),
    partly to include various stages of calibration.
CA
    Cell Array.
CLI
    Command-line interface
CTI
    CALIBRATION_TABLE_INDEX (zVariable).
CTI2
    Second value in a CDF record of zVariable CALIBRATION_TABLE_INDEX.
Dataset (data set)
    A CDF file on any one of a number standardized formats specified by the
    various RPW teams. All CDF files in the context of BICAS are datasets.
Deg
    Degrees (angle). 1 revolution=360 degrees=2*pi radians.
DSI
    DATASET_ID
DWNS
    Downsampled. Cf. ORIS.
EMIDP
    (MATLAB) Error Message Identifier Part. One of the colon-separated
    parts of the MException .identifier string field (error message ID).
    NOTE: "Component" has a special meaning in the context of error
    message IDs. Therefore uses the term "part" instead.
FTF
    Forward Transfer Function = TF that describes the conversion of physical
    INPUT to OUTPUT (not the reverse). Cf. ITF.
ICD
    Interface Control Document
ITF
    Inverse Transfer Function = TF that describes the conversion of physical
    OUTPUT to INPUT (not the reverse). Cf. FTF.
IV, ivolt, Interface Volt
    Calibrated volt at the interface between BIAS and LFR/TDS.
IVPAV
    Interface volt/antenna volt
IVPT
    Interface volt Per TM unit. IV/TM.
LSF
    LFR Sampling Frequency (F0...F3).
    NOTE: When used as a variable (array index), 1=F0, ..., 4=F3.
NSO
    Non-Standard Operations. Functionality for making BICAS modify processed
    data based on manually compiled list of "events". Can e.g. set quality
    bits and remove data.
Offset
    Value (constant) that is ADDED to (not subtracted from) a measured
    value during the calibration process.
ORIS
    Original sampling (rate). Used in the context of downsampling. Cf DWNS.
RCS
    RPW Calibration Software. BICAS is an example of an RCS.
RCS ICD
    Originally document ROC-TST-GSE-ICD-00023-LES,
    "RPW Calibration Software ICD Documentation",
    which was later superseded by ROC-PRO-PIP-ICD-00037-LES,
    "RPW Calibration Software Interface Document".
    NOTE: "RCS ICD" does not at this time (2019-07-24) distinguish between these
    two which gives room for confusion since a later rev/iss for the old RCS
    ICD may thus be superseded by a lower rev/iss for the newer RCS ICD.
RCT
    RPW Calibration Table. CDF with calibration data. See RCS ICD. ROC-defined.
RCTS
    RCT CALIBRATION_TABLE (glob.attr) + CALIBRATION_TABLE_INDEX (zVariable).
    S = plural.
ROC
    RPW Operations Center.
ROC DFMD
    Document ROC-TST-GSE-NTT-00017-LES, "Data format and metadata definition for
    the ROC-SGSE data"
ROC Engineering Guidelines
    Document ROC-GEN-SYS-NTT-00019-LES, "ROC
    Engineering Guidelines for External Users"
RPS
    Radians Per Second
RUM
    Document ROC-PRO-SFT-SUM-00080, "RCS User Manual"
RV
    Return Value.
sampere
    "Set current ampere". Exactly proportional to bias current in TM.
Sec
    Seconds
SPR
    Samples (per channel) Per (CDF) Record. Only refers to actual data
    (currents, voltages), not metadata.
SWD, S/W descriptor
    Text on JSON format which describes among other things the S/W modes,
    including the required CLI parameters that every mode requires albeit not
    very clearly. (Defined by the RCS ICD.)
S/W mode
    A "S/W mode" defines a set of required input CDF files and a set of output
    CDF files derived from the input files. BICAS can execute only one such mode
    on each run. Executing such modes is the primary purpose of an RCS. (Defined
    by the RCS ICD.)
TBW
    To Bash Wrapper.
TF
    Transfer Function. Transfer function Z=Z(omega) in the frequency domain.
    Conventionally here on the form of a complex number (Z) as a function of
    radians/s (omega).
TM
    Telemetry units (in LFR/TDS ADC), or telecommand (TC) units. Using this term
    instead of the term "count".
TPIV
    TM/interface volt. TM per interface volt.
UFV
    Use Fill Values. Refers to CDF records which data should overwritten with
    fill values).
ZV
    CDF zVariable, or MATLAB variable that is analogous to one. First dimension
    corresponds to CDF record.



#################
 Main executable
#################
<BICAS root dir>/roc/bicas



#############################
 CLI syntax / CLI parameters
#############################
NOTE: The official CLI parameter syntax is defined in RCS ICD, Iss02 Rev02, Section 3.2.

SYNTAX 1: ( --version | --identification | --swdescriptor | --help ) <General parameters>
SYNTAX 2: <S/W mode> <General parameters, Output parameter, Specific inputs parameters>

NOTE: In syntax 2, the position of the first arguments is important. The order
of all other (groups of) arguments is arbitrary.

--version          Print the software version.
--identification   Print the S/W descriptor release segment.
--swdescriptor     Print the S/W descriptor (not RCS ICD requirement).
--help             Print "help-ish" text



=========================
 Common input parameters
=========================
--log    <absolute path to log file>   (optional) Specifies log file.
--config <absolute path to file>       (optional) Specifies the configuration
                                       file to use.


<S/W mode>   Selects the S/W mode to use.
Available S/W modes can be found in the S/W descriptor. They are listed under
"modes". "name" specifies the string that identifies a given mode and can be
used on as CLI argument.



===========================
 Specific input parameters
===========================
Set of parameters which specify input CDF files. The exact set depends on the
exact S/W mode and can in principle be read from the S/W descriptor.
Required input parameters for a specific S/W mode can be found in the S/W
descriptor under "modes" --> (specific mode) --> "inputs"
--> Name of subsection, e.g. "input_hk", "input_sci".
Example: an input subsection "input_hk" means that there is a required parameter
"--input_hk <path_to_file>".



===============
 Example calls
===============
bicas --version --config ~/bicas.conf
bicas --identification
bicas --identification --log ~/bicas.log
bicas LFR-SURV-CWF-E
    --in_sci   L1R/2020/04/14/solo_L1R_rpw-lfr-surv-swf-e-cdag_20200414_V01.cdf
    --in_cur   BIA/2020/04/solo_L1_rpw-bia-current-cdag_20200401T000000-20200421T000000_V01.cdf
    --in_hk    HK/2020/04/14/solo_HK_rpw-bia_20200414_V02.cdf
    --out_sci  solo_L2_rpw-lfr-surv-swf-e_20200414T000000-20200415T000000_V02.cdf'
    --config   /home/erjo/bicas_batch.conf



###########################################
 Installation, set-up, system requirements
###########################################
See "install.txt".



####################################
 Known current limitations, caveats
####################################
For limitations and caveats, see the official user manual, the RUM
document.
