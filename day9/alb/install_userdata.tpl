#!/bin/bash
#yum -y install httpd
#echo "hello from terraform" >> /var/www/html/index.html
#service httpd restart

#add user and update sudo
sudo useradd -m -d /home/ec2-user -s /bin/bash -c "ec2-user Owner" -U ec2-user; (echo redhat; echo redhat) | sudo passwd ec2-user
echo 'ec2-user   ALL=(ALL)       NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
service sshd restart
sleep 3m;  stress --cpu 1 --timeout 300
