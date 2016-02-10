Locations="Function ServiceDelivery"

CurrentVersion=$(grep "<version>.*SNAPSHOT</version>" Function/pom.xml| sed -e 's!<version>!!g' -e 's!</version>!!g' | tr -d " ")
CurrentVersionWithoutSnapshot=$(echo $CurrentVersion  | sed -e 's!-SNAPSHOT!!g')

# Upload the SNAPSHOT version of the war and rpm to nexus - this is the current version as it's checked out of GIT 
mvn -q -f Function/pom.xml deploy
mvn -q -f ServiceDescription/pom.xml versions:set -DnewVersion=$CurrentVersion -Dmvn_version=$CurrentVersion
mvn -q -f ServiceDescription/pom.xml -Dmvn_version=$CurrentVersion deploy

# Change the version number in the POM to remove the snapshot identifier and RELEASE into NEXUS
mvn -q -f Function/pom.xml versions:set -DnewVersion=$CurrentVersionWithoutSnapshot -Dmvn_version=$CurrentVersionWithoutSnapshot 
mvn -q -f Function/pom.xml deploy
mvn -q -f ServiceDescription/pom.xml versions:set -DnewVersion=$CurrentVersionWithoutSnapshot -Dmvn_version=$CurrentVersionWithoutSnapshot
mvn -q -f ServiceDescription/pom.xml -Dmvn_version=$CurrentVersionWithoutSnapshot deploy
