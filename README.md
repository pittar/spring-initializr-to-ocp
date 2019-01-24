# Intializr to OCP

A collection of scripts, Jenkinsfiles, and OpenShift Templates to automate creating a new Spring Boot app from [Spring Initializr](https://start.spring.io/), creating a new GitHub repo, and setting up a build/deploy pipeline on OCP with a Jenkinsfile.

## Prerequisites

## GitHub Personal Access Token

If you don't already have a [GitHub](https://github.com) account, you'll need to create one.
Login to GitHub and go to `Settings -> Developer Settings -> Personal access tokens`.  Create a token and make sure it has *Full control of private repositories*.

Take note of your new token, you will need it to run the script.

### OpenShift Instance

There are a few options here:
* Use an existing OpenShift Container Platform cluster that you already have access to (self managed or Dedicated)
* Sign up for the [OpenShift Online free tier](https://www.openshift.com/products/online/)
* Run [Minishift](https://docs.okd.io/latest/minishift/getting-started/installing.html), a single-node OKD cluster, on your local machine (Linux/MacOS/Windows).
* Sign up for a free Red Hat account and download/run [Red Hat Container Development Kit](https://developers.redhat.com/products/cdk/overview/)

I developed this using Minishift (OKD 3.11) on a Mac, but it should work just as well on Linux.  For Windows, you will need a tool like [Cygwin](http://www.cygwin.com/) to run the shell script.

Make sure you have the `oc` binary on your path.  The `new-app.sh` script makes use of it.

### OpenJDK 8 Image (Minishift)

If you aren't running on Minishift, you can skip this step.

If you are using OpenShift Container Platform (self installed/Dedicated/Online) the image should be included already.  If you are using Minishift, you may need to add the image manually.  It's easiest to add the image to the `openshift` namespace so that all other projects have access to it.

```
oc import-image openjdk18-openshift \ 
    --from=registry.access.redhat.com/redhat-openjdk-18/openjdk18-openshift \
    -n openshift \
    --confirm
```

## Running the Script

Now that you have running instance of OpenShift (or OKD) that you can connect to you're ready to try this out!

1. First, login to your cluster: `$ oc login ...`.  If you are using Minishift, this is simply `oc login -u developer`
2. Execute the script `$ ./new-app.sh <github personal access token>`

The script will prompt for a few bits of info (GAV info, if app needs scurity or DB, etc...).  When it's done, it will:
* `POST` that data to the Spring Intializr site.
* Expand the resulting tar file into a temp directory.
* Add a Jenkinsfile to the new app.
* Add an OpenShift template file to the new app.
* Create a new GitHub repo in your account with the same name as the supplied *artifactId*.
* Initialize the local git repository, add and commit files, then push to the new GitHub repo.
* Run the `oc` commands to create the new OpenShift projects, create the template, and launch the pipeline build.

This is still very much a work in progress, but it's also a good example of some easy automation with a little bit of scripting!



