#!/bin/bash

# Copyright (C) 2015-2017  Unreal Arena
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Travis CI support script


################################################################################
# Setup
################################################################################

# Arguments parsing
if [ $# -ne 1 ]; then
	echo "Usage: ${0} <STEP>"
	exit 1
fi


################################################################################
# Routines
################################################################################

# before_install
before_install() {
	sudo apt-get -qq update
}

# install
install() {
	sudo apt-get -qq install libjpeg-turbo8\
	                         libpng12-0\
	                         libxml2\
	                         zlib1g
	git clone https://gitlab.com/xonotic/netradiant.git
	cd netradiant
	mkdir build
	cd build
	cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release ..
	cmake --build . --target q3map2 -- -j8 ||
	cmake --build . --target q3map2 -- VERBOSE=1
	cd ../..
	git clone https://github.com/BinomialLLC/crunch
	cd crunch
	# sed -i '24s/size_t/auto/' crnlib/crn_vector.cpp
	cd crnlib
	make -j8 ||
	make VERBOSE=1
	./crunch
	cd ../..
}

# before_script
before_script() {
	mkdir -p "${HOMEPATH}"
	ln -s "$(readlink -f "maps/${MAP}")" "${HOMEPATH}/pkg"
}

# script
script() {
	cd "maps/${MAP}"
	q3map2 -threads 8\
	       -fs_homebase .unrealarena\
	       -fs_game pkg\
	       -meta\
	       -custinfoparms\
	       -keeplights\
	       "maps/${MAP}.map"
	q3map2 -threads 8\
	       -fs_homebase .unrealarena\
	       -fs_game pkg\
	       -vis\
	       -saveprt\
	       "maps/${MAP}.map"
	q3map2 -threads 8\
	       -fs_homebase .unrealarena\
	       -fs_game pkg\
	       -light\
	       -faster\
	       "maps/${MAP}.map"
	zip -r9 "../../map-${MAP}_${MAPVERSION}.pk3" . -x "maps/${MAP}.srf" "maps/${MAP}.prt"
}

# before_deploy
before_deploy() {
	if [ "${MAPVERSION}" = "${TAGMAPVERSION}" ]; then
		curl -LsO "https://github.com/unrealarena/unrealarena-maps/releases/download/${TAG}/map-${MAP}.pre.zip"
	else
		zip -9 "map-${MAP}.pre.zip" "map-${MAP}_${MAPVERSION}.pk3"
	fi
}


################################################################################
# Main
################################################################################

# Arguments check
if ! `declare -f "${1}" > /dev/null`; then
	echo "Error: unknown step \"${1}\""
	exit 1
fi

# Enable exit on error & display of executing commands
set -ex

# Run <STEP>
${1}
