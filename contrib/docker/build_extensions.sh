#!/bin/bash
echo "Looking for local extensions to install..."
echo "Extension dir contents new:"

ls -la $CKAN_EXTENSIONS
echo "Activate Virtual ENV"
source "${CKAN_VENV}/bin/activate"

for i in $CKAN_EXTENSIONS/*
do
    if [ -d $i ];
    then

        if [ -f $i/pip-requirements.txt ];
        then
            ckan-pip install -r $i/pip-requirements.txt
            echo "Found requirements file in $i"
        fi
        if [ -f $i/requirements.txt ];
        then
            ckan-pip install -r $i/requirements.txt
            echo "Found requirements file in $i"
        fi
        if [ -f $i/dev-requirements.txt ];
        then
            ckan-pip install -r $i/dev-requirements.txt
            echo "Found dev-requirements file in $i"
        fi
        if [ -f $i/setup.py ];
        then
            cd $i
            python $i/setup.py develop
            echo "Found setup.py file in $i"
            cd $APP_DIR
        fi

        # Point `use` in test.ini to location of `test-core.ini`
        #if [ -f $i/test.ini ];
        #then
        #    echo "Updating \`test.ini\` reference to \`test-core.ini\` for plugin $i"
        #    ckan config-tool $i/test.ini "use = config:/usr/lib/ckan/test-core.ini"
        #fi
    fi
done