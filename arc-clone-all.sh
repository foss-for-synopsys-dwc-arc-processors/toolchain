#!/bin/sh
 
# Copyright (C) 2013 Embecosm Limited.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# A script to clone all the components of the ARC tool chain

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


# -----------------------------------------------------------------------------
#		     CLONE ALL ARC TOOL CHAIN COMPONENTS
#		     ===================================

# Run this in the toolchain directory. You should have first cloned this
# repository and then changed directory into it:

#   git clone https://github.com/foss-for-synopsys-dwc-arc-processors/toolchain.git
#   cd toolchain

# If you are a developer you may be using SSH:

#   git clone git@github.com:foss-for-synopsys-dwc-arc-processors/toolchain.git
#   cd toolchain

# Usage:

#   arc-clone-all.sh [-f | --force] [-d | --dev]

# The arguments have the following meanings

# --force
# -f

#     Delete any existing clone of an ARC repository

# -dev
# -d

#     Developer mode. Attempt to clone each ARC repository using SSH (allowing
#     write as well as read access) and also fetch the upstream repository. If
#     SSH clone fails silently use HTTPS.

# The script tests that the parent directory (the one containing toolchain) is
# writable, so it can be used for all the other repositories.


# -----------------------------------------------------------------------------
# Function to parse args
parse_args () {
    # Defaults
    do_force="false"
    is_dev="false"

    # Get the arguments
    until
    opt=$1
    case ${opt} in
	--force | -f)
	    do_force="true"
	    ;;

	--dev | -d)
	    is_dev="true"
	    ;;

	?*)
	    echo "Usage: arc-clone-all.sh [--force | -f] [--dev | -d]"
	    return 1
	    ;;

	*)
	    ;;
    esac
    [ "x${opt}" = "x" ]
    do
	shift
    done

    # Success
    return 0
}

# -----------------------------------------------------------------------------
# Function to clone a tool and (optionally) its upstream. The ARC branches of
# the tool will be from a remote called "arc", the upstream branches from a
# remote called "upstream".

# @param $1  Name of the tool
# @param $2  (Optional) URL of upstream repo (minus tool name and .git)
# @return 0 on success, 1 on failure to clone or fetch
clone_tool () {
    tool=$1
    upstream=$2
    ssh_repo="${ssh_prefix}${org}/${tool}.git"
    http_repo="${http_prefix}${org}/${tool}.git"

    echo "Cloning ${tool}..." | tee -a ${logfile}

    # Check there is nothing there or clear it out as appropriate.
    cd ${ARC_GNU}
    if [ ${do_force} = "true" ]
    then
	echo "- removing any existing clone" | tee -a ${logfile}
	rm -rf ${tool}
    elif [ -e ${tool} ]
    then
	echo "Warning: existing clone of ${tool} not replaced" \
	    | tee -a ${logfile}
	return 1
    fi

    # Clone the ARC repo
    if [ ${is_dev} = "false" ] \
	|| ! git clone -q -o arc ${ssh_repo} >> ${logfile} 2>&1
    then
	if ! git clone -q -o arc ${http_repo} >> ${logfile} 2>&1
	then
	    echo "Warning: Failed to clone ${http_repo}" | tee -a ${logfile}
	    return 1
	else
	    echo "- successfully cloned ARC ${tool} repository" \
		| tee -a ${logfile}
	fi
    else
	echo "- successfully cloned ARC ${tool} repository (dev)" \
	    | tee -a ${logfile}
    fi
    
    # Optionally add the upstream repository and fetch it
    if [ ${is_dev} = "true" -a "x${upstream}" != "x" ]
    then
	cd ${tool}
	# Add
	if ! git remote add upstream ${upstream}${tool}.git
	then
	    echo "Warning: failed to add ${upstream}${tool}.git as remote" \
		| tee -a ${logfile}
	    return 1
	fi
	# Fetch
	if git fetch -q upstream >> ${logfile} 2>&1
	then
	    echo "- successfully fetched upstream ${tool} repository" \
		| tee -a ${logfile}
	else
	    echo "Warning: failed to fetch upstream ${tool} repository" \
		| tee -a ${logfile}
	    echo "- manually run 'git fetch upstream'" | tee -a ${logfile}
	    return 1
	fi
    fi
}

# -----------------------------------------------------------------------------
# Main script
http_prefix=https://github.com/
ssh_prefix=git@github.com:
org=foss-for-synopsys-dwc-arc-processors

# Get the args
if ! parse_args $*
then
    exit 1
fi

# Generic release set up, which we'll share with sub-scripts. This defines
# (and exports RELEASE, LOGDIR and RESDIR, creating directories named $LOGDIR
# and $RESDIR if they don't exist.
d=`dirname "$0"`
ARC_GNU=`(cd "$d/.." && pwd)`
export ARC_GNU
. ${ARC_GNU}/toolchain/define-release.sh

# Set up a logfile
logfile="${LOGDIR}/clone-all-$(date -u +%F-%H%M).log"
rm -f "${logfile}"

echo "Cloned directories will be created in ${ARC_GNU}" | tee -a ${logfile}

# Can we create directories in the parent?
echo "Checking we can write in ${ARC_GNU}" | tee -a ${logfile}
td=${ARC_GNU}/clone-test-dir
rm -rf ${td}
if mkdir ${td} >> ${logfile} 2>&1
then
    rm -rf ${td}
else
    echo "ERROR: Cannot create repository directories" | tee -a ${logfile}
    exit 1
fi

# Clone all the ARC tools and the toolchain scripts
status="ok"
clone_tool cgen      https://github.com/embecosm/ || status="failed"
clone_tool binutils  git://sourceware.org/git/    || status="failed"
clone_tool gcc       https://github.com/mirrors/  || status="failed"
clone_tool gdb       git://sourceware.org/git/    || status="failed"
clone_tool newlib    git://sourceware.org/git/    || status="failed"
clone_tool uClibc    git://uclibc.org/            || status="failed"
clone_tool linux     https://github.com/torvalds/ || status="failed"

# All done
if [ "${status}" = "ok" ]
then
    echo "All repositories cloned" | tee -a ${logfile}
    echo "- full logs in ${logfile}" | tee -a ${logfile}
    exit 0
else
    echo "Some repositories cloned" | tee -a ${logfile}
    echo "- full logs in ${logfile}" | tee -a ${logfile}
    exit 1
fi
