systemctl stop firewalld.service
systemctl disable firewalld.service 
systemctl restart iptables.service 
systemctl enable iptables.service 

