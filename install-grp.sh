#!/bin/sh

appName=$1
nodes=$2
create=$3

rm -rf *.txt
rm -rf hosts.yml
cp hosts.yml.sample hosts.yml

export ANSIBLE_HOST_KEY_CHECKING=False
#KAfka

gcloud compute instance-groups unmanaged create bk-ms-kafka-$appName-group
gcloud compute instance-groups unmanaged create bk-ms-kafka-zk-$appName-group


if $create ; then
echo " Creating Kafka instances"
 for (( node=1; node<=nodes; node++ ))
  do
    gcloud compute instances create bk-ms-kafka-$appName-$node --source-instance-template ms-kafka-template-2 --tags=$appName
    gcloud compute instance-groups unmanaged add-instances bk-ms-kafka-$appName-group --instances bk-ms-kafka-$appName-$node
  done
fi  
 gcloud compute instances list |grep kafka-$appName |awk '{print $4":"}' >> kafkaIps.txt
#  
#ZK 
if $create ; then
echo " Creating ZK nodes"
 for (( node=1; node<=2; node++ ))
   do
     gcloud compute instances create bk-ms-kafka-zk-$appName-$node --source-instance-template  ms-kafka-zk-template --tags=$appName	
     gcloud compute instance-groups unmanaged add-instances bk-ms-kafka-zk-$appName-group --instances bk-ms-kafka-zk-$appName-$node
   done
 fi
 gcloud compute instances list |grep kafka-zk-$appName |awk '{print $4":"}' >> zkIps.txt

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