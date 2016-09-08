#!/usr/bin/env bash

CURRENT_DIR="$( pwd )"
SCRIPT_COMMAND_LOCATION="${BASH_SOURCE[0]}"

#determine if the script was run via a symlink
SYMLINK_DESTINATION=`readlink ${SCRIPT_COMMAND_LOCATION}`

if [[ -z $SYMLINK_DESTINATION ]]; then
	#not using symlink
	SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
else
	#using symlink
	SCRIPT_DIR="$( cd "$( dirname "${SYMLINK_DESTINATION}" )" && pwd )"
fi

RESOURCE_DIR="$SCRIPT_DIR/resources"
PROJECT_NAME="$1"
RED='\033[0;31m'
GREEN='\033[1;32m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

if [[ -z $PROJECT_NAME ]]; then
	echo -e "${RED}No project name specified${NC}"
	exit 1
fi

PROJECT_DIR="$CURRENT_DIR/$PROJECT_NAME"
WP_DIR="$PROJECT_DIR/wordpress"

# create the laravel project
echo -e "${ORANGE}Creating laravel project...${NC}"
laravel new "$PROJECT_NAME"
echo -e "${GREEN}Done.${NC}"
echo ""

cd "$PROJECT_NAME"

echo -e "${ORANGE}Installing wordpress...${NC}"
composer require "johnpbloch/wordpress":"*"
echo -e "${GREEN}Done.${NC}"
echo ""

echo -e "${ORANGE}Patching laravel index.php...${NC}"
cd "$PROJECT_DIR/public"
patch -u < "$RESOURCE_DIR/laravel.index.patch"
echo -e "${GREEN}Done.${NC}"
echo ""

cd "$PROJECT_DIR"

echo -e "${ORANGE}Creating wp-config.php with laravel mods...${NC}"
cp "$RESOURCE_DIR/wp-config-laravel.php" "$WP_DIR/wp-config.php"
echo -e "${GREEN}Done.${NC}"
echo ""

echo -e "${ORANGE}Copying wp-bootstrap-laravel.php...${NC}"
cp "$RESOURCE_DIR/wordpress.wp-bootstrap-laravel.php" "$WP_DIR/wp-bootstrap-laravel.php"
echo -e "${GREEN}Done.${NC}"
echo ""

echo -e "${ORANGE}Copying laravel based wordpress config file...${NC}"
cp "$RESOURCE_DIR/config.wordpress.php" "$PROJECT_DIR/config/wordpress.php"
echo -e "${GREEN}Done.${NC}"
echo ""

echo -e "${ORANGE}Copying Wordpress helper class to app/libraries...${NC}"
mkdir "$PROJECT_DIR/app/libraries/"
cp "$RESOURCE_DIR/app.libraries.Wordpress.php" "$PROJECT_DIR/app/libraries/Wordpress.php"
echo -e "${GREEN}Done.${NC}"
echo ""

echo -e "${GREEN}You now need to modify the server config to point the wordpress URLs to below the document root"
echo -e "an example config for apache is located at $RESOURCE_DIR/apache-additions.conf${NC}"