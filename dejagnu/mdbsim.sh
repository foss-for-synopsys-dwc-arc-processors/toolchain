#!/bin/sh
mdb -nsim -noproject -nooptions -run $*
RET=$?
echo "*** EXIT code ${RET}"
