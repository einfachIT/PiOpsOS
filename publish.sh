#!/bin/bash

# You need to setup ~/.m2/settings.xml first
# <settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
#   xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
#   xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
#                       http://maven.apache.org/xsd/settings-1.0.0.xsd">
# 
#   <activeProfiles>
#     <activeProfile>github</activeProfile>
#   </activeProfiles>
# 
#   <profiles>
#     <profile>
#       <id>github</id>
#       <repositories>
#         <repository>
#           <id>github</id>
#           <name>GitHub OWNER Apache Maven Packages</name>
#           <url>https://maven.pkg.github.com/einfachit/</url>
#         </repository>
#       </repositories>
#     </profile>
#   </profiles>
# 
#   <servers>
#     <server>
#       <id>github</id>
#       <username>YOUR GITHUB USERNAME</username>
#       <password>YOUR GITHUB ACCESS KEY</password>
#     </server>
#   </servers>
# </settings>

mvn deploy:deploy-file -DgroupId=ch.einfachit -DartifactId=epicpios-64 -Dversion=0.9-beta -Dpackaging=zip -Dfile=epicPiOS_64.zip -Durl=https://maven.pkg.github.com/einfachIT/epicPiOS/ -DrepositoryId=github 

