#!/bin/bash

# creat OS zip for publishing
zip epicPiOS_64.zip boot.tar.xz root.tar.xz os.json partitions.json partition_setup.sh provision.service provision.sh blink_ip.sh blink_ip.service blink_ip.timer factory_reset.sh

# publish OS zip to gitHub packages maven repo
deploy:deploy-file   -DgroupId=ch.einfachIT   -DartifactId=epicpios_64 -Dversion=2020-08-24   -Dpackaging=zip   -Dfile=epicPiOs_64.zip   -Dregistry=https://maven.pkg.github.com/einfachIT -Durl=https://maven.pkg.github.com/orgs/einfachIT/ -Dtoken=${{secrets.GITHUB_TOKEN}}

