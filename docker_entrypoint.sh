#!/bin/bash

# Set up an environment for running CAMISIM in a container, even when
# the container is run read-only (e.g. CWL) and even when the user is
# unprivileged (e.g. Openshift).
#
# Works around two invalid assumptions: by CAMISIM, that it is invoked
# from its install directory, rather than a writeable working
# directory; and by ete2, that it can write both in its invocation
# directory and in $HOME.
# Also works around an inconsisteny, where CAMISIM is provided an NCBI
# taxonomy file, but ete2 downloads a new one from the NCBI anyway.

# CAMISIM expects to be invoked from its install directory.
# In an ideal world this variable is set by the container image.
CASMISIM=${CAMISIM:-/usr/local/bin}

# $HOME must be writeable, even if the container user is unprivileged.
# Note as per [4.2](https://www.commonwl.org/v1.1/CommandLineTool.html#Runtime_environment)
# only the output and temporary directories need be writeable.
touch "$HOME/." || export HOME=${TMPDIR:=/tmp}

# Location of the taxonomy source file expected by ete2.
TAXDUMP=$HOME/taxdump.tar.gz

# The container can be invoked with extra arguments, in environment
# variables to avoid polluting the CLI arguments.
# Reuse boolean argument variables for output file names.
[ "$KEEP_TAXDUMP" ] && KEEP_TAXDUMP=$HOME/out-taxdump.tar.gz
[ "$KEEP_TAXDB" ] && KEEP_TAXDB=$HOME/out-taxa.sqlite

# Save the command line since CLI argument scanning will change $@
INVOCATION=$@

# Evaluate CLI arguments.
# Note that CLI arguments may be relative to $CAMISIM directory.
cd $CAMISIM
eval set -- "$(getopt -o '' -ql ncbi: -- "$@")"
while [ $# -ge 1 ]; do
    case "$1" in
	--ncbi)
	    # If NCBI taxonomy file specified explicitly, use it for ete2, too.
	    [ -f "$2" ] ln -s "$2" $TAXDUMP;
	    shift
	    ;;
    esac
    shift
done

# Preload ete2 taxonomy, in $HOME, which is writeable, rather than in
# $CAMISIM, which might not be.
echo -e "from ete2 import NCBITaxa\nNCBITaxa()" |
    (cd $HOME && python)

# Output directory is $HOME, so can just link taxonomy file.
[ "$KEEP_TAXDUMP" ] && ln $TAXDUMP $KEEP_TAXDUMP
[ "$KEEP_TAXDB" ] && ln $HOME/.etetoolkit/taxa.sqlite $KEEP_TAXDB

# MAIN EVENT: run the selected program in the expected directory,
# return exit code.
cd $CAMISIM && exec python $INVOCATION
