#!/bin/bash

# script to auto-generate terraform documentation

pandoc -v &> /dev/null || echo "ERROR: Pandoc not installed"
terraform-docs --version &> /dev/null || echo "ERROR: terraform-docs not installed"

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
        terraform-docs markdown table $i > $docs_dir/TF_MODULE.md

        # merge the tf docs with the main readme
        pandoc --wrap=none -f gfm -t gfm $docs_dir/README.md -A $docs_dir/TF_MODULE.md > $i/README.md

        # do some cleanup
        # because sed on macOS is special..
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/<!-- end list -->/d' $i/README.md  # quirk of pandoc
        else
            sed -i -e '/<!-- end list -->/d' $i/README.md  # quirk of pandoc
        fi

    elif [[ ! -d "$docs_dir" && $i != *".terraform"* ]]; then
        terraform-docs markdown table $i > README.md
    fi
done