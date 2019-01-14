#!/bin/bash

###
#
# Install and configure postfix with gmail relay
# - ytanguy, 2018-06-14
#
# https://www.howtoforge.com/tutorial/configure-postfix-to-use-gmail-as-a-mail-relay/
#
###

printf '1/ Install postfix mailutils libsasl2-modules\n'
printf '\nNOTE : When prompted for "General type of mail configuration," choose Internet Site.\n'
sleep 5
apt-get update && apt-get install -y postfix mailutils libsasl2-modules

printf '2/ Configure username and password\n'
read -p ' - Please provide gmail account (ex: margaret.hamilton@gmail.com) : ' username
if ! $(echo "$username" | grep -q '@gmail.com'); then
    printf 'ERROR - You must provide a full account (ex: margaret.hamilton@gmail.com)\n'
    exit 2
fi
read -s -p ' - Please provide associated password : ' password
printf '\n'
echo -e "[smtp.gmail.com]:587\t$username:$password" > /etc/postfix/sasl_passwd
chmod 600 /etc/postfix/sasl_passwd

printf '3/ Process password file\n'
postmap /etc/postfix/sasl_passwd

printf '4/ Set postfix configuration\n'
cat <<EOF >> /etc/postfix/main.cf

### Set by postfixgmail-install.sh ###
relayhost = [smtp.gmail.com]:587
smtp_use_tls = yes
smtp_sasl_auth_enable = yes
smtp_sasl_security_options =
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
EOF

printf '5/ Restart postfix\n'
systemctl restart postfix.service

printf '6/ Send test email\n'
echo 'Grettings from postfixgmail-install.sh' | mail -s 'Test email' "$username"

printf '\nAll done\n'
