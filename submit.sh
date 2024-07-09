#!/bin/bash

FNALURL='https://fndcadoor.fnal.gov:2880/dune/scratch/users'
FCL="scripts/jobAtmoAnalysis.fcl"
CODE_TAR="/exp/dune/app/users/pgranger/atmoAnalysis.tar.gz"
# MQL_QUERY="files from fardet-hd:fardet-hd__full-reconstructed__v09_85_00d00__reco2_atmos_dune10kt_1x2x6_geov5__prodgenie_atmnu_max_weighted_randompolicy_dune10kt_1x2x6__out1__v1_official limit 3"
MQL_QUERY="files from fardet-hd:fardet-hd__fd_mc_2023a_reco2__full-reconstructed__v09_81_00d02__standard_reco2_dune10kt_nu_1x2x6__prodgenie_nue_dune10kt_1x2x6__out1__v1_official limit 10000"
DUNE_VERSION="v09_89_01d01"
DUNE_QUALIFIER="e26:prof"

#Getting the right credentials
rm -f /tmp/x509up_u`id -u`
kx509
voms-proxy-init -noregen -rfc -voms dune:/dune/Role=Analysis

echo "Creating the tar with the input fcl"

TMPDIR=$(mktemp -d)
TMPTAR=$TMPDIR/fcl.tar
tar cvf $TMPTAR $FCL

echo "Uploading $TMPTAR to CVMFS"
FCL_TAR_DIR_LOCAL=$(justin-cvmfs-upload ${TMPTAR})
echo "Uploaded to $FCL_TAR_DIR_LOCAL"

echo "Uploading $CODE_TAR to CVMFS"
CODE_TAR_DIR_LOCAL=$(justin-cvmfs-upload ${CODE_TAR})
echo "Uploaded to $CODE_TAR_DIR_LOCAL"

while : ; do
    if [ -d "$FCL_TAR_DIR_LOCAL" ] && [ -d "$CODE_TAR_DIR_LOCAL" ]; then
        break
    else
        echo "Files are not yet available on cvmfs. Sleeping 10s..."
        sleep 10
    fi
done

# FCL_FILE=$FCL_TAR_DIR_LOCAL/$(basename ${FCL})
FCL_FILE=$FCL_TAR_DIR_LOCAL/${FCL}
#justin-test-jobscript
justin simple-workflow \
--mql "$MQL_QUERY" \
--env FCL_FILE="$FCL_FILE" \
--env CODE_TAR_DIR_LOCAL="$CODE_TAR_DIR_LOCAL" \
--env DUNE_VERSION="$DUNE_VERSION" \
--env DUNE_QUALIFIER="$DUNE_QUALIFIER" \
--env HAS_ART_OUTPUT=false \
--jobscript scripts/standard-fcl.jobscript \
--max-distance 30 \
--rss-mib 4000 \
--scope usertests \
--output-pattern "*ana*.root:$FNALURL/$USER" \
--lifetime-days 1

#--env NUM_EVENTS=1 \

