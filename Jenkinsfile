#!groovy
// Build and push docker images by branches and tags
// Required: "Basic Branch Build Strategies Plugin"
// GitHub Behaviours: Discover tags
// GitHub Behaviours: Clean Before Checkout
// GitHub Build strategies: Regular Branches
// GitHub Build strategies: Tags
// Scan Repository Triggers Periodically  if no hooks
properties([disableConcurrentBuilds()])

pipeline {
    agent {
        label 'master'
    }
    triggers {
        githubPush()
    }
    options {
        buildDiscarder(logRotator(numToKeepStr: '15', artifactNumToKeepStr: '15'))
        timestamps()
    }
    stages {
        stage("Preparations") {
            steps {
                script {
                    // getting repo url and cutting it to get docker image name
                    sh """
                    echo ${GIT_URL} | sed 's@.*-@@' | rev | cut -c 5- | rev | tr -d '\n' >  ${WORKSPACE}/env.GIT_URL
                    """
                    env.GIT_REPO = readFile (file: "${WORKSPACE}/env.GIT_URL")
                    slackSend channel: '#jenkins',
                        color: 'good',
                        message: "Job for building ${env.GIT_REPO}:${GIT_BRANCH} started: <${env.BUILD_URL}|View Result>"
                }
            }
        }
        stage("Build docker image :latest") {
            when { not { tag "*" } }
            steps {
                script {
                    echo " ============== start building :latest from ${env.GIT_REPO}:${GIT_BRANCH} =================="
                    sh """
                    docker build -t exodusmovement/${env.GIT_REPO}:latest .
                    """
                    currentBuild.description = "${env.GIT_REPO}:latest built, "
                }
            }
        }
        stage("Push docker image :latest") {
            when { not { tag "*" } }
            steps {
                script {
                    echo " ============== start pushing :latest from ${env.GIT_REPO}:${GIT_BRANCH} =================="
                    withDockerRegistry([ credentialsId: "exodusmovement-docker-creds", url: "" ]) {
                        sh """
                        docker push exodusmovement/${env.GIT_REPO}:latest
                        """
                    }
                    currentBuild.description += "and pushed to registry"
                }
            }
        }
        stage("Build docker image :release") {
            when { tag "*" }
            steps {
                script {
                    echo " ============== start building :${GIT_BRANCH} from ${env.GIT_REPO}:${GIT_BRANCH} =================="
                    sh """
                    docker build -t exodusmovement/${env.GIT_REPO}:${GIT_BRANCH} .
                    """
                    currentBuild.description = "${env.GIT_REPO}:${GIT_BRANCH} built, "
                }
            }
        }
        stage("Push docker image :release") {
            when { tag "*" }
            steps {
                script {
                    echo " ============== start pushing ${GIT_BRANCH} from ${env.GIT_REPO}:${GIT_BRANCH} =================="
                    withDockerRegistry([ credentialsId: "exodusmovement-docker-creds", url: "" ]) {
                        sh """
                        docker push exodusmovement/${env.GIT_REPO}:${GIT_BRANCH}
                        """
                    }
                    currentBuild.description += "and pushed to registry"
                }
            }
        }
    }
    post {
        failure {
            slackSend channel: '#jenkins',
                color: 'danger',
                message: "Job for building ${env.GIT_REPO}:${GIT_BRANCH} failed: <${env.BUILD_URL}|View Result>"
        }
        aborted {
            slackSend channel: '#jenkins',
                color: 'warning',
                message: "Job for building ${env.GIT_REPO}:${GIT_BRANCH} aborted: <${env.BUILD_URL}|View Result>"
        }
        success {
            slackSend channel: '#jenkins',
                color: 'good',
                message: "Job for building ${env.GIT_REPO}:${GIT_BRANCH} finished: <${env.BUILD_URL}|View Result>"
        }
    }
}
