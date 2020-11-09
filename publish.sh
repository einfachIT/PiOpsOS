#!/bin/bash

# publish OS zip to gitHub packages maven repo
deploy:deploy-file   -DgroupId=ch.einfachIT   -DartifactId=epicpios_64 -Dversion=2020-08-24   -Dpackaging=zip   -Dfile=epicPiOs_64.zip   -Dregistry=https://maven.pkg.github.com/einfachIT -Durl=https://maven.pkg.github.com/orgs/einfachIT/ -Dtoken=${{secrets.GITHUB_TOKEN}}

