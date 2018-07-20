#!/bin/bash

set -e

# synopsis {{{
# Script that knows how to define the concrete type of the JVM project.
# Scans for presence of files.
# }}}

# It takes ages on Docker to run the app without this
# Also we want to disable the progress indicator for downloaded jars
export MAVEN_OPTS="${MAVEN_OPTS} -Djava.security.egd=file:///dev/urandom -Dorg.slf4j.simpleLogger.log.org.apache.maven.cli.transfer.Slf4jMavenTransferListener=warn"
export BINARY_EXTENSION="${BINARY_EXTENSION:-jar}"

# FUNCTION: downloadAppBinary {{{
# Fetches a JAR from a binary storage
#
# $1 - URL to repo with binaries
# $2 - group id of the packaged sources
# $3 - artifact id of the packaged sources
# $4 - version of the packaged sources
function downloadAppBinary() {
	local repoWithJars="${1}"
	local groupId="${2}"
	local artifactId="${3}"
	local version="${4}"
	local destination
	local changedGroupId
	local pathToJar
	destination="$(pwd)/${OUTPUT_FOLDER}/${artifactId}-${version}.${BINARY_EXTENSION}"
	changedGroupId="$(echo "${groupId}" | tr . /)"
	pathToJar="${repoWithJars}/${changedGroupId}/${artifactId}/${version}/${artifactId}-${version}.${BINARY_EXTENSION}"
	mkdir -p "${OUTPUT_FOLDER}"
	echo "Current folder is [$(pwd)]; Downloading binary to [${destination}]"
	local success="false"
	curl -u "${M2_SETTINGS_REPO_USERNAME}:${M2_SETTINGS_REPO_PASSWORD}" "${pathToJar}" -o "${destination}" --fail && success="true"
	if [[ "${success}" == "true" ]]; then
		echo "File downloaded successfully!"
		return 0
	else
		echo "Failed to download file!"
		return 1
	fi
} # }}}

# FUNCTION: isMavenProject {{{
# Returns true if Maven Wrapper is used
function isMavenProject() {
	[ -f "mvnw" ]
} # }}}

# FUNCTION: isGradleProject {{{
# Returns true if Gradle Wrapper is used
function isGradleProject() {
	[ -f "gradlew" ]
} # }}}

# FUNCTION: projectType {{{
# JVM implementation of projectType
function projectType() {
	if isMavenProject; then
		echo "MAVEN"
	elif isGradleProject; then
		echo "GRADLE"
	else
		echo "UNKNOWN"
	fi
} # }}}

[[ -z "${PROJECT_TYPE}" || "${PROJECT_TYPE}" == "null" ]] && PROJECT_TYPE=$(projectType)

export -f projectType
export PROJECT_TYPE

echo "Project type [${PROJECT_TYPE}]"

# Setting a default when
[[ -z "${REPO_WITH_BINARIES_FOR_UPLOAD}" ]] && REPO_WITH_BINARIES_FOR_UPLOAD="${REPO_WITH_BINARIES}"

lowerCaseProjectType=$(echo "${PROJECT_TYPE}" | tr '[:upper:]' '[:lower:]')
__DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=/dev/null
[[ -f "${__DIR}/pipeline-${lowerCaseProjectType}.sh" ]] &&  \
 source "${__DIR}/pipeline-${lowerCaseProjectType}.sh" ||  \
 echo "No ${__DIR}/pipeline-${lowerCaseProjectType}.sh found"
