#!/bin/bash

GIT_REF=${GIT_REF:-develop}

# script to auto-generate terraform documentation

pandoc -v &> /dev/null || { echo >&2 "ERROR: Pandoc not installed" ; exit 1 ; }
terraform-docs --version &> /dev/null || { echo >&2 "ERROR: terraform-docs not installed" ; exit 1 ; }

IFS=$'\n'
# create an array of all unique directories containing .tf files 
arr=($(find . -name '*.tf' | xargs -I % sh -c 'dirname %' | sort -u))
unset IFS

for i in "${arr[@]}"
do
    # check for _docs folder
    docs_dir=$i/_docs

    if [[ -d "$docs_dir" ]]; then

        if ! test -f $docs_dir/README.md; then 
            echo "ERROR: _docs dir found with no README.md"; exit 1
        fi

        # generate the tf documentation
        echo "generating docs for: $i"
        ci/bin/terraform-docs.sh markdown $i > $docs_dir/TF_MODULE.md

        # merge the tf docs with the main readme
        pandoc --wrap=none -f gfm -t gfm $docs_dir/README.md -A $docs_dir/TF_MODULE.md > $i/README.md
        
        # Create a absolute link for terraform registry
        sed -i ".bak" -e "s|__GIT_REF__|${GIT_REF}|" $i/README.md
        rm -rf $i/README.md.bak

        # do some cleanup
        # because sed on macOS is special..
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/<!-- end list -->/d' $i/README.md  # quirk of pandoc
        else
            sed -i -e '/<!-- end list -->/d' $i/README.md  # quirk of pandoc
        fi

    elif [[ ! -d "$docs_dir" && $i != *".terraform"* ]]; then
        ci/bin/terraform-docs.sh markdown $i > README.md
    fi
done
