#!/bin/bash
directory="/usr/share/tomcat/webapps/ROOT/cloudman/xml"
rm -rf group.list
#attention, if use group*, then group.list3 will be deleted
rm -rf groupdir*
for file in ${directory}/*; do
if [[ $file == *".xml"* ]]
then
filename=`basename $file`
echo $filename | sed "s/.xml$//" >> group.list
fi
done

\cp group.list group.list2

groupnumber=1
for ip in `cat group.list2 | awk '{print $1}'`
do
#ip="10.8.8.22"
#groupnumber=2

neighbour=`egrep '([^0-9]|\<)(([0-1]?[0-9]{0,2}|([2]([0-4][0-9]|[5][0-5])))\.){3}([0-1]?[0-9]{0,2}|([2]([0-4][0-9]|[5][0-5])))([^0-9]|\>)' $directory/$ip.xml | sed "s/^<IP>//;s/<\/IP>$//" | sort | uniq`
echo $neighbour

#if group value not setted
for neigh in $neighbour
do
#echo "the 1st layer neighbour of $ip.xml: "$neigh

neighbour2=`egrep '([^0-9]|\<)(([0-1]?[0-9]{0,2}|([2]([0-4][0-9]|[5][0-5])))\.){3}([0-1]?[0-9]{0,2}|([2]([0-4][0-9]|[5][0-5])))([^0-9]|\>)' $directory/$neigh.xml | sed "s/^<IP>//;s/<\/IP>$//" | sort | uniq`
for neigh2 in $neighbour2
do
#echo "the 2nd layer neighbour of $neigh.xml: "$neigh2

neighbour3=`egrep '([^0-9]|\<)(([0-1]?[0-9]{0,2}|([2]([0-4][0-9]|[5][0-5])))\.){3}([0-1]?[0-9]{0,2}|([2]([0-4][0-9]|[5][0-5])))([^0-9]|\>)' $directory/$neigh2.xml | sed "s/^<IP>//;s/<\/IP>$//" | sort | uniq`
for neigh3 in $neighbour3
do
#echo "the 3rd layer neighbour of $neigh2.xml: "$neigh3

neighbour4=`egrep '([^0-9]|\<)(([0-1]?[0-9]{0,2}|([2]([0-4][0-9]|[5][0-5])))\.){3}([0-1]?[0-9]{0,2}|([2]([0-4][0-9]|[5][0-5])))([^0-9]|\>)' $directory/$neigh2.xml | sed "s/^<IP>//;s/<\/IP>$//" | sort | uniq`
for neigh4 in $neighbour4
do
#echo "the 4rd layer neighbour of $neigh3.xml: "$neigh4

flag=`cat group.list2 | awk '{if($1=="'$neigh4'") print $2}'`
#echo $flag
if [ "$flag" = "" ]
then
cat group.list2 | awk '{if ($1=="'$neigh4'") $(NF+1)="'$groupnumber'"; print $0}' > group.temp
\cp group.temp group.list2
fi
done
#break
done
#break
done
#break
done
#break
groupnumber=`expr $groupnumber + 1`
#echo $groupnumber
#break
done

#resign the group index
index=`cat group.list2 | awk '{print $2}' | sort -n | uniq`
echo $index
newindex=1
for i in $index
do
cat group.list2 | awk '{if($2=="'$i'") $(NF+1)="'$newindex'"; print $0}' > group.temp
\cp group.temp group.list2
newindex=`expr $newindex + 1`
done

#group.list3 is stable, prepared for other program to read
cat group.list2 | awk '{print $1,$3}' > group.temp
\cp group.temp group.list2
#cache group.list3 for generate-pm-json
\cp group.list2 group.list3


#create directory for each group, and copy file to these directory
i=1
groupnum=`cat group.list2 | awk '{print $2}' | sort -n | uniq | wc -l`
while [ $i -le $groupnum ]
do
mkdir groupdir$i
ip=`cat group.list2 | awk '{if ($2=="'$i'") print $1}'`
for j in $ip
do
\cp $directory/$j.xml groupdir$i/
done
#use new method: generate-json-from-xml2.sh
./generate-json-from-xml2.sh /usr/share/tomcat/webapps/ROOT/code/groupdir$i /usr/share/tomcat/webapps/ROOT/code/groupdir$i.json2
#java wholeGraph /usr/share/tomcat/webapps/ROOT/kj/xmltest/group$i/ /usr/share/tomcat/webapps/ROOT/kj/xmltest/group$i.json
#processid=`ps -ef|grep -E "wholeGraph"|grep -v grep|awk '{print $2}'`
#sleep 10
#kill -9 $processid
for j in $ip
do
\cp groupdir$i.json2 ../cloudman/json-vm2/$j.json
done
i=`expr $i + 1`
done

#####new added: merge all the vm groups in the same pm
directory="/usr/share/tomcat/webapps/ROOT/cloudman/json-pm"
rm -rf ../cloudman/json-group3/*
for file in ${directory}/*; do
if [[ $file == *".json"* ]]
then
#first: open a pmip.json
filename=`basename $file`
pmip=`echo $filename | sed "s/.json$//"`
#get all the vms in this pm
vmlist=`cat $file | grep "{\"name\"" | awk -F[:,\"] '{print $5}'`
echo $vmlist
#for each vm to find their related vms
echo "{\"links\":[" >> ../cloudman/json-group3/$filename
for i in $vmlist
do
cat ../cloudman/json-vm2/$i.json >> ../cloudman/json-group3/$filename
done
fi

cat ../cloudman/json-group3/$filename | sort | uniq > vmgroup.temp
lastline=`cat vmgroup.temp | tail -n1 |sed 's/\(.*\).$/\1/g'`
cat vmgroup.temp | sed '$d' > vmgroup.temp2
echo $lastline >> vmgroup.temp2
mv vmgroup.temp2 ../cloudman/json-group3/$filename
echo "]}" >> ../cloudman/json-group3/$filename

done
