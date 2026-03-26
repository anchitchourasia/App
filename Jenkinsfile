pipeline {
    agent any

    stages {
        stage('Install Backend Dependencies') {
            steps {
                // Tells Jenkins to go into the 'backend' folder
                dir('backend') {
                    echo 'Installing backend dependencies...'
                    // Example: sh 'npm install' or 'pip install -r requirements.txt'
                }
            }
        }

        stage('Build Flutter Frontend') {
            steps {
                // Tells Jenkins to go into the 'heg' folder
                dir('heg') {
                    echo 'Building Flutter app...'
                    // Example: sh 'flutter build apk'
                }
            }
        }

        stage('Test') {
            steps {
                parallel(
                    "Backend Tests": {
                        dir('backend') { sh 'echo "Running backend tests..."' }
                    },
                    "Frontend Tests": {
                        dir('heg') { sh 'echo "Running flutter tests..."' }
                    }
                )
            }
        }
    }
}