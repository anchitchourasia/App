pipeline {
    agent any

    tools {
        maven 'Maven-3.9.12'
    }

    environment {
        FLUTTER_DIR = 'HEG'
        BACKEND_DIR = 'backend\\demo'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        stage('Build Spring Boot Backend') {
            steps {
                dir("${env.BACKEND_DIR}") {
                    echo 'Building Spring Boot Backend...'
                    bat 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Build Flutter App') {
            steps {
                dir("${env.FLUTTER_DIR}") {
                    echo 'Fetching Flutter dependencies...'
                    bat 'flutter pub get'
                    echo 'Building Android APK...'
                    bat 'flutter build apk --release'
                }
            }
        }

        stage('Archive Artifacts') {
            steps {
                echo 'Saving JAR and APK files...'
                archiveArtifacts artifacts: "${env.BACKEND_DIR}/target/*.jar", allowEmptyArchive: true
                archiveArtifacts artifacts: "${env.FLUTTER_DIR}/build/app/outputs/flutter-apk/app-release.apk", allowEmptyArchive: true
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Build completed successfully!'
        }
        failure {
            echo 'FAILED: Check Console Output for errors.'
        }
    }
}