pipeline {
    agent any

    stages {
        stage('Install Backend') {
            steps {
                dir('backend') {
                    echo 'Installing Python dependencies...'
                    // Ensure requirements.txt exists in your backend folder
                    bat 'pip install -r requirements.txt'
                }
            }
        }

        stage('Build Flutter') {
            steps {
                dir('heg') {
                    echo 'Fetching Flutter packages and building APK...'
                    bat 'flutter pub get'
                    bat 'flutter build apk --release'
                }
            }
        }

        stage('Parallel Tests') {
            steps {
                parallel(
                    "Backend Check": {
                        dir('backend') { 
                            // Runs your python tests
                            bat 'pytest' 
                        }
                    },
                    "Flutter Check": {
                        dir('heg') { 
                            // Runs flutter unit tests
                            bat 'flutter test' 
                        }
                    }
                )
            }
        }
    }

    post {
        success {
            echo 'Build Successful! Archiving APK...'
            // This makes the APK available for download in the Jenkins UI
            archiveArtifacts artifacts: 'heg/build/app/outputs/flutter-apk/app-release.apk', fingerprint: true
        }
    }
}