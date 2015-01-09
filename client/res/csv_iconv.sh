#!/bin/bash   
dir=. 

for file in `find $dir -name "*.csv"`; do   
	echo "`file $file`"
	encode=`file $file | grep Unicode*`
	if [ -z "$encode" ]; then
		iconv -f gbk -t utf8 $file > $file.tmp
		mv $file.tmp $file
	fi
done  
