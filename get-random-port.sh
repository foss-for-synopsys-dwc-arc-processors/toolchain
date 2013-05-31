#!/bin/bash

# 20000 : 64000
begin=20000
range=44000
portnum=

while [ -z "${portnum}" ]; do
    portnum=$(python -c "import random, math; print(int(math.floor(random.random() * ${range} + ${begin})))")
#    lsof -iTCP -sTCP:LISTEN -Fn | awk -F : '/n*:/ { print $2 }' | grep -q ${portnum}
    lsof -iTCP -Fn | \
        awk -F : '/n*:[0-9]+$/ { print $2 } /n*:[0-9]+->/ { print substr($2, 0, index($2, "->") - 1 ) }' | \
        grep -q ${portnum}
    if [ $? -eq 0 ]; then
        portnum=
    fi
done

echo "${portnum}"

