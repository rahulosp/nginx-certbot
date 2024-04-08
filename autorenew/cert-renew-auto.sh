#!/usr/bin/env bash

#Setting up environment variables for the Database
SUCCESS_STRING="Successfully received certificate"
DKR_CMPS_LOC="/opt/nginx-certbot"
LOG_FILE="/opt/nginx-certbot/autorenew/log-cert.txt"
CERT_RENEW_LOG_FILE="/opt/nginx-certbot/autorenew/certificate_renew_log_file"

#Get the present time
printf "\n\n\n\n######################################################################################################" >> ${LOG_FILE}
printf -v PRESENT_TIME '%(%Y-%m-%d-%H-%M-%S)T\n' -1 >> ${LOG_FILE}
printf "\nCertificate renew script ran at this_time\t ${PRESENT_TIME}" >> ${LOG_FILE}

#Get to compose directory
cd ${DKR_CMPS_LOC}
DKRSRVS=$(/usr/bin/docker compose config --services)
printf "\n Here are the docker services\n"
printf "\n%s" ${DKRSRVS}

for i in ${DKRSRVS};
do
  if [[ $i == *"certbot"* ]]; then
    printf "\nThis is a certbot service, will attempt renewal\n" >> ${LOG_FILE}
    printf "\nRemoving certbot container %s, if exists\n" $i >> ${LOG_FILE}
    sudo docker rm $i --force

    #Now run the certbot container
    printf "\nRecreating and Running the certbot container\n" $i >> ${LOG_FILE}
    sudo docker compose create $i
    sudo docker compose start $i
    sleep 30

    #Store the logs of certbot container into a variable
    if [[ $? == 0 ]];then
      docker logs $i > "${CERT_RENEW_LOG_FILE}"
      LOG_CERTB=$(grep "${SUCCESS_STRING}" "${CERT_RENEW_LOG_FILE}")

      if [[ "${LOG_CERTB}" == "${SUCCESS_STRING}" ]]; then
        echo -e "\nCertificates were successfully renewed at ${PRESENT_TIME}\n" >> ${LOG_FILE}
        printf "\nRestarting the nginx proxy\n" >> ${LOG_FILE}
        sudo docker compose restart nginx
      else
        echo -e "\nCertificates renewal failed with errors !!! at ${PRESENT_TIME}\n" >> ${LOG_FILE}
      fi
    fi
  fi
done

# Mark End of script
printf "######################################################################################################\n\n" >> ${LOG_FILE}


