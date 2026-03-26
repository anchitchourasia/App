pipeline {
    // Run on any available Jenkins agent (your PC)
    agent any

    environment {
        // These match the exact folder names in your GitHub repo
        FLUTTER_DIR = 'HEG'         
        BACKEND_DIR = 'backend'        
    }

    stages {
        // --- STAGE 1: Get the Code ---
        stage('Checkout') {
            steps {
                echo 'Checking out code from GitHub...'
                checkout scm
            }
        }

        // --- STAGE 2: Build Spring Boot Backend ---
        stage('Build Spring Boot Backend') {
            // 'when' ensures this only runs if backend files changed (saves time)
            when {
                changeset "${BACKEND_DIR}/**"
            }
            steps {
                dir("${env.BACKEND_DIR}") {
                    echo 'Building Spring Boot Backend...'
                    // Using Windows bat command to run Maven wrapper
                    bat 'mvnw.cmd clean package -DskipTests'
                }
            }
        }

        // --- STAGE 3: Build Flutter App ---
        stage('Build Flutter App') {
            // 'when' ensures this only runs if Flutter files changed
            when {
                changeset "${FLUTTER_DIR}/**"
            }
            steps {
                dir("${env.FLUTTER_DIR}") {
                    echo 'Fetching Flutter dependencies...'
                    bat 'flutter pub get'
                    
                    echo 'Building Android APK...'
                    bat 'flutter build apk --release'
                }
            }
        }

        // --- STAGE 4: Save Build Artifacts ---
        stage('Archive Artifacts') {
            steps {
                echo 'Saving the generated APK and Backend JAR...'
                // Save the Backend JAR file so you can download it from Jenkins
                archiveArtifacts artifacts: "${env.BACKEND_DIR}/target/*.jar", allowEmptyArchive: true
                
                // Save the Flutter APK file
                archiveArtifacts artifacts: "${env.FLUTTER_DIR}/build/app/outputs/flutter-apk/app-release.apk", allowEmptyArchive: true
            }
        }
    }

    // --- POST ACTIONS ---
    post {
        success {
            echo 'SUCCESS: Pipeline completed successfully!'
        }
        failure {
            echo 'FAILED: Pipeline failed. Please check the Jenkins Console Output for errors.'
        }
    }
}