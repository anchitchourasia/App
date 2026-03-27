pipeline {
    agent any

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
                    // Use cmd /c to force Windows to find the file in the current directory
                    bat 'cmd /c mvnw.cmd clean package -DskipTests'
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
                echo 'Saving the generated APK and Backend JAR...'
                archiveArtifacts artifacts: "${env.BACKEND_DIR}/target/*.jar", allowEmptyArchive: true
                archiveArtifacts artifacts: "${env.FLUTTER_DIR}/build/app/outputs/flutter-apk/app-release.apk", allowEmptyArchive: true
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Pipeline completed successfully!'
        }
        failure {
            echo 'FAILED: Pipeline failed. Please check the Jenkins Console Output for errors.'
        }
    }
}