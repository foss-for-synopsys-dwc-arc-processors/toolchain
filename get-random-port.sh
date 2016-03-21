#!/bin/sh

# Copyright (C) 2013-2016 Synopsys Inc.

# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.

# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.

# You should have received a copy of the GNU General Public License along
# with this program.  If not, see <http://www.gnu.org/licenses/>.

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

# vim: expandtab sts=4:
