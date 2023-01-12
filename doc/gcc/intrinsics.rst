Intrinsics in ARC GNU vs MWDT
=================================

If one is interested in ARC-specific GCC built-ins those
might be found in upstream documentation here:
`<https://gcc.gnu.org/onlinedocs/gcc/ARC-Built-in-Functions.html>`_.

Note to use listed below intrinsics it's required to include
``arcle.h`` in your source file that way:

.. code:: c

    #include <arcle.h>

.. table:: List of ARC intrinsics supported by MetaWare & GCC compilers
   :widths: auto

   =================== ==============
    MetaWare compiler   GCC compiler
   =================== ==============
   _abss               _abss
   _abssh              _abssh
   _adcs               _adcs
   _add                Not planned
   _add1               Not planned
   _add1_f             Not planned
   _add2               Not planned
   _add2_f             Not planned
   _add3               Not planned
   _add3_f             Not planned
   _add_f              Not planned
   _adds               _adds
   _adds_f             Not planned
   _aex                Unsupported
   _and                Not planned
   _and_f              Not planned
   _asl                Not planned
   _asl_f              Not planned
   _aslacc             _aslacc
   _asls               _asls
   _asls_f             Not planned
   _aslsacc            _aslsacc
   _asr                Not planned
   _asr_f              Not planned
   _asrs               _asrs
   _asrs_f             Not planned
   _asrsr              _asrsr
   _asrsr_f            Not planned
   _bclr               Not planned
   _bclr_f             Not planned
   _bmsk               Not planned
   _bmsk_f             Not planned
   _bset               Not planned
   _bset_f             Not planned
   _btst_f             Not planned
   _bxor               Not planned
   _bxor_f             Not planned
   _cbflyhf0r          _cbflyhf0r
   _cbflyhf1r          _cbflyhf1r
   _cmacchfr           _cmacchfr
   _cmacchnfr          _cmacchnfr
   _cmachfr            _cmachfr
   _cmachnfr           _cmachnfr
   _cmpychfr           _cmpychfr
   _cmpychnfr          _cmpychnfr
   _cmpyhfmr           _cmpyhfmr
   _cmpyhfr            _cmpyhfr
   _cmpyhnfr           _cmpyhnfr
   _divf               _divf
   _dmach              _dmach
   _dmachbl            _dmachbl
   _dmachbm            _dmachbm
   _dmachf             _dmachf
   _dmachfr            _dmachfr
   _dmachu             _dmachu
   _dmacwh             _dmacwh
   _dmacwhf            _dmacwhf
   _dmacwhu            _dmacwhu
   _dmpyh              _dmpyh
   _dmpyhbl            _dmpyhbl
   _dmpyhbm            _dmpyhbm
   _dmpyhf             _dmpyhf
   _dmpyhfr            _dmpyhfr
   _dmpyhu             _dmpyhu
   _dmpyhwf            _dmpyhwf
   _dmpywh             _dmpywh
   _dmpywhf            _dmpywhf
   _dmpywhu            _dmpywhu
   _ex                 unsupported
   _ex_di              unsupported
   _ffs                unsupported
   _flagacc            _flagacc
   _fls                unsupported
   _getacc             _getacc
   _kflag              _kflag
   _lr                 _lr
   _lsr                Not planned
   _lsr_f              Not planned
   _mac                _mac
   _macd               _macd
   _macdf              _macdf
   _macdu              _macdu
   _macf               _macf
   _macfr              _macfr
   _macu               _macu
   _macwhfl            _macwhfl
   _macwhflr           _macwhflr
   _macwhfm            _macwhfm
   _macwhfmr           _macwhfmr
   _macwhkl            _macwhkl
   _macwhkul           _macwhkul
   _macwhl             _macwhl
   _macwhul            _macwhul
   _max_f              Not planned
   _min_f              Not planned
   _modif              Not planned
   _mov_f              Not planned
   _mpy                Not planned
   _mpyd               Not planned
   _mpydf              _mpydf
   _mpydu              Not planned
   _mpyf               _mpyf
   _mpyfr              _mpyfr
   _mpym               Not planned
   _mpymu              Not planned
   _mpyu               Not planned
   _mpywhfl            _mpywhfl
   _mpywhflr           _mpywhflr
   _mpywhfm            _mpywhfm
   _mpywhfmr           _mpywhfmr
   _mpywhkl            _mpywhkl
   _mpywhkul           _mpywhkul
   _mpywhl             _mpywhl
   _mpywhul            _mpywhul
   _msubdf             _msubdf
   _msubf              _msubf
   _msubfr             _msubfr
   _msubwhfl           _msubwhfl
   _msubwhflr          _msubwhflr
   _msubwhfm           _msubwhfm
   _msubwhfmr          _msubwhfmr
   _negs               _negs
   _negs_f             Not planned
   _negsh              _negsh
   _negsh_f            Not planned
   _norm               Not planned
   _norm_f             Not planned
   _normacc            _normacc
   _normh              Not planned
   _normh_f            Not planned
   _normw              Not planned
   _normw_f            Not planned
   _or                 Not planned
   _or_f               Not planned
   _qmach              _qmach
   _qmachf             _qmachf
   _qmachu             _qmachu
   _qmpyh              _qmpyh
   _qmpyhf             _qmpyhf
   _qmpyhu             _qmpyhu
   _rndh               _rndh
   _rndh_f             Not planned
   _ror                Not planned
   _ror_f              Not planned
   _rrc                Not planned
   _rrc_f              Not planned
   _satf               _satf
   _sath               _sath
   _sath_f             Not planned
   _sbcs               _sbcs
   _setacc             _setacc
   _sqrt               _sqrt
   _sqrtf              _sqrtf
   _sr                 _sr
   _sub                Not planned
   _sub1               Not planned
   _sub1_f             Not planned
   _sub2               Not planned
   _sub2_f             Not planned
   _sub3               Not planned
   _sub3_f             Not planned
   _sub_f              Not planned
   _subs               _subs
   _subs_f             Not planned
   _trap               _trap
   _vabs2h             _vabs2h
   _vabss2h            _vabss2h
   _vadd2              _vadd2
   _vadd2h             _vadd2h
   _vadd4b             _vadd4b
   _vadd4h             _vadd4h
   _vadds2             _vadds2
   _vadds2h            _vadds2h
   _vadds4h            _vadds4h
   _vaddsub            _vaddsub
   _vaddsub2h          _vaddsub2h
   _vaddsub4h          _vaddsub4h
   _vaddsubs           _vaddsubs
   _vaddsubs2h         _vaddsubs2h
   _vaddsubs4h         _vaddsubs4h
   _valgn2h            _valgn2h
   _vasl2h             _vasl2h
   _vasls2h            _vasls2h
   _vasr2h             _vasr2h
   _vasrs2h            _vasrs2h
   _vasrsr2h           _vasrsr2h
   _vext2bhl           _vext2bhl
   _vext2bhlf          _vext2bhlf
   _vext2bhm           _vext2bhm
   _vext2bhmf          _vext2bhmf
   _vlsr2h             _vlsr2h
   _vmac2h             _vmac2h
   _vmac2hf            _vmac2hf
   _vmac2hfr           _vmac2hfr
   _vmac2hnfr          _vmac2hnfr
   _vmac2hu            _vmac2hu
   _vmax2h             _vmax2h
   _vmin2h             _vmin2h
   _vmpy2h             _vmpy2h
   _vmpy2hf            _vmpy2hf
   _vmpy2hfr           _vmpy2hfr
   _vmpy2hu            _vmpy2hu
   _vmpy2hwf           _vmpy2hwf
   _vmsub2hf           _vmsub2hf
   _vmsub2hfr          _vmsub2hfr
   _vmsub2hnfr         _vmsub2hnfr
   _vneg2h             _vneg2h
   _vnegs2h            _vnegs2h
   _vnorm2h            _vnorm2h
   _vpack2hbl          _vpack2hbl
   _vpack2hblf         _vpack2hblf
   _vpack2hbm          _vpack2hbm
   _vpack2hbmf         _vpack2hbmf
   _vpack2hl           _vpack2hl
   _vpack2hm           _vpack2hm
   _vperm              _vperm
   _vrep2hl            _vrep2hl
   _vrep2hm            _vrep2hm
   _vsext2bhl          _vsext2bhl
   _vsext2bhm          _vsext2bhm
   _vsub2              _vsub2
   _vsub2h             _vsub2h
   _vsub4b             _vsub4b
   _vsub4h             _vsub4h
   _vsubadd            _vsubadd
   _vsubadd2h          _vsubadd2h
   _vsubadd4h          _vsubadd4h
   _vsubadds           _vsubadds
   _vsubadds2h         _vsubadds2h
   _vsubadds4h         _vsubadds4h
   _vsubs2             _vsubs2
   _vsubs2h            _vsubs2h
   _vsubs4h            _vsubs4h
   _wevt               Unsupported
   =================== ==============
