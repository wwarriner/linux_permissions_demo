#!/bin/bash

set -u

ROOT_=$(pwd)


namedir() {
  echo "d$1"
}

prepdir() {
  # takes in a permission triple like `r-x`
  # creates a directory with those user permissions and no others
  local DIR="$ROOT_/d$1"
  mkdir "$DIR"

  touch "$DIR/file"
  chmod "u=rwx,g-rwx,o-rwx" "$DIR/file"

  local nodash="${1//-/}"
  chmod "u=$nodash,g-rwx,o-rwx" "$DIR"
  echo "$DIR"
}

prepfile() {
  # takes in a permission triple like `r-x`
  # creates a file with those user permissions and no others
  # file has its permission triple as a constant
  local FILE="$ROOT_/f$1"
  touch "$FILE"

  local nodash="${1//-/}"
  chmod "u=$nodash,g-rwx,o-rwx" "$FILE"
  echo "$FILE"
}

wlog() {
  # 1 - command
  # 2 - type
  # 3 - dir permissions
  # 4 - file permissions
  # 5 - redirect stream
  echo "$1","$2","$3","$4","$?" >> $5
}

cleardir() {
  chmod -R u=rwx $1 || true
  rm -rf $1
}

clearfile() {
  chmod -R u=rwx $1 || true
  rm -f $1
}

clean() {
  chmod -R u=rwx d???
  rm -r d???

  chmod -R u=rwx d???cp
  rm -r d???cp

  chmod -R u=rwx d???mv
  rm -r d???mv

  chmod -R u=rwx f???
  rm -r f???

  chmod -R u=rwx f???cp
  rm -r f???cp

  chmod -R u=rwx f???mv
  rm -r f???mv
}

APPEND="append redirect (>>)"
CAT="cat"
CD="cd"
CLOBBER="clobber redirect (>)"
CP="cp"
CP_R="cp -r"
CP_INTO="cp file into dir"
EXECUTE="execute"
FIND="find"
LS="ls"
LS_L="ls -l"
MV="mv"
MV_INTO="mv file into dir"
RM="rm"
RM_F="rm -f"
RM_R="rm -r"
RM_RF="rm -rf"

DIR="d/"
DIRFILE="f"
FILE="f"

permissions=(--- --x -w- -wx r-- r-x rw- rwx)

log=$ROOT_/results.csv
rm $log
touch $log

comlog=$ROOT_/commands.log
rm $comlog
touch $comlog

echo "starting dirs"
for p in "${permissions[@]}"; do
  dir=$(prepdir $p)

  # dir operations
  ls $dir >> $comlog 2>&1
  wlog "$LS" $DIR $p "" $log

  ls -l $dir >> $comlog 2>&1
  wlog "$LS_L" $DIR $p "" $log

  find $dir >> $comlog 2>&1
  wlog "$FIND" $DIR $p "" $log

  cd $dir >> $comlog 2>&1
  wlog "$CD" $DIR $p "" $log
  cd $ROOT_ >> /dev/null 2>&1

  cp -r $dir/ ${dir}cp >> $comlog 2>&1
  wlog "$CP_R" $DIR $p "" $log
  rm -rf ${dir}cp >> /dev/null 2>&1

  mv $dir ${dir}mv >> $comlog 2>&1
  wlog "$MV" $DIR $p "" $log
  mv ${dir}mv $dir/ >> /dev/null 2>&1

  file=$dir/file

  # into dir operations
  touch file__in
  cp file__in ${file}__ >> $comlog 2>&1
  wlog "$CP_INTO" $DIR $p "" $log
  rm file__in >> /dev/null 2>&1
  rm ${file}__ >> /dev/null 2>&1

  touch file__in
  mv file__in ${file}__ >> $comlog 2>&1
  wlog "$MV_INTO" $DIR $p "" $log
  rm file__in >> /dev/null 2>&1
  rm ${file}__ >> /dev/null 2>&1

  # rwx file in dir operations
  ls $file >> $comlog 2>&1
  wlog "$LS" $DIRFILE $p rwx $log

  ls -l $file >> $comlog 2>&1
  wlog "$LS_L" $DIRFILE $p rwx $log

  find $file >> $comlog 2>&1
  wlog "$FIND" $DIRFILE $p rwx $log

  cat $file >> $comlog 2>&1
  wlog "$CAT" $DIRFILE $p rwx $log

  { echo "new" 1>> $file; } 2>> $comlog
  wlog "$APPEND" $DIRFILE $p rwx $log

  { echo "new" 1> $file; } 2>> $comlog
  wlog "$CLOBBER" $DIRFILE $p rwx $log

  { echo "" 1> $file; } 2>> $comlog
  $file >> $comlog 2>&1
  wlog "$EXECUTE" $DIRFILE $p rwx $log

  cp $file file__out >> $comlog 2>&1
  wlog "$CP" $DIRFILE $p rwx $log
  rm file__out >> /dev/null 2>&1

  mv $file file__out >> $comlog 2>&1
  wlog "$MV" $DIRFILE $p rwx $log
  rm file__out >> /dev/null 2>&1

  # clean up
  cleardir $dir
done

echo "starting dir only cp"
for p in "${permissions[@]}"; do
  dir=$(prepdir $p)
  file=$dir/file

  rm -f $file >> /dev/null 2>&1
  cp $dir >> $comlog 2>&1
  wlog "$CP" $DIR $p "" $log

  # clean up
  cleardir $dir
done

echo "starting dirfile rm"
for p in "${permissions[@]}"; do
  dir=$(prepdir $p)
  file=$dir/file

  yes | rm $file >> $comlog 2>&1
  wlog "$RM" $DIRFILE $p rwx $log

  cleardir $dir
done

echo "starting dirfile rm -f"
for p in "${permissions[@]}"; do
  dir=$(prepdir $p)
  file=$dir/file

  rm -f $file >> $comlog 2>&1
  wlog "$RM_F" $DIRFILE $p rwx $log

  cleardir $dir
done

echo "starting dir rm -f"
for p in "${permissions[@]}"; do
  dir=$(prepdir $p)
  file=$dir/file
  rm -f $file >> /dev/null 2>&1

  rm -rf $dir >> $comlog 2>&1
  wlog "$RM_F" $DIR $p "" $log

  cleardir $dir
done

echo "starting dir rm -r"
for p in "${permissions[@]}"; do
  dir=$(prepdir $p)

  yes | rm -r $dir >> $comlog 2>&1
  wlog "$RM_R" $DIR $p "" $log

  cleardir $dir
done

echo "starting dir rm -rf"
for p in "${permissions[@]}"; do
  dir=$(prepdir $p)

  rm -rf $dir >> $comlog 2>&1
  wlog "$RM_RF" $DIR $p "" $log

  cleardir $dir
done

echo "starting files"
for p in "${permissions[@]}"; do
  # skip rwx/rwx
  if [ $p = "rwx" ]; then
    continue
  fi

  file=$(prepfile $p)

  ls $file >> $comlog 2>&1
  wlog "$LS" $FILE rwx $p $log

  ls -l $file >> $comlog 2>&1
  wlog "$LS_L" $FILE rwx $p $log

  find $file >> $comlog 2>&1
  wlog "$FIND" $FILE rwx $p $log

  cat $file >> $comlog 2>&1
  wlog "$CAT" $FILE rwx $p $log

  { echo "new" 1>> $file; } 2>> $comlog
  wlog "$APPEND" $FILE rwx $p $log

  { echo "new" 1> $file; } 2>> $comlog
  wlog "$CLOBBER" $FILE rwx $p $log

  cp $file filecp >> $comlog 2>&1
  wlog "$CP" $FILE rwx $p $log
  rm -f filecp >> /dev/null 2>&1

  mv $file filemv >> $comlog 2>&1
  wlog "$MV" $FILE rwx $p $log
  mv filemv $file >> /dev/null 2>&1

  { echo "" 1> $file; } 2>> /dev/null
  { $file >> $comlog; } >> $comlog 2>&1
  wlog "$EXECUTE" $FILE rwx $p $log

  clearfile $file
done

echo "starting files rm"
for p in "${permissions[@]}"; do
  # skip rwx/rwx
  if [ $p = "rwx" ]; then
    continue
  fi
  file=$(prepfile $p)

  yes | rm $file >> $comlog 2>&1
  wlog "$RM" $FILE rwx $p $log

  clearfile $file
done

echo "starting files rm -f"
for p in "${permissions[@]}"; do
  # skip rwx/rwx
  if [ $p = "rwx" ]; then
    continue
  fi
  file=$(prepfile $p)

  rm -f $file >> $comlog 2>&1
  wlog "$RM_F" $FILE rwx $p $log

  clearfile $file
done

clean
