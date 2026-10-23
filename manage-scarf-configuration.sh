#!/bin/bash

#
# The service of scarf.sh is available as CNCF benefits,
# so distribute fluent-package via scarf.sh.
# The following routes are used:
#
# packages.fluentd.org
# => fluentd.gateway.scarf.sh
# => fluentd.cdn.cncf.io
#

function info()
{
    _MSG=$1
    echo -e "[\e[32;40mINFO\e[0m] ${_MSG}"
}

function fail()
{
    _MSG=$1
    echo -e "[\e[31;40mFAIL\e[0m] ${_MSG}"
}


if [ -z "${SCARF_API_TOKEN}" ]; then
    fail "no SCARF_API_TOKEN"
    exit 1
fi

YYYYMMDD=$(date +'%Y%m%d')
case $1 in
    backup)
        info "List packages"
        for entry in $(curl --silent --header "Authorization: Bearer ${SCARF_API_TOKEN}" \
                              https://api.scarf.sh/v2/packages/fluentd | \
                             jq --raw-output '.results[] | "\(.id),\(.name)"'); do
            package_id=$(echo $entry | cut -d',' -f1)
            package_name=$(echo $entry | cut -d',' -f2)
            info "Get package routes (File Packages): ${package_name}"
            curl --silent --header "Authorization: Bearer ${SCARF_API_TOKEN}" \
                 "https://api.scarf.sh/v2/packages/fluentd/${package_id}/routes?per_page=30" > ${package_name}.${YYYYMMDD}.json
        done
        ;;
    deploy)
        if [ $# -ne 3 ]; then
            fail "$0 deploy [PACKAGE_NAME] [PATH_TO_JSON_FILE]"
            exit 1
        fi
        name=$2
        json=$3
        if [ ! -f "$json" ]; then
            fail "No such $json"
            exit 1
        fi

        package_id=""
        response=$(curl --silent \
                        --header "Authorization: Bearer ${SCARF_API_TOKEN}" \
                        --header "Content-Type: application/json" \
                        "https://api.scarf.sh/v2/packages/fluentd/file/${name}")
        if [ "$response" = "" ]; then
            info "no such a package ${name} yet"
        else
            package_id=$(echo $response | jq --raw-output ".id")
            fail "Already package ${name} exists: ${package_id}"
            exit 1
        fi

        count=1
        total=$(jq --raw-output 'length' $json)
        jq --raw-output '.[] | "\(.incoming_path) \(.outgoing_url)"' $json | 
            while IFS=" " read -r incoming outgoing; do
            if [ $count -eq 1 ]; then
                info "create a new package: ${name}"
                info "(${count}/${total}) ${incoming} => ${outgoing}"
                response=$(curl --silent --request POST \
                        --header "Authorization: Bearer ${SCARF_API_TOKEN}" \
                        --header "Content-Type: application/json" \
                        --data "{ \
                               \"name\": \"${name}\", \
                               \"type\": \"file\", \
                               \"incoming_path\": \"${incoming}\", \
                               \"outgoing_url\": \"${outgoing}\", \
                        }" \
                        "https://api.scarf.sh/v2/packages/fluentd")
                if [ "$response" = '{"code":"package-already-exists","message":"Package already exists."}' ]; then
                    fail "Package already exists: <${name}>"
                    exit 1
                else
                    echo $response
                    package_id=$(echo $response | jq --raw-output ".id")
                    echo $package_id
                fi
            else
                if [ -n "$package_id" ]; then
                    info "(${count}/${total}) create route: ${incoming} => ${outgoing}"
                    curl --silent --show-error --request POST \
                        --header "Authorization: Bearer ${SCARF_API_TOKEN}" \
                        --header "Content-Type: application/json" \
                        --data "{ \
                               \"type\": \"uri-template\", \
                               \"incoming_path\": \"${incoming}\", \
                               \"outgoing_url\": \"${outgoing}\" \
                        }" \
                        "https://api.scarf.sh/v2/packages/fluentd/${package_id}/routes"
                    echo $response
                else
                    fail "No package id found"
                    exit 1
                fi
            fi
            count=$((count + 1))
        done
        ;;
    *)
        info "$0 [backup|deploy]"
        ;;
esac
      
