#! /bin/sh -pe

# libhsync -- the library for network deltas
# $Id$
# 
# Copyright (C) 2000 by Martin Pool <mbp@linuxcare.com.au>
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License
# as published by the Free Software Foundation; either version 2.1 of
# the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public
# License along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.


                                     # I think if you've ordered
				     # somebody to do something you
				     # should probably resist the urge
				     # to thank them.
				     #    -- http://abc.net.au/thegames/



# Generate code for the instruction tables

cat <<EOF 
/* AUTOGENERATED BY $0, DO NOT EDIT */

#include "config.h"

#include <stdlib.h>
#include <stdio.h>

#include "hsync.h"
#include "protocol.h"
#include "command.h"
#include "prototab.h"

/* This file defines an array mapping command IDs to the operation kind,
 * implied literal value, length of the first and second parameters,
 * and length of the whole command.  The implied value is only used
 * if the first parameter length is zero. */

const struct hs_prototab_ent _hs_prototab[] = {
EOF

not_first=
value=0
emit_cmd() {
    # usage: emit_cmd kind literalval len1 len2
    if test "$not_first"
    then 
	printf ', \n'
    fi
    not_first=1
    len=`expr 1 + $3 + $4 `
    printf '    { HS_KIND_%-10s, %3d, %d, %d, %d }            /* %#4x */' $@ $len $value
    value=`expr $value + 1 `
}

emit_cmd EOF 0 0 0

for i in `seq 1 120`
do
    emit_cmd LITERAL $i 0 0
done

for i in 1 2 4
do 
    emit_cmd LITERAL 0 $i 0
done

for i in `seq 1 119`
do
    emit_cmd SIGNATURE $i 0 0
done

for i in 1 2 4
do 
    emit_cmd SIGNATURE 0 $i 0
done

emit_cmd CHECKSUM 0 2 0

for i in 2 4
do
    for j in 1 2 4
    do
	emit_cmd COPY 0 $i $j
    done
done

# These would be int64 COPY commands, but we don't support long files
# yet so they're illegal.

for j in 1 2 4
do
    emit_cmd RESERVED 0 8 $j
done

# we've just moved past the last command, so assert value == 0xff+1
if test $value -ne 256
then
    printf "$0: internal inconsistency: last command is %#x not 0xff\n" \
	`expr $value - 1` >&2
    exit 1
fi

cat <<EOF
};


/* End of autogenerated code.  We now return you to your regularly scheduled
 * programming. */
EOF
