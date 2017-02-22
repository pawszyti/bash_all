#!/bin/bash
tmp=tymczasowe.txt
tmp2=tymczasowe2.txt
tmp3=tymczasowe3.txt
ssh -n root@192.168.1.4 "wbinfo --user-groups=$1" >$tmp
exec 0< $tmp
while IFS= read id
do 
ssh -n root@192.168.1.4 "wbinfo -G $id" >$tmp2
id2=`cat $tmp2`
ssh -n root@192.168.1.4 "wbinfo -s $id2" >$tmp3
gr=`cat $tmp3 | cut -c4- | rev | cut -c3- | rev`
echo "usuwam grupe "$gr" dla uzytkownika "$1
ssh -n root@192.168.1.4 "samba-tool group removemembers '$gr' $1"
done