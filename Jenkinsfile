pipeline {
    agent any

    stages {
        stage('Install Backend') {
            steps {
                dir('backend') {
                    echo 'Installing backend dependencies...'
                    bat 'echo RUN_BACKEND_INSTALL_COMMAND_HERE'
                }
            }
        }

        stage('Build Flutter') {
            steps {
                dir('heg') {
                    echo 'Building Flutter frontend...'
                    bat 'echo RUN_FLUTTER_BUILD_COMMAND_HERE'
                }
            }
        }

        stage('Parallel Tests') {
            steps {
                parallel(
                    "Backend Check": {
                        dir('backend') { bat 'echo Testing Backend...' }
                    },
                    "Flutter Check": {
                        dir('heg') { bat 'echo Testing Flutter...' }
                    }
                )
            }
        }
    }
}