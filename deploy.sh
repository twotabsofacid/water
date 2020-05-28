#!/bin/sh
#
# Deploy to water.twotabsofacid.com with build
#
# To deploy:
# > ./deploy.sh

yarn build
sed -i "" 's/\/dist\/main.js/main.js/g' out/index.html

# Get the sshPath from the .env file
sshPath=$(grep sshPath .env | cut -d '=' -f2)
folderPath=$(grep folderPath .env | cut -d '=' -f2)

# Delete existing content on ssri.network
echo "Starting deletion of existing files/folders"
ssh $sshPath "rm -rf $folderPath*"

# Upload the new content to the server
echo "Starting deploy of newly built website"
scp -r out/* $sshPath:$folderPath
