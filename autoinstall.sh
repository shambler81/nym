#!/bin/bash
echo -e "\033[0;35m" 
echo "===============================================================";
echo ".__   __.   ______    _______   __    _______ ____    ____     ";
echo "|  \ |  |  /  __  \  |       \ |  |  /  _____|\   \  /   /     ";
echo "|   \|  | |  |  |  | |  .--.  ||  | |  |  __   \   \/   /      ";
echo "|  . \`  | |  |  |  | |  |  |  ||  | |  | |_ |   \_    _/       ";
echo "|  |\   | |  \`--'  | |  '--'  ||  | |  |__| |     |  |         ";
echo "|__| \__|  \______/  |_______/ |__|  \______|     |__|         ";
echo "";
echo "===============================================================";
echo -e "\e[0m"                                                    
sleep 2

echo "export FORTA_PASSPHRASE=flaring-debtless-bride-recollect-shame-stillness-badass-backfire-crinkly-slather" >> ~/.bash_profile # <YOUR_PASSPHRASE> заменить ваш пароль
echo "export FORTA_OWNER_ADDRESS=0x7E5bFB5325aBA3Fc6719DB4ae091f148B5f6f39b" >> ~/.bash_profile # <YOUR_FORTA_OWNER_ADDRESS> заменить на адрес владельца ноды (пункт 1)
echo "export FORTA_RPC_URL=https://eth-mainnet.alchemyapi.io/v2/WnhlZ3dZf3fsGbZU70_6tjsM5VM6cXlH" >> ~/.bash_profile # <YOUR_FORTA_RPC_URL> заменить на ссылку полученную в пункте 5
echo "export REPLY=1" >> ~/.bash_profile 
echo "export FORTA_DIR=~/.forta" >> ~/.bash_profile
source ~/.bash_profile









# echo -e "\e[1m\e[32m1. Enter Forta passphrase(passwrod) \e[0m"
# read -p "Forta Passphrase: " FORTA_PASSPHRASE

# echo -e "\e[1m\e[32m2. Enter owner address(any metamask address that you have access to) \e[0m"
# read -p "Forta Owner Address: " FORTA_OWNER_ADDRESS

# echo -e "\e[1m\e[32m3. Select desired chain id. Chain id must match your RPC chain URL!!! \e[0m"
# PS3='Please enter your choice: '
# options=(
#     "1 - ETH" 
#     "56 - BSC" 
#     "137 - Polygon" 
#     "43114 - Avalanche" 
#     "42161 - Arbitrum" 
#     "10 - Optimism")
# select opt in "${options[@]}"
# do
#   case "$REPLY" in
#     1|2|3|4|5|6)
#       echo "Greath Choice!"
#       break
#       ;;
#     *) 
#       echo "Invalid option $REPLY"
#       ;;
#   esac
# done

# echo -e "\e[1m\e[32m4. Enter RPC url \e[0m"
# read -p "Enter RPC url: " FORTA_RPC_URL

echo "=================================================="

echo -e "\e[1m\e[32m Forta Passphrase: \e[0m" $FORTA_PASSPHRASE
echo -e "\e[1m\e[32m Forta Owner Address:  \e[0m" $FORTA_OWNER_ADDRESS
echo -e "\e[1m\e[32m RPC url:  \e[0m" $FORTA_RPC_URL
echo -e "\e[1m\e[32m Forta Chain Id:  \e[0m" $REPLY

while true; do
    read -p "Please make sure that is everything is correct [Y/n]? " rmv
    rmv=${rmv,,}                                 # lower the letters in the rmv variable
    case $rmv in
        [y]* ) echo "YES"; break;;
        #[] ) echo "Enter Key"; break;;
        [n]* ) echo "NO"; exit;;
        * ) echo "Please answer yes or no! ";;   # repeat until valid answer
    esac
done

echo -e "\e[1m\e[32m5. Updating list of dependencies... \e[0m" && sleep 1
sudo apt-get update
cd $HOME

echo "=================================================="

echo -e "\e[1m\e[32m6. Verifying Docker version... \e[0m" && sleep 1

if [[ $(docker version -f "{{.Server.Version}}") != "20.10."* ]]; then
    echo -e "\e[1m\e[32m6.2 Updating/Installing Docker... \e[0m" && sleep 1
    sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
    sudo apt-cache policy docker-ce
    sudo apt install docker-ce -y
fi

echo "=================================================="

echo -e "\e[1m\e[32m7. Check if Docker service is active... \e[0m" && sleep 1

if [[ $(systemctl is-active docker) != "active" ]]; then
    echo -e "\e[91m Docker service is not active, please make sure that Docker is working properly and try again later. \e[0m" && sleep 1
    exit
fi

echo "=================================================="

echo -e "\e[1m\e[32m8. Install forta node... \e[0m" && sleep 1
sudo curl https://dist.forta.network/pgp.public -o /usr/share/keyrings/forta-keyring.asc -s
echo 'deb [signed-by=/usr/share/keyrings/forta-keyring.asc] https://dist.forta.network/repositories/apt stable main' | sudo tee -a /etc/apt/sources.list.d/forta.list
sudo apt-get update
sudo apt-get install forta

echo "=================================================="

echo -e "\e[1m\e[32m9. Configure forta node... \e[0m" && sleep 1
echo '{
   "default-address-pools": [
        {
            "base":"172.17.0.0/12",
            "size":16
        },
        {
            "base":"192.168.0.0/16",
            "size":20
        },
        {
            "base":"10.99.0.0/16",
            "size":24
        }
    ]
}' > /etc/docker/daemon.json
sudo systemctl restart docker
if [[ $(systemctl is-active docker) != "active" ]]; then
    echo -e "\e[91m Docker service is not active, please make sure that Docker is working properly and try again later. \e[0m" && sleep 1
    exit
fi
sudo mkdir -p /lib/systemd/system/forta.service.d

echo "[Service]
Environment='FORTA_DIR=$HOME/.forta'
Environment='FORTA_PASSPHRASE=$FORTA_PASSPHRASE'" > /lib/systemd/system/forta.service.d/env.conf

FORTA_SCANNER_ADDRESS=$(forta init --passphrase $FORTA_PASSPHRASE | awk '/Scanner address: /{print $3}') && sleep 2
if [ -z "$FORTA_SCANNER_ADDRESS" ]; then
    echo -e "\e[91m Wasn't able execute forta init, possible reason is that fora was already initiated before. \e[0m" && sleep 1
    exit
fi

sed -i 's,<required>,'$FORTA_RPC_URL',g' $HOME/.forta/config.yml
sed -i 's/chainId: .*/chainId: '$REPLY'/g' $HOME/.forta/config.yml

echo "=================================================="

echo -e "\e[1m\e[32m10. Register Forta scan node... \e[0m \n" && sleep 1
for (( ;; )); do
    if forta register --owner-address $FORTA_OWNER_ADDRESS --passphrase $FORTA_PASSPHRASE ; then
        echo "$FORTA_SCANNER_ADDRESS has insufficient funds. This action requires Polygon (Mainnet). Fund your wallet $FORTA_SCANNER_ADDRESS with some Matic(at least 0.1 MATIC)"
    else
        break   
    fi
    for (( timer=15; timer>0; timer-- ))
        do
            printf "* Sleep for \033[0;31m%!d(MISSING)\033[0m sec\r" $timer
            sleep 1
        done
done

echo "=================================================="

echo -e "\e[1m\e[32m11. Starting Forta service... \e[0m" && sleep 1
sudo systemctl enable forta
sudo systemctl start forta

echo "=================================================="

echo -e "\e[1m\e[32mForta Node Started \e[0m"

echo "=================================================="


echo -e "\e[1m\e[32mTo check status: \e[0m" 
echo -e "\e[1m\e[39mforta status \n \e[0m"

echo -e "\e[1m\e[32mYour scanner address: \e[0m" 
echo -e "\e[1m\e[39m$FORTA_SCANNER_ADDRESS \n \e[0m"

echo -e "\e[1m\e[32mYour owner address: \e[0m" 
echo -e "\e[1m\e[39m$FORTA_OWNER_ADDRESS \n \e[0m" 

echo -e "\e[1m\e[32mYour passphrase: \e[0m" 
echo -e "\e[1m\e[39m$FORTA_PASSPHRASE \n \e[0m" 