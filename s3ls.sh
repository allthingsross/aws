#!/bin/bash

aws s3 ls | awk '{ print $NF }' | while read BUCKET
do 
  aws s3 ls  --recursive s3://${BUCKET} | gawk -v bucket=${BUCKET} '{ print $1,$2,$3,"s3://"bucket"/"$NF }'
  echo -e ""
done
