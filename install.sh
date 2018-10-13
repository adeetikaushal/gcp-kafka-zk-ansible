#!/bin/sh

appName=$1
nodes=$2
create=$3

rm -rf *.txt
rm -rf hosts.yml
cp hosts.yml.sample hosts.yml

export ANSIBLE_HOST_KEY_CHECKING=False
#KAfka
if $create ; then
echo " Creating Kafka instances"
 for (( node=1; node<=nodes; node++ ))
  do
    gcloud compute instances create bk-ms-kafka-$appName-kafka-$node --source-instance-template ms-kafka-template-1 --tags=$appName
  done
fi  
 gcloud compute instances list |grep $appName-kafka |awk '{print $4":"}' >> kafkaIps.txt
#  
#ZK 
if $create ; then
echo " Creating ZK nodes"
 for (( node=1; node<=3; node++ ))
   do
     gcloud compute instances create bk-ms-kafka-$appName-zk-$node --source-instance-template ms-zk-centos7-images --tags=$appName	
   done
 fi
 gcloud compute instances list |grep $appName-zk |awk '{print $4":"}' >> zkIps.txt

echo "Updating the host file"
#get connect IP

echo "Updating zk"
sed -i '' '/#zkIps/ {r zkIps.txt
d;};' hosts.yml

echo "Updating kafka"
sed -i '' '/#kafkaIps/ {r kafkaIps.txt
d;};' hosts.yml

sed -i '' 's/.$//' kafkaIps.txt

echo "Updating connect"
sed -i -e 's/$/2181/g' zkIps.txt 
tr '\n' ',' < zkIps.txt > connect.txt

#dynamic create host file

sed -i '' 's/10./    10./g'  hosts.yml

#broker yml
i=1
while IFS='' read -r line || [[ -n "$line" ]]; do
    echo "    $line:" >> kafkahosts.txt
    echo "       kafka:" >> kafkahosts.txt
    echo "         broker:" >> kafkahosts.txt
    echo "           id: $i" >> kafkahosts.txt
    echo "           connect: `cat connect.txt`" >> kafkahosts.txt
    echo "           host: $line" >> kafkahosts.txt
 ((i++))  
done < "kafkaIps.txt"

sed -i '' '/kafkahosts/ {r kafkahosts.txt
d;};' hosts.yml


echo "Running ansible"

ansible-playbook -i hosts.yml all.yml