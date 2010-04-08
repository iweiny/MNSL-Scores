#!/bin/sh

dir=`dirname $0`

cd $dir
mysqldump -u root -p mnsl > mnsl2.sql
pushd ..
tar czf MNSL.tgz ./MNSL
popd

