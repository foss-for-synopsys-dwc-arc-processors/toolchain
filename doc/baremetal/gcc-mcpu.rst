.. index:: mcpu, compiler

Understanding GCC -mcpu option
==============================

The GCC option ``-mcpu=`` for ARC does not only designate the ARC CPU family
(ARC EM, HS, 600 or 700), but also enables the corresponding set of optional
instructions defined for the selected configuration. Therefore a particular
``-mcpu`` value selects not only a family, but also other ``-m<something>`` GCC
options for ARC.

Value of ``-mcpu=`` option not only sets various other ``-m<something>``
options to particular values, but also selects a specific standard library
build which was done for this particular core configuration. It is possible to
override selection of hardware extensions by passing individual
``-m<something>`` options to compiler *after* the ``-mcpu=`` option, however
standard library build used for linkage still will be the one matching
``-mcpu=`` value. Therefore, for example, option combination ``-mcpu=em4
-mno-code-density`` will generate code that doesn't use code density
instructions, however it will be linked with standard library that has been
built with just ``-mcpu=em4``, which uses code density instructions - therefore
final application still may use code density instructions. That's why TCF
generator, for example, analyzes hardware features present in the configured
processor and selects ``-mcpu=`` value that is the best match for this
configuration.


ARC EM
------

The following table summarize what options are set by each of the possible
``-mcpu`` values for ARC EM.

.. table:: -mcpu values for ARC EM

    ========= ======== ======== ======== ========= ======= ========= ======= ======
     -mcpu=   -mcode\   -mnorm   -mswap  -mbarrel\  -mdiv\  -mmpy\    -mfpu  -mrf16
              -density                   -shifter   -rem    -option
    ========= ======== ======== ======== ========= ======= ========= ======= ======
       em                                                   none
     em_mini                                                none               Y
       em4       Y                                          none
      arcem      Y                           Y              wlh1
    em4_dmips    Y        Y        Y         Y        Y     wlh1
    em4_fpus     Y        Y        Y         Y        Y     wlh1      fpus
    em4_fpuda    Y        Y        Y         Y        Y     wlh1      fpuda
    ========= ======== ======== ======== ========= ======= ========= ======= ======

The above ``-mcpu`` values correspond to specific ARC EM Processor templates
presented in the ARChitect tool. It should be noted however that some ARC
features are not currently supported in the GNU toolchain, for example DSP
instruction support, reduced register size and reduced register sets.
Relationship between ``-mcpu`` values above and ARC EM Processor templates in
ARChitect tool are limited to options listed in the table.  Tables will be
updated as support for more options get added to the GNU toolchain.

* ``-mcpu=em`` doesn't correspond to any specific template, it simply defines
  the base ARC EM configuration without any optional instructions.
* ``-mcpu=em_mini`` is same as ``em``, but uses reduced register file with
  only 16 core registers.
* ``-mcpu=em4`` is a base ARC EM core configuration with ``-mcode-density``
  option.  It corresponds to the following ARC EM templates in ARChitect:
  em4_mini, em4_sensor, em4_ecc, em6_mini, em5d_mini, em5d_mini_v3, em5d_nrg,
  em7d_nrg, em9d_mini. Note, however, that those ``mini`` templates has a
  reduced core register file, while this option doesn't specify it.
* ``-mcpu=arcem`` doesn't correspond to any specific template, it is legacy
  flag preserved for compatibility with older GNU toolchain versions, where
  ``-mcpu`` used to select only a CPU family, while optional features were
  enabled or disable by individual ``-m<something>`` options.
* ``-mcpu=em4_dmips`` is a full-featured ARC EM configuration for integer
  operations. It corresponds to the following ARC EM templates in ARChitect:
  em4_dmips, em4_rtos, em6_dmips, em4_dmips_v3, em4_parity, em6_dmips_v3,
  em6_gp, em5d_voice_audio, em5d_nrg_v3, em7d_nrg_v3, em7d_voice_audio,
  em9d_nrg, em9d_voice_audio, em11d_nrg and em11d_voice_audio.
* ``-mcpu=em4_fpus`` is like ``em4_dmips`` but with additional support for
  single-precision floating point unit. It corresponds to the following ARC EM
  templates in ARChitect: em4_dmips_fpusp, em4_dmips_fpusp_v3, em5d_nrg_fpusp
  and em9d_nrg_fpusp.
* ``-mcpu=em4_fpuda`` is like ``em4_fpus`` but with additional support for
  double-precision assist instructions. It corresponds to the following ARC EM
  templates in ARChitect: em4_dmips_fpuspdp and em4_dmips_fpuspdp_v3.
* ``-mcpu=quarkse_em`` is a configuration for ARC processor in Intel Quark SE chip.

  ================== ============
    Option            quarkse_em
  ================== ============
   -mcode-density         Y
   -mnorm                 Y
   -mswap                 Y
   -mbarrel-shifter       Y
   -mdiv-rem              Y
   -mmpy-option          wlh2
   -mfpu                quark
   -mrf16
  ================== ============


ARC HS
------

The following table summarize what options are set by each of the possible ``-mcpu``
values for ARC HS.

.. table:: -mcpu values for ARC HS

   ============ =========== ========== ========= =============== =========
      -mcpu=     -mdiv-rem   -matomic   -mll64    -mmpy-option    -mfpu
   ============ =========== ========== ========= =============== =========
        hs                      Y                      none
       hs34                     Y                      mpy
      archs          Y          Y          Y           mpy
       hs38          Y          Y          Y        plus_qmacw
       hs4x          Y          Y          Y        plus_qmacw
      hs4xd          Y          Y          Y        plus_qmacw
    hs38_linux       Y          Y          Y        plus_qmacw    fpud_all
   ============ =========== ========== ========= =============== =========

The above ``-mcpu`` values correspond to specific ARC HS Processor templates
presented in the ARChitect tool. It should be noted however that some ARC
features are not currently supported in the GNU toolchain, for example reduced
register size and reduced register sets.  Relationship between ``-mcpu`` values
above and ARC HS Processor templates in ARChitect tool are limited to options
listed in the table.  Tables will be updated as support for more options get
added to the GNU toolchain.

* ``-mcpu=hs`` corresponds to a basic ARC HS with only atomic instructions
  enabled. It corresponds to the following ARC HS templates in ARChitect:
  hs34_base, hs36_base and hs38_base.
* ``-mcpu=hs34`` is like ``hs`` but with with additional support for standard
  hardware multiplier.  It corresponds to the following ARC HS templates in
  ARChitect: hs34, hs36 and hs38.
* ``-mcpu=archs`` is a generic CPU, which corresponds to the default
  configuration in older GNU toolchain versions.
* ``-mcpu=hs38`` is a fully featured ARC HS.  It corresponds to the following
  ARC HS templates in ARChitect: hs38_full
* ``-mcpu=hs4x`` and ``-mcpu=hs4xd`` have same option set as ``-mcpu=hs38`` but compiler will
  optimize instruction scheduling for specified processors.
* ``-mcpu=hs38_linux`` is a fully featured ARC HS with additional support for
  double-precision FPU.


ARC 600 and ARC 700
-------------------

The following table summarize what options are set by each of the possible ``-mcpu``
values for ARC 600 and ARC 700.

.. table:: -mcpu values for ARC 600 and ARC 700

   ================= ======== ======== ================== ============
         -mcpu        -mnorm   -mswap   -mbarrel-shifter   multiplier
   ================= ======== ======== ================== ============
        arc700           Y       Y             Y             -mmpy
        arc600                                 Y
      arc600_norm        Y                     Y
     arc600_mul64        Y                     Y            -mmul64
    arc600_mul32x16      Y                     Y           -mmul32x16
        arc601
      arc601_norm        Y
     arc601_mul64        Y                                  -mmul64
    arc601_mul32x16      Y                                 -mmul32x16
   ================= ======== ======== ================== ============

.. vim: sts=3 sw=3 ts=3 tw=100:
