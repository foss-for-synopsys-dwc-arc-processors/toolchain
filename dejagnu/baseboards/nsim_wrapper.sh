#!/bin/bash

ret=$(${NSIM_HOME}/bin/nsimdrv -prop=nsim_isa_family=arc64 -prop=nsim_emt=1 -on=trace $1 | timeout 30s grep -E "mov[ \t]+r0,r0")
if [ $? -eq 124 ]
then
  #echo "Timeout!!!!"
  echo "*** EXIT code 255"
  exit 255
fi
ret=$(echo ${ret} | grep -o -E "r0 <= 0x[^ ]+" | cut -d'x' -f 2)
ret=$((16#${ret}))

echo "*** EXIT code ${ret}"
exit ${ret}
