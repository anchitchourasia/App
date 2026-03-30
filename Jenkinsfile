pipeline {
    agent any

    options {
        skipDefaultCheckout()
    }

    environment {
        FLUTTER_DIR = 'HEG'
        BACKEND_DIR = 'backend\\demo'
        MVN_CMD = 'C:\\Users\\heg\\.m2\\wrapper\\dists\\apache-maven-3.9.12\\59fe215c0ad6947fea90184bf7add084544567b927287592651fda3782e0e798\\bin\\mvn.cmd'
        MVN_SETTINGS = 'C:\\Users\\heg\\.m2\\settings.xml'

        PROXY_HOST = '192.168.9.112'
        PROXY_PORT = '8080'
        NO_PROXY_VALUE = 'localhost,127.0.0.1,::1'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Spring Boot Backend') {
            steps {
                dir("${env.BACKEND_DIR}") {
                    bat "\"%MVN_CMD%\" -s \"%MVN_SETTINGS%\" clean package -DskipTests -U"
                }
            }
        }

        stage('Build Flutter App') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'proxy-creds',
                    usernameVariable: 'PUSER',
                    passwordVariable: 'PPASS'
                )]) {
                    dir("${env.FLUTTER_DIR}") {
                        bat '''
                            @echo on
                            git config --global --add safe.directory C:/flutter/flutter
                            git config --global --add safe.directory C:/ProgramData/Jenkins/.jenkins/jobs/Company-Fullstack-App/workspace/HEG

                            set PROXY_URL=http://%PUSER%:%PPASS%@%PROXY_HOST%:%PROXY_PORT%
                            set http_proxy=%PROXY_URL%
                            set https_proxy=%PROXY_URL%
                            set HTTP_PROXY=%PROXY_URL%
                            set HTTPS_PROXY=%PROXY_URL%
                            set no_proxy=%NO_PROXY_VALUE%
                            set NO_PROXY=%NO_PROXY_VALUE%

                            flutter doctor -v
                            call flutter pub get -v
                            if errorlevel 1 exit /b 1

                            call flutter build apk --release -v
                            if errorlevel 1 exit /b 1
                        '''
                    }
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: "${env.BACKEND_DIR}/target/*.jar", allowEmptyArchive: false
                archiveArtifacts artifacts: "${env.FLUTTER_DIR}/build/app/outputs/flutter-apk/app-release.apk", allowEmptyArchive: false
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Backend JAR and Flutter APK built successfully!'
        }
        failure {
            echo 'FAILED: Check Console Output for errors.'
        }
    }
}