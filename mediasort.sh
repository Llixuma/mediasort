#!/bin/bash
# created 22.02.24
# updated 27.02.24 - rename variables and add comments
# By Llixuma
# rectal use only
# dont blame me if you break stuff with this thing
# this tool is provided as is and without any warranties or promises of making your situation any better
MFVERSION="2.24-beta"

# store args in global variables
DIRECTORY=$1 # Directory
OPTION=$2 # Option
SUB_OPTION=$3 # Suboption
OUTPUT_DIRECTORY=$4 # Output directory

cd $DIRECTORY > /dev/null
echo "Executing in $(pwd)"

INDEXFILE="$(pwd)/.index" 2>/dev/null # dont throw file not found error if it doesnt exist

ALBUMDEFINITION=10 # amount of files in a folder to consider it being an album

##
## in program fuctions
##

Album() # TODO, look for folders containing mostly one filetype, along the lines of 90% mp3 files and 10% album art
{
  ALBUMFILES=0 # number of files in a folder
  FILEEXTENSION="" # grab the file extension for calcualting percentage
  FOLDERS=$(awk -F '/' -v OFS='/' 'NF-=2' $INDEXFILE | sort | uniq | sort -h)
  FOLDERFILES=$(awk -F '/' -v OFS='/' 'NF-=2' $INDEXFILE | sort | uniq -c | sort -h | awk -F '/' '{print $1}')
  for i in $FOLDERS
  do
    echo $i
    echo
  done
}

##
## Option functions
##

ShowUsage()
{
  echo "USAGE: mediasort.sh [DIRECTORY] [OPTION] [SUBOPTION]"
  echo
  echo "OPTIONS:"
  echo "list - list occurences of the different file types"
  echo "list [FILETYPE] - List files with filetype/specific"
  echo "rebuild - Rebuild file index"
  echo
  echo "########### Danger zone! ###########"
  echo "move [FILETYPE] [LOCATION] - Move files of file type to a different folder"
  echo "DELETE [FILETYPE] - Delete all occurences of file type"
  echo
}

CreateIndex()
{
  rm $INDEXFILE 2>/dev/null
  touch $INDEXFILE
  echo "Rebuilding..."
  echo "This may create a LOT of disk cache"
  echo "use 'echo 3 | sudo tee /proc/sys/vm/drop_caches' to free up the cache again"
  trap "echo ;echo Terminated, deleting unfinished index...; rm $INDEXFILE; exit 1" INT
  for i in $(ls)
  do
    find $(pwd)/$i -type f -exec file --mime-type {} \+ >> $INDEXFILE
  done
  echo done
}

List()
{
  if echo $FILETYPES | grep -q "$SUB_OPTION" && [ "$SUB_OPTION" != "" ]
  then
    grep "$SUB_OPTION" $INDEXFILE | more
    exit 0
  elif [ "$SUB_OPTION" == "" ]
  then
    awk -F ' ' '{print $NF}' $INDEXFILE | sort | uniq -c | sort -h | more
  else
    echo "couldn't find $SUB_OPTION"
  fi
}

Move()
{
  if echo $FILETYPES | grep -q "$SUB_OPTION" && [ "$SUB_OPTION" != "" ]
  then
    grep "$SUB_OPTION" $INDEXFILE
  else
    echo "this its temporary"
    exit 1
  fi
}

Delete()
{
  TOBEDELETED=$(grep "$SUB_OPTION" $INDEXFILE | awk -F':' '{print $1}')
  if echo $FILETYPES | grep -q "$SUB_OPTION" && [[ "$SUB_OPTION" != "" ]] && [[ "$TOBEDELETED" != "" ]]
  then
    echo "THIS WILL REMOVE EVERY FILE IN THE LIST BELOW"
    echo
    grep "$SUB_OPTION" $INDEXFILE | awk -F':' '{print $1}'
    echo
    echo
    echo "if you are absolutely sure you want to remove these files, type:"
    echo "                        "YES I AM SURE"                         "
    echo
    read FUCKMYSHITUP
    if [[ $FUCKMYSHITUP = "YES I AM SURE" ]]
    then
      for delete in $TOBEDELETED
      do
        echo deleting $delete
        rm $delete
      done
      echo done
      CreateIndex # rebuild index because i still need to find a way to edit out the deleted files from the existing index
    else
      echo "Exiting"
    fi
  else
    echo "No files to remove"
    echo
  fi
}

##
## main part
##

echo mediafind.sh by Llixuma
echo "Version $MFVERSION"

if [ -f $INDEXFILE ]; then
  echo
else
  echo No file index found
  CreateIndex
fi
echo

FILETYPES=$(awk -F ' ' '{print $NF}' $INDEXFILE | sort | uniq)


case $OPTION in
  list) List ;;
  rebuild) CreateIndex ;;
  move) Move ;;
  DELETE) Delete ;;
  album) Album ;;
  *) ShowUsage ;;
esac

