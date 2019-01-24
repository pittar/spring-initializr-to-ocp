#!/bin/bash

NEW_REPO=0
DEBUG=1

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
curl https://start.spring.io/starter.tgz \
    -d dependencies=$dependencies \
    -d artifactId=$artifactId \
    -d groupId=$groupId \
    -d applicationName=$artifactId \
    | tar -C $temp_dir -xzf -

if [ $NEW_REPO -eq 1 ]
then
    curl -i -H "Authorization: token $github_token" \
        -d '{ 
            "name": "testrepo", 
            "has_issues": false,
            "has_projects": false,
            "has_wiki": false,
            "gitignore_template": "Maven"
        }' \
        https://api.github.com/user/repos
fi

