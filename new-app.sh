#!/bin/bash

NEW_REPO=1
DEBUG=1
CURRENT_DIR=`pwd`

github_token=$1
# The basic dependencies.
dependencies="web,devtools"

# Minimum required info.
read -p "JIRA key: " jira_key
read -p "GroupId: ca.canada.ised.$jira_key." group_id_suffix
read -p "ArtifactId: " artifact_id

# Ask a few questions to gether dependencies.
read -p "Requires security? (y/n): " has_security
read -p "Requires database? (y/n): " has_db
read -p "Requires mail? (y/n): " has_mail
# Or... just ask for a comman separted list.
#read -p "Comma-separted list of dependences: web,devtools," dependencies

group_id="ca.canada.ised.$group_id_suffix"

if [ $has_security = 'y' ]
then
    dependencies="$dependencies,security"
fi

if [ $has_db = 'y' ]
then
    dependencies="$dependencies,data-jpa,h2,postgresql,liquibase"
fi

if [ $has_mail = 'y' ]
then
    dependencies="$dependencies,mail"
fi

echo "Creating new project with following details."
echo "JIRA key:        $jira_key"
echo "GroupId:         $group_id"
echo "ArtifactId:      $artifact_id"
echo "Dependency list: $dependencies "

temp_dir=$(mktemp -d)
if [ $DEBUG -eq 1 ]
then
    echo "Temp dir: $temp_dir"
fi

# Generate a new project and extract it to the temp dir.
curl https://start.spring.io/starter.tgz \\
    -d artifactId=$artifactId \\
    -d groupId=$groupId \\
    -d dependencies=$dependencies \\
    -d applicationName=$artifactId \\
    | tar -C $temp_dir -xzf -

# Make a folder for OCP and copy files.
mkdir "$temp_dir/ocp"
cp ocp/template.yaml $temp_dir/ocp
cp jenkins/Jenkinsfile $temp_dir

cd $temp_dir

if [ $NEW_REPO -eq 1 ]
then
    curl -i -H "Authorization: token $github_token" \
        -d '{ 
            "name": "'"$artifactId"', 
            "has_issues": false,
            "has_projects": false,
            "has_wiki": false
        }' \
        https://api.github.com/user/repos

    git init
    git add --all
    git commit -m "Initial commit."
    git remote add origin git@github.com:pittar/testrepo.git
    git push -u origin master

    # Create DEV and TEST ocp projects.
    oc new-project $jira_key-dev
    #oc new-project $jira_key-test
    oc process -f ocp/template.yaml -p GIT_SOURCE_URL=https://github.com/pittar/testrepo.git \
        | oc create -f -

    rm -rf $temp_dir
fi

