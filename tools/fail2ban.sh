#!/bin/bash
 
touch /root/satools/
cat /var/log/auth.log|awk '/Failed/{print $(NF-3)}'|sort|uniq -c|awk '{print $2"="$1;}'>/root/satools/black.txt
 
DEFINE="10"
 
for i in `cat /root/satools/black.txt`
do
        IP=`echo $i|awk -F= '{print $1}'`
        NUM=`echo $i|awk -F= '{print $2}'`

        if [ $NUM -gt $DEFINE ]:
        then
                grep $IP /etc/hosts.deny>/dev/null

                if [ $? -gt 0 ]:
                then
                echo "sshd:$IP">>/etc/hosts.deny
                fi
        fi
done
