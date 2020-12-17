#!/bin/bash -x

# Set up an environment for running CAMISIM in a container, even when
# the container is run read-only (e.g. CWL) and even when the user is
# unprivileged (e.g. Openshift).
#
# Works around two invalid assumptions: by CAMISIM, that it is invoked
# from its install directory, rather than a writeable working
# directory; and by ete2, that it can write both in its invocation
# directory and in $HOME.

echo Invocation $@

# CAMISIM expects to be invoked from its install directory.
# In an ideal world this variable is set by a container image.
CASISIM=${CAMISIM:-/usr/local/bin}

# Location of the taxonomy database expected or created by ete2.
ETE2_TAXDB=$HOME/.etetoolkit/taxa.sqlite

# $HOME must be writeable, even if the container user is unprivileged.
# Note that when invoking from CWL, only the output and temporary
# directories are guaranteed to be writeable, as per
# [4.2](https://www.commonwl.org/v1.1/CommandLineTool.html#Runtime_environment)
touch "$HOME/." || export HOME=${TMPDIR:=/tmp}

# # The container can be invoked with extra arguments, in environment
# # variables to avoid polluting the CLI arguments.
# [ -s "$TAXDB" -a ! -s $ETE2_TAXDB ] && mkdir -p $(dirname $ETE2_TAXDB) && cp "$TAXDB" $ETE2_TAXDB

# If the current working directory of this invocation isn't $HOME but does
# contain an ete2 taxonomy dump, copy the dump to the expected place.
# (This can happen in containers with unexpected bind mounts.)
[ -s ./.etetoolkit/taxa.sqlite -a ! ./.etetoolkit/taxa.sqlite -ef $ETE2_TAXDB ] &&
    mkdir -p $(dirname $ETE2_TAXDB) &&
    cp ./.etetoolkit/taxa.sqlite $ETE2_TAXDB

# Preload the ete2 taxonomy, in $HOME, which is writeable, rather than in
# $CAMISIM, which might not be.
echo -e "from ete2 import NCBITaxa\nNCBITaxa()" |
    (cd $HOME && python)

# # Copy taxonomy file to output if requested.
# [ "$KEEP_TAXDB" ] && cp $ETE2_TAXDB $HOME/out-taxa.sqlite

# MAIN EVENT: run the selected program in the expected directory,
# return exit code.
cd $CAMISIM && exec python $@
