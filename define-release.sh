#!/bin/sh

# Copyright (C) 2013 Synopsys Inc.

# Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

# A script to define and set up release specific environment variables and
# directories.

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

#		SCRIPT TO DEFINE RELEASE SPECIFIC INFORMATION
#               =============================================

# Script must be sourced, since it sets up environment variables for the
# parent script.

# Defines the RELEASE, LOGDIR and RESDIR environment variables, creating the
# LOGDIR and RESDIR directories if they don't exist.

# The following pre-requisites must be defined

# ARC_GNU

#     The directory containing all the sources. Log and results files are
#     created within this directory.


# The Synopsys release number
RELEASE=mainline

# Create a common log directory for all logs in this and sub-scripts
LOGDIR=${ARC_GNU}/logs-${RELEASE}
mkdir -p ${LOGDIR}

# Create a common results directory in which sub-directories will be created
# for each set of tests.
RESDIR=${ARC_GNU}/results-${RELEASE}
mkdir -p ${RESDIR}

# Export the environment variables
export RELEASE
export LOGDIR
export RESDIR
