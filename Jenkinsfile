@Library('Jenkins-Shared-Lib') _

pipeline {
    agent {
        kubernetes {
            yaml jenkinsAgent("registry.runicrealms.com")
        }
    }

    environment {
        IMAGE_NAME = 'realm-paper'
        PROJECT_NAME = 'Realm Paper'
        REGISTRY = 'registry.runicrealms.com'
        REGISTRY_PROJECT = 'build'
    }

    stages {
        stage('Send Discord Notification (Build Start)') {
            steps {
                discordNotifyStart(env.PROJECT_NAME, env.GIT_URL, env.GIT_BRANCH, env.GIT_COMMIT.take(7))
            }
        }
        stage('Determine Environment') {
            steps {
                script {
                    def branchName = env.GIT_BRANCH.replaceAll(/^origin\//, '').replaceAll(/^refs\/heads\//, '')

                    echo "Using normalized branch name: ${branchName}"

                    if (branchName == 'dev') {
                        env.RUN_MAIN_DEPLOY = 'false'
                    } else if (branchName == 'main') {
                        env.RUN_MAIN_DEPLOY = 'true'
                    } else {
                        error "Unsupported branch: ${branchName}"
                    }
                }
            }
        }
        stage('Pull Plugin Artifacts') {
            steps {
                container('jenkins-agent') {
                    script {
                        def manifest = readYaml file: 'plugin-manifest.yaml'
                        manifest.artifacts.each { artifact ->
                            def parts = artifact.name.tokenize('/')
                            def registry = parts[0]
                            def registryProject = parts[1]
                            def artifactName = parts[2]

                            echo "Pulling ${artifactName} from ${registry}/${registryProject} with tag ${artifact.newTag}"
                            orasPull(artifactName, artifact.newTag, 'plugins', registry, registryProject)
                        }
                    }
                }
            }
        }
        stage('Build and Push Docker Image') {
            steps {
                container('jenkins-agent') {
                    dockerBuildPush("Dockerfile", env.IMAGE_NAME, env.GIT_COMMIT.take(7), env.REGISTRY, env.REGISTRY_PROJECT)
                }
            }
        }
        stage('Update Deployment') {
            steps {
                container('jenkins-agent') {
                    updateManifest('dev', 'Realm-Deployment', 'base/kustomization.yaml', env.IMAGE_NAME, env.GIT_COMMIT.take(7), env.REGISTRY, env.REGISTRY_PROJECT)
                }
            }
        }
        stage('Create PR to Promote Realm-Deployment Dev to Main (Prod Only)') {
            when {
                expression { return env.RUN_MAIN_DEPLOY == 'true' }
            }
            steps {
                container('jenkins-agent') {
                    createPR('Realm-Paper', 'Realm-Deployment', 'dev', 'main')
                }
            }
        }
    }

    post {
        success {
            discordNotifySuccess(env.PROJECT_NAME, env.GIT_URL, env.GIT_BRANCH, env.GIT_COMMIT.take(7))
        }
        failure {
            discordNotifyFail(env.PROJECT_NAME, env.GIT_URL, env.GIT_BRANCH, env.GIT_COMMIT.take(7))
        }
    }
}
