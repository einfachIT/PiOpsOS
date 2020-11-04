zip raspios_arm64.zip boot.tar.xz root.tar.xz os.json partitions.json partition_setup.sh

deploy:deploy-file   -DgroupId=ch.einfachIT   -DartifactId=raspios_arm64   -Dversion=2020-08-24   -Dpackaging=zip   -Dfile=raspios_arm64.zip   -Dregistry=https://maven.pkg.github.com/einfachIT -Durl=https://maven.pkg.github.com/orgs/einfachIT/packages -Dtoken=${{secrets.GITHUB_TOKEN}}

