#!/bin/bash
#set -x

setIpInHosts()
{
  # Discover Public IP for Running ec2 instances
  # Add new ec2 instances to local hosts file
  # If neccessary, amend existing host file entries

  export hostsFile=/etc/hosts
  
  aws ec2 describe-instances --filter "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[*].[PublicIpAddress, Tags[?Key=='Name'].Value|[0]]" --output text | while read IP HOST
  do
    export hostName=${HOST}
    export publicIP=${IP}
    hostExist=$(gawk -v host=${hostName} '($2==host) { print $2 }' ${hostsFile})

    if [ -z ${hostExist} ] 
    then
      echo -e "Discovered AWS EC2 Instance ${hostName} with Public IP ${publicIP}: Added to local hosts file."
      echo -e "${publicIP} ${hostName}" | sudo tee -a ${hostsFile} > /dev/null
    else  
      echo -e "Discovered AWS EC2 Instance ${hostName} with Public IP ${publicIP}: Amended existing local hosts file entry."
      echo -e "Discovered ${hostName} host key in known_hosts file: Deleting..."
      sudo -E ssh-keygen -qf ~/.ssh/known_hosts -R ${hostName} > /dev/null 2>&1
      sudo -E  perl -i.bak -plane 's/$F[0]/$ENV{publicIP}/ if $F[1] eq "$ENV{hostName}" ' ${hostsFile}
    fi  
  done
}

instanceStatus()
{
   aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId, Tags[?Key=='Name'].Value|[0], State.Name]" --o text
}

case $1 in
	ip) setIpInHosts ;;
	status) instanceStatus ;;
	stop) aws ec2 stop-instances --instance-ids $2 ;;
	start) aws ec2 start-instances --instance-ids $2 ;;
	terminate) aws ec2 terminate-instances --instance-ids $2 ;;
	*) ;;
esac
