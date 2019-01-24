#!/bin/bash

group_id_prefix="com.example"
new_repo=1
debug=1
work_dir=`pwd`

github_token=$1
# The basic dependencies.
dependencies="web,devtools"

# Minimum required info.
read -p "JIRA key: " jira_key
read -p "GroupId: $group_id_prefix.$jira_key." group_id_suffix
read -p "ArtifactId: " artifact_id

# Ask a few questions to gether dependencies.
read -p "Requires security? (y/n): " has_security
read -p "Requires database? (y/n): " has_db
read -p "Requires mail? (y/n): " has_mail
# Or... just ask for a comman separted list and don't bother asking individual questions.
#read -p "Comma-separted list of dependences: web,devtools," dependencies

group_id="$group_id_prefix.$jira_key.$group_id_suffix"

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
if [ $debug -eq 1 ]
then
    echo "Temp dir: $temp_dir"
fi

# Generate a new project and extract it to the temp dir.
curl https://start.spring.io/starter.tgz \
    -d artifactId=$artifact_id \
    -d groupId=$group_id \
    -d dependencies=$dependencies \
    -d applicationName=$artifact_id \
    | tar -C $temp_dir -xzf -

# Make a folder for OCP and copy files.
mkdir "$temp_dir/ocp"
cp ocp/template.yaml $temp_dir/ocp
cp jenkins/Jenkinsfile $temp_dir
cp .gitignore $temp_dir
# Delete maven wrapper. Comment this out if you actually want it.
rm -rf $temp_dir/.mvn
rm $temp_dir/mvnw
rm $temp_dir/mvnw.cmd

cd $temp_dir

if [ $new_repo -eq 1 ]
then
    curl -i -H "Authorization: token $github_token" \
        -d "$(generate_post_data)" \
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

    # Bak to originl directory.
    cd $work_dir
    # Delete temp dir.
    rm -rf $temp_dir
fi

generate_post_data() {
  cat <<EOF
{ 
    "name": "$artifact_id", 
    "has_issues": false,
    "has_projects": false,
    "has_wiki": false
}
EOF 
}