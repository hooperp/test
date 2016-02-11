
if ! $(wget -q http://aretzm01:8081/nexus/ ) ; then 
    echo "Nexus server is not running" 
    exit 1 
fi


#curl --request DELETE --write "%{http_code} %{url_effective}\\n" --user admin:admin123 --output /dev/null --silent http://aretzm01:8081/nexus/content/repositories/snapshots/uk/ >/dev/null 2>&1

curl --request DELETE --user admin:admin123 --output /dev/null --silent http://aretzm01:8081/nexus/content/repositories/snapshots/uk/ >/dev/null 2>&1


#curl --request DELETE --write "%{http_code} %{url_effective}\\n" --user admin:admin123 --output /dev/null --silent http://aretzm01:8081/nexus/content/repositories/releases/uk/ >/dev/null 2>&1

curl --request DELETE --user admin:admin123 --output /dev/null --silent http://aretzm01:8081/nexus/content/repositories/releases/uk/ >/dev/null 2>&1



