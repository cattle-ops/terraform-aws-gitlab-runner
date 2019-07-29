#!/bin/bash

which awk 2>&1 >/dev/null || ( echo "awk not available"; exit 1)
which terraform 2>&1 >/dev/null || ( echo "terraform not available"; exit 1)
which terraform-docs 2>&1 >/dev/null || ( echo "terraform-docs not available"; exit 1)

if [[ "`terraform version | head -1`" =~ 0\.12 ]]; then
    TMP_FILE="$(mktemp /tmp/terraform-docs.XXXXXXXXXX)"
    awk -f ${PWD}/ci/bin/terraform-docs.awk $2/*.tf > ${TMP_FILE}
    terraform-docs $1 ${TMP_FILE}
    exit 1
    #rm -f ${TMP_FILE}
else
    terraform-docs $1 $2
fi
