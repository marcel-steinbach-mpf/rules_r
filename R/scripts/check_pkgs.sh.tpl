#!/bin/bash

set -euo pipefail

help() {
  echo 'Usage: bazel run target_label -- [-p pkg_list]'
  echo '  -p  pkg_list is a comma-separated list of the packages to be checked'
}

REPO_MGMT_SCRIPT="{repo_mgmt_script}"
DEP_UTILS_SCRIPT="{dep_utils_script}"
REPO_PACKAGE_LIST="{repo_package_list}"
APPLIED_PACKAGE_LIST="{applied_package_list}"
PACKAGE_LIST="{package_list}"

REPO_DIR="{repo_dir}"
PKGS="{pkgs}"

while getopts "p:h" opt; do
  case "$opt" in
    "p") PKGS="${OPTARG}";;
    "h") help; exit 0;;
    "?") error "invalid option: -$OPTARG"; help; exit 1;;
  esac
done

if [ -z "$PKGS" ]; then
    echo "pkg_list not set"
    help; exit 1;
fi

REPO_PACKAGE_LIST=${REPO_PACKAGE_LIST:-"external_packages_$(tr , _ <<<$PKGS).csv"}

echo "Pulling packages into ${REPO_DIR} ..."
FORMATTED_PKGS=$( sed -e "s/^/'/" -e "s/\$/'/" -e "s/,/',\'/g" <<<${PKGS} )
echo $FORMATTED_PKGS
Rscript \
     -e "options(repos={repos})" \
     -e "sprintf('Configured repositories: %s', getOption('repos'))" \
     -e "source('${REPO_MGMT_SCRIPT}')" \
     -e "addPackagesToRepo(repo_dir='${REPO_DIR}', pkgs=c(${FORMATTED_PKGS}))"


echo "Creating a package CSV ${REPO_PACKAGE_LIST}"

Rscript \
      -e "source('${REPO_MGMT_SCRIPT}')" \
      -e "packageList(repo_dir='${REPO_DIR}', output_file='${REPO_PACKAGE_LIST}', sha256=TRUE)"

echo "Comparing ${REPO_PACKAGE_LIST} and ${PACKAGE_LIST} ..."

Rscript \
      -e "source('${DEP_UTILS_SCRIPT}')" \
      -e "printPackageDiff(base_package_list='${PACKAGE_LIST}', new_package_list='${REPO_PACKAGE_LIST}')"


APPLIED_PACKAGE_LIST=${APPLIED_PACKAGE_LIST:-"external_packages_$(tr , _ <<<$PKGS)_applied.csv"}

Rscript \
      -e "source('${DEP_UTILS_SCRIPT}')" \
      -e "writePackageDiff(base_package_list='${PACKAGE_LIST}', new_package_list='${REPO_PACKAGE_LIST}', output='${APPLIED_PACKAGE_LIST}')"

echo "Applied difference has been stored in ${APPLIED_PACKAGE_LIST}"