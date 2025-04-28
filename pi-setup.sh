#/bin/bash

# Colors

CYAN="\e[36m"
YELLOW="\e[33m"
RED="\e[31m"
ENDCOLOR="\e[0m"


echo -e "${CYAN}  ___  _       ___                           _____          _        _ _            "
echo -e " / _ \\(_)     / _ \\                         |_   _|        | |      | | |           "
echo -e "/ /_\\ \\_ _ __/ /_\\ \\_      ____ _ _ __ ___    | | _ __  ___| |_ __ _| | | ___ _ __ "
echo -e "|  _  | | '__|  _  \\ \\ /\\ / / _\` | '__/ _ \\   | || '_ \\/ __| __/ _\` | | |/ _ \\ '__|"
echo -e "| | | | | |  | | | |\\ V  V / (_| | | |  __/  _| || | | \\__ \\ || (_| | | |  __/ |   "
echo -e "\\_| |_/_|_|  \\_| |_/ \\_/\\_/ \\__,_|_|  \\___|  \\___/_| |_|___/\\__\\__,_|_|_|\\___|_|${ENDCOLOR}   "
echo
echo -e "Welcome to the ${YELLOW}AirAware installer${ENDCOLOR}!"
echo "This utility will setup the Web server, MQTT broker and database for AirAware."
echo
echo -e "Note: the installer is specifically for the ${YELLOW}hio-raspbian-bookworm-lite image${ENDCOLOR}. Proceed with caution."
read -p "Type \`install\` if you want to start the installation process: " confirm
echo

if [[ "$confirm" == "install" ]] then

STEPS=7

echo 1/$STEPS: Updating system
sudo apt update 

echo 2/$STEPS: Installing php composer and necessary extensions

# Repo for php 8.4
sudo wget -qO /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
sudo apt update

# Install
sudo apt install -y php8.4-common php8.4-cli
sudo apt install php-xml -y
sudo apt install php-sqlite3 -y
sudo apt-get install composer -y
source ~/.bashrc

echo 3/$STEPS: Installing NodeJS
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 22

echo 4/$STEPS: Cloning AirAware application repository
git clone https://github.com/airaware-iot/dashboard.git ~/Airaware

echo 5/$STEPS: Setting up laravel web application
cd ~/Airaware
composer install
npm install
touch ./database/database.sqlite

cp .env.example .env # Generate .env file from template
php artisan key:generate
php artisan migrate --force
npm run build

echo 6/$STEPS: Configuring nodered
cd ~/.node-red

ESCAPED_NODERED_CODE='[
  {
    "id": "2c41a2bd.aa36ae",
    "type": "tab",
    "label": "Data storage flow"
  },
  {
    "id": "6c6622f5.06be2c",
    "type": "mqtt in",
    "z": "2c41a2bd.aa36ae",
    "name": "",
    "topic": "node/#",
    "qos": "2",
    "datatype": "base64",
    "broker": "29fba84a.b2af58",
    "nl": false,
    "rap": false,
    "inputs": 0,
    "x": 290,
    "y": 180,
    "wires": [
      [
        "ebe183de73bf666a"
      ]
    ]
  },
  {
    "id": "0791b386fd8b7092",
    "type": "http request",
    "z": "2c41a2bd.aa36ae",
    "name": "",
    "method": "POST",
    "ret": "txt",
    "paytoqs": "ignore",
    "url": "localhost:8001/api/v1/data",
    "tls": "",
    "persist": false,
    "proxy": "",
    "insecureHTTPParser": false,
    "authType": "",
    "senderr": false,
    "headers": [
      {
        "keyType": "other",
        "keyValue": "payload",
        "valueType": "msg",
        "valueValue": "payload"
      }
    ],
    "x": 690,
    "y": 180,
    "wires": [
      [
        "9d9c9e1aad241528"
      ]
    ]
  },
  {
    "id": "9d9c9e1aad241528",
    "type": "debug",
    "z": "2c41a2bd.aa36ae",
    "name": "debug 1",
    "active": true,
    "tosidebar": true,
    "console": false,
    "tostatus": false,
    "complete": "false",
    "statusVal": "",
    "statusType": "auto",
    "x": 900,
    "y": 180,
    "wires": []
  },
  {
    "id": "ebe183de73bf666a",
    "type": "function",
    "z": "2c41a2bd.aa36ae",
    "name": "MQTT to JSON",
    "func": "msg.payload = JSON.stringify({\n    topic: msg.topic,\n    value: msg.payload,\n});\n\nreturn msg;",
    "outputs": 1,
    "noerr": 0,
    "initialize": "",
    "finalize": "",
    "libs": [],
    "x": 480,
    "y": 180,
    "wires": [
      [
        "0791b386fd8b7092"
      ]
    ]
  },
  {
    "id": "29fba84a.b2af58",
    "type": "mqtt-broker",
    "name": "",
    "broker": "127.0.0.1",
    "port": "1883",
    "clientid": "",
    "autoConnect": true,
    "usetls": false,
    "protocolVersion": "4",
    "keepalive": "60",
    "cleansession": true,
    "birthTopic": "",
    "birthQos": "0",
    "birthPayload": "",
    "birthMsg": {},
    "closeTopic": "",
    "closePayload": "",
    "closeMsg": {},
    "willTopic": "",
    "willQos": "0",
    "willPayload": "",
    "willMsg": {},
    "sessionExpiry": ""
  }
]'


echo $ESCAPED_NODERED_CODE > flows.json 

echo 7/$STEPS: Launching server
sudo php artisan serve --host=0.0.0.0 --port=80


else
    echo "Stopping installer."
fi
