#!/bin/bash
#
# This file specifies external files/folders from github locations
#  which are used in this distribution and should be updated
#  as necessary to incorporate into the hardware definition.
#
# The repos mentioned are checked out into 
#     {dirpath_to_makedist.sh}/.sources.tmp/REPO_NAME
#  and you can edit in there if you want while developing.
# 

function main
{
  # Ensure we have certain directories
  [ -d cores ]    || mkdir cores
  [ -d variants ] || mkdir variants
  
  # github https://github.com/damellis/attiny/tree/master/attiny/variants/tiny8    variants/tiny8
  # github https://github.com/damellis/attiny/tree/master/attiny/variants/tiny14   variants/tiny14
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/cores/tiny           cores/tiny
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/variants/tinyX5      variants/tinyX5
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/variants/tinyX4_Arduino_Numbering      variants/tinyX4
  #github https://github.com/sleemanj/ATTinyCore/tree/master/avr/variants/tinyX4      variants/tinyX4
  
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/variants/tiny13      variants/tiny13
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/variants/tiny5_10    variants/tiny5_10
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/variants/tiny4_9     variants/tiny4_9
  
  # Libraries, these include examples for ATTinyCore chips
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/libraries      libraries
  
  # We need to grab most of the platform.txt information from the ATTinyCore 
  #  except we want to use our own avrdude stuff
  github https://github.com/sleemanj/ATTinyCore/tree/master/avr/platform.txt         platform.tmp.txt  
  echo "
  
###############################################################################
#
# This platform.txt has been created from the combination of 
#  https://github.com/sleemanj/ATTinyCore/tree/master/avr/platform.txt
# and the platform.local.txt in this folder
#
# This file is created automatically by \`sources.sh\` when the diy_attiny
# distribution is updated with \`makdedist.sh\`
#
###############################################################################

name=DIY ATtiny
version=${VERSION}
" >platform.txt 
  cat platform.tmp.txt | grep -v "name=" | grep -v "version=" | grep -v tools.avrdude >>platform.txt
  rm platform.tmp.txt      
  cat platform.local.txt >>platform.txt
  
  
  # Because of:
  #   https://github.com/arduino/Arduino/issues/4619
  # it is best that we duplicate programmers.txt and make a unique name for each one in it    
  if grep -F "#define" avrdude.local.conf >/dev/null
  then  
    cp avrdude.local.conf avrdude.conf
    wget https://raw.githubusercontent.com/arduino/Arduino/master/hardware/arduino/avr/programmers.txt -O programmers.tmp.txt
    cat programmers.tmp.txt | sed -r 's/\.name=(.*)/.name=DIY ATtiny: \1/' >programmers.txt  
    rm programmers.tmp.txt
  else
    # Not using a custom avrdude.conf
    rm -f avrdude.conf programmers.txt
    cp programmers.local.txt programmers.txt
    
    # Out platform.txt will also need modification to set the avrdude.conf back to the builtin
    cat platform.txt | sed -r 's/\{runtime.platform.path\}\/avrdude.conf/{path}\/avrdude.conf/' >platform.tmp.txt
    mv platform.tmp.txt platform.txt
  fi
  
}

function github
{
  local TMP_DIR=$(dirname $(realpath $0))/../../../.sources.tmp/  
  local OUT_DIR=$(dirname $(realpath $0))
  if [ ! -d $TMP_DIR ]
  then
    mkdir $TMP_DIR || exit 1
  fi
  
  local GIT="$(echo $1 | sed 's/\/tree.*/.git/')"
  local GITNAME="$(echo $GIT | sed 's/.*\///' | sed 's/\.git//' )"
  local BRANCH="$(echo $1 | sed 's/.*tree\///' | sed 's/\/.*//')"
  local FILES="$(echo $1 | sed "s/..*\/tree\/$BRANCH\///")"
  pushd $TMP_DIR
    if [ ! -d $GITNAME ]
    then
      git clone $GIT      
    fi
    pushd $GITNAME
      git checkout $BRANCH      
    popd
    rm -rf $OUT_DIR/$2
    cp -rP $GITNAME/$FILES $OUT_DIR/$2
  popd
}

main "$@"