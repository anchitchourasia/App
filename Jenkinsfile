pipeline {
    agent any

    stages {
        stage('Install Backend Dependencies') {
            steps {
                dir('backend') {
                    echo 'Installing backend dependencies...'
                    // Changed 'sh' to 'bat' for Windows
                    bat 'echo Installing backend...' 
                    // Example: bat 'npm install' or 'pip install -r requirements.txt'
                }
            }
        }

        stage('Build Flutter Frontend') {
            steps {
                dir('heg') {
                    echo 'Building Flutter app...'
                    // Changed 'sh' to 'bat' for Windows
                    bat 'echo Building Flutter...'
                    // Example: bat 'flutter build apk'
                }
            }
        }

        stage('Test') {
            steps {
                parallel(
                    "Backend Tests": {
                        dir('backend') { 
                            bat 'echo "Running backend tests..."' 
                        }
                    },
                    "Frontend Tests": {
                        dir('heg') { 
                            bat 'echo "Running flutter tests..."' 
                        }
                    }
                )
            }
        }
        stage('Install Backend Dependencies') {
            steps {
                dir('backend') {
                    // This replaces the placeholder echo
                    bat 'pip install -r requirements.txt'
                }
            }
        }

        stage('Build Flutter Frontend') {
            steps {
                dir('heg') {
                    // This fetches flutter packages and builds the APK
                    bat 'flutter pub get'
                    bat 'flutter build apk --release'
                }
            }
        }
    }
}