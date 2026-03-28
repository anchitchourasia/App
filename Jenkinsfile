pipeline {
    agent any

    environment {
        FLUTTER_DIR = 'HEG'
        BACKEND_DIR = 'backend\\demo'
        MVN_CMD = 'C:\\Users\\heg\\.m2\\wrapper\\dists\\apache-maven-3.9.12\\59fe215c0ad6947fea90184bf7add084544567b927287592651fda3782e0e798\\bin\\mvn.cmd'
        MVN_SETTINGS = 'C:\\Users\\heg\\.m2\\settings.xml'

        PROXY_HOST = '192.168.9.112'
        PROXY_PORT = '8080'
        NO_PROXY_VALUE = 'localhost,127.0.0.1,::1'

        ANDROID_HOME = 'C:\\Users\\heg\\AppData\\Local\\Android\\Sdk'
        ANDROID_SDK_ROOT = 'C:\\Users\\heg\\AppData\\Local\\Android\\Sdk'

        PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
        FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
        PUB_CACHE = 'C:\\flutter\\.pub-cache'
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

        stage('Prepare Flutter Cache') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'proxy-creds',
                    usernameVariable: 'PUSER',
                    passwordVariable: 'PPASS'
                )]) {
                    maskPasswords(
                        varPasswordPairs: [
                            [var: 'PUSER'],
                            [var: 'PPASS']
                        ],
                        varMaskRegexes: []
                    ) {
                        bat '''
                            if not exist "%PUB_CACHE%" mkdir "%PUB_CACHE%"

                            set PROXY_URL=http://%PUSER%:%PPASS%@%PROXY_HOST%:%PROXY_PORT%
                            set http_proxy=%PROXY_URL%
                            set https_proxy=%PROXY_URL%
                            set HTTP_PROXY=%PROXY_URL%
                            set HTTPS_PROXY=%PROXY_URL%
                            set no_proxy=%NO_PROXY_VALUE%
                            set NO_PROXY=%NO_PROXY_VALUE%

                            set ANDROID_HOME=%ANDROID_HOME%
                            set ANDROID_SDK_ROOT=%ANDROID_SDK_ROOT%
                            set PUB_CACHE=%PUB_CACHE%
                            set PUB_HOSTED_URL=%PUB_HOSTED_URL%
                            set FLUTTER_STORAGE_BASE_URL=%FLUTTER_STORAGE_BASE_URL%

                            call flutter precache --android
                        '''
                    }
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
                    maskPasswords(
                        varPasswordPairs: [
                            [var: 'PUSER'],
                            [var: 'PPASS']
                        ],
                        varMaskRegexes: []
                    ) {
                        dir("${env.FLUTTER_DIR}") {
                            bat '''
                                git config --global --add safe.directory C:/flutter/flutter
                                git config --global --add safe.directory C:/ProgramData/Jenkins/.jenkins/jobs/Company-Fullstack-App/workspace/HEG

                                set PROXY_URL=http://%PUSER%:%PPASS%@%PROXY_HOST%:%PROXY_PORT%
                                set http_proxy=%PROXY_URL%
                                set https_proxy=%PROXY_URL%
                                set HTTP_PROXY=%PROXY_URL%
                                set HTTPS_PROXY=%PROXY_URL%
                                set no_proxy=%NO_PROXY_VALUE%
                                set NO_PROXY=%NO_PROXY_VALUE%

                                set ANDROID_HOME=%ANDROID_HOME%
                                set ANDROID_SDK_ROOT=%ANDROID_SDK_ROOT%
                                set PUB_CACHE=%PUB_CACHE%
                                set PUB_HOSTED_URL=%PUB_HOSTED_URL%
                                set FLUTTER_STORAGE_BASE_URL=%FLUTTER_STORAGE_BASE_URL%

                                call flutter pub get
                                call flutter build apk --release
                            '''
                        }
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