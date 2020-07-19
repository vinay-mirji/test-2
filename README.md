# ANZ test2
[![Build Status](https://travis-ci.com/vinay-mirji/test-2.svg?token=m4spbWRfaq9sJepYZkeo&branch=master)](https://travis-ci.com/vinay-mirji/test-2)

 - [Introduction](https://github.com/vinay-mirji/test-2#introduction)
 - [Installation and Execution](##installation-and-execution)
    - [Pre-requisites](###pre-requisites)
    - [Build and execute](###build-and-execute)
        - [Run just the nodejs application without docker](####run-nodejs-application-without-docker)
        - [Build and run using docker manually](####build-and-run-using-docker-manually)
        - [CI using travis](####continuous-integration-using-travis-ci-tool)
    - [Application versioning](###application-versioning)
    - [Risks associated with application/deployment](###risks)



## Introduction
This repository contains all code necessary to containerize a simple `nodejs` application using **docker** and uses [travis-ci](https://travis-ci.com/) for CI.

The application expose an end point `/version` on port `8080` which is configurable.

---

## Installation and Execution

### Pre requisites
 - Download and install `NodeJS` from [node downloads](https://nodejs.org/en/download/). The current LTS version is 12.18.2. This is only needed to make changes and check locally if you dont want to use `docker` for development.

 - Download and install `Docker Desktop` if your machine does not have `docker` already installed. [Docker Desktop](https://www.docker.com/products/docker-desktop)

 - A `github` account.

 - A [travis-ci](https://travis-ci.com/) account. You can use your `github` account created above for this step. (for CI).

 - A [Snyk](https://snyk.io/) account which can again use your `github` account for a quick set up.

 - A [Dockerhub](https://hub.docker.com/) account. This will be used to publish the docker image.


### Build and execute

#### Run nodejs application without docker

Clone this git repository using : 

    git clone https://github.com/vinay-mirji/test-2

Install necessary packages

    npm install

Run the application 

    npm start

See if it works. Go to your favourite browser and type 

    http://localhost:8081/version 

Note that the default port used is 8081. 
On the browser a JSON object is shown which contains
- Application version : this is indicated by `version`. It is read from the `version` in `package.json` file of the application during runtime.

- Last commit SHA : this is indicated by `sha`. It is read from the `metadata` file during runtime.

- Description : this is indicated by `description`. It is also read from `package.json`.


To run unit tests use 

     npm test 

To run the security tests we need to install and authenticate snyk. 
See [here](https://snyk.io/test/) for details.


#### Build and run using docker manually

Run docker build with

     docker build -t local-build-tag --build-arg COMMIT_SHA=test1234 --build-arg PORT_ARG=8080 . 

The args are used to simulate a CI environment.

`COMMIT_SHA` refers to the last git commit.

`PORT_ARG` allows us to specify the port for the application. This overrides the default value of `8081`.

The build occurs in multiple stages

- unit test - *tester* stage.
- install dependencies - *builder* stage
- final step to generate the docker image

To run only the tests use 

    docker build -t run_tests --target tester .

Once the build stage is succesful we can now run the container

     docker run -p 80:8080 -d --name test2 local-build-tag 

- `--name` is helpful in identifying the container in `docker-desktop` or when listing the docker application using `docker ps`

- `local-build-tag` is the image which was built earlier.
-  Port 80 of the machine is mapped to 8080 of the docker image.


To run snyk tests on docker container use

    snyk test --docker local-build-tag

To test the application again open a browser and type

    http://localhost/version


#### Continuous Integration using Travis CI tool

We use travis-ci for CI and it can be further extended for CD. Integration of our github repo with travis-ci allows us to continuously test, build and publish docker images

- Integrate with github by following these [steps](https://docs.travis-ci.com/user/tutorial/#to-get-started-with-travis-ci-using-github)

- Set the below variables for our repository. For steps refer to [Defining variables in repository settings](https://docs.travis-ci.com/user/environment-variables/#defining-variables-in-repository-settings)
    - DOCKER_PASSWORD - the password used for docker hub account
    - DOCKER_USER - user name of the docker hub account
    - PORT_ARG - port for the application to run
    - PROJECT - name of the project
    - SNYK_TOKEN - api token used for snyk testing. It can be obtained by referring to this [article](https://support.snyk.io/hc/en-us/articles/360004008258-Authenticate-the-CLI-with-your-account)

- [travis.yml](https://github.com/vinay-mirji/test-2/blob/master/.travis.yml) file has necessary code to run the build in **travis-ci**. The build includes
    - Run unit tests using the `tester` target
    - Run snyk tests for npm packages
    - Build the docker image and tag using commit sha.
    - Run snyk tests on the docker image.
    - Tag and push the image to docker hub.

- To trigger a build we need to commit and push to this repo. Travis-CI will automatically trigger a build and push the image to docker hub using the login credentials provided in env variables.

- We can use this image from docker hub to run the application on our local machine.

    Get the image from docker hub 

        docker pull vinaymirji/test-2

    Run it

        docker run -p 80:8080 -d --name test2 vinaymirji/test-2

    Test on browser using

        http://localhost/version

### Application versioning

The node package versioning is controlled by `version` in `package.json`. A 3 part versioning approach is following for the node application.

- patch version is incremented for security patches etc which are backward compatible.
    
         npm version patch  

- minor version is incremented for bug fixes and small enhancements.

         npm version minor  

- major version is incremented for breaking changes/ major upgrades/ new features which may not be compatible with previous versions of the application
        
        npm version major  


Docker image versioning is handled by CI pipeline which tags the images using the first 6 characters of the git commit sha. 
It can be changed to use the pipeline build number by making some changes to [travis.yml](https://github.com/vinay-mirji/test-2/blob/master/.travis.yml) file. 

To acheive this replace `$COMMIT` in the file with `$TRAVIS_BUILD_NUMBER`


### Risks
1. The application is not secure and once deployed anybody can access the api `/version`. This puts the application at risk for DDoS style of attacks.

2. The CI pipeline warns about the unencrypted password being stored in the home directory. To overcome this we need to use encrypted keys for `DOCKER_PASSWORD` and `DOCKER_USER`

3. The docker container can potentially run more than just the nodejs application. To prevent this we can use `dumb-init` which always uses `PID 1` for the application it starts. This way we can avoid multiple processes in a single container.

4. The application is run as non-root user and hence prevents risks associated with root user access.
