#!/bin/bash

set -euo pipefail

help() {
  echo 'Usage: bazel run target_label -- [-p pkg_list] [-v ver_list]'
  echo '  -p  pkg_list is a comma-separated list of the packages to be checked'
  echo '  -v  ver_list is a comma-separated list of the desired versions of the packages in pkg_list', the latest versions are taken if this option is missing
}

REPO_DIR="stage-repo"
OUTPUT_PKGS_PATH="output_pkgs"

REPO_MGMT_SCRIPT="{repo_mgmt_script}"
DEP_UTILS_SCRIPT="{dep_utils_script}"
REPO_PACKAGE_LIST="${OUTPUT_PKGS_PATH}/{repo_package_list}"
APPLIED_PACKAGE_LIST="${OUTPUT_PKGS_PATH}/{applied_package_list}"
PACKAGE_LIST="{package_list}"

BASE_OUTPUT_PATH="{base_output_path}"


PKGS="{pkgs}"
PKG_VERSIONS="{versions}"
EXTRA_R_LIBS="{extra_r_libs}"

export R_LIBS="${R_LIBS:-""}:${EXTRA_R_LIBS}"

rm -rf "${OUTPUT_PKGS_PATH}" "${REPO_DIR}"
mkdir -m 755 -p "${OUTPUT_PKGS_PATH}" "${REPO_DIR}"

while getopts "p:v:h" opt; do
  case "$opt" in
    "p") PKGS="${OPTARG}";;
    "v") PKG_VERSIONS="${OPTARG}";;
    "h") help; exit 0;;
    "?") error "invalid option: -$OPTARG"; help; exit 1;;
  esac
done

if [ -z "$PKGS" ]; then
    echo "pkg_list not set"
    help; exit 1;
fi

if [ -n "$PKG_VERSIONS" ]; then
    if [ `awk -F, '{print NF}' <<<$PKGS` -ne `awk -F, '{print NF}' <<<$PKG_VERSIONS` ] ; then
        echo "pkg_list and ver_list do not match"
        help; exit 2;
    fi
fi

echo "Pulling packages into ${REPO_DIR} ..."
FORMATTED_PKGS=$( sed -e "s/^/c('/" -e "s/\$/')/" -e "s/,/',\'/g" <<<${PKGS} )

if [ -n "${PKG_VERSIONS}" ]; then
   FORMATTED_PKG_VERSIONS=$( sed -e "s/^/c('/" -e "s/\$/')/" -e "s/,/',\'/g" <<<${PKG_VERSIONS} )

else
   FORMATTED_PKG_VERSIONS=NA
fi

echo "FORMATTED_PKG_VERSIONS == $FORMATTED_PKG_VERSIONS"

Rscript \
     -e "options(repos={repos})" \
     -e "sprintf('Configured repositories: %s', getOption('repos'))" \
     -e "source('${REPO_MGMT_SCRIPT}')" \
     -e "addPackagesToRepo(repo_dir='${REPO_DIR}', pkgs = ${FORMATTED_PKGS}, versions = $FORMATTED_PKG_VERSIONS)"


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

echo -e "Applied difference has been stored in '`realpath "${APPLIED_PACKAGE_LIST}"`'"