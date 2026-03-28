pipeline {
    agent any

    environment {
        FLUTTER_DIR = 'HEG'
        BACKEND_DIR = 'backend\\demo'
        MVN_CMD = 'C:\\Users\\heg\\.m2\\wrapper\\dists\\apache-maven-3.9.12\\59fe215c0ad6947fea90184bf7add084544567b927287592651fda3782e0e798\\bin\\mvn.cmd'
        MVN_SETTINGS = 'C:\\Users\\heg\\.m2\\settings.xml'

        HTTP_PROXY = 'http://192.168.9.112:8080'
        HTTPS_PROXY = 'http://192.168.9.112:8080'
        http_proxy = 'http://192.168.9.112:8080'
        https_proxy = 'http://192.168.9.112:8080'
        NO_PROXY = 'localhost,127.0.0.1,::1'

        PUB_HOSTED_URL = 'https://pub.flutter-io.cn'
        FLUTTER_STORAGE_BASE_URL = 'https://storage.flutter-io.cn'
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
                bat 'git config --global --add safe.directory C:/flutter/flutter'
                bat 'git config --global --add safe.directory C:/ProgramData/Jenkins/.jenkins/jobs/Company-Fullstack-App/workspace/HEG'
                dir("${env.FLUTTER_DIR}") {
                    bat 'flutter doctor -v'
                    bat 'flutter pub get'
                    bat 'flutter build apk --release'
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: "${env.BACKEND_DIR}/target/*.jar", allowEmptyArchive: true
                archiveArtifacts artifacts: "${env.FLUTTER_DIR}/build/app/outputs/flutter-apk/app-release.apk", allowEmptyArchive: true
            }
        }
    }
}