pipeline {
    agent any


    options {
        skipDefaultCheckout()
        timeout(time: 45, unit: 'MINUTES')
    }


    environment {
        FLUTTER_DIR = 'HEG'
        BACKEND_DIR = 'backend\\demo'


        MVN_CMD      = 'C:\\Users\\heg\\.m2\\wrapper\\dists\\apache-maven-3.9.12\\59fe215c0ad6947fea90184bf7add084544567b927287592651fda3782e0e798\\bin\\mvn.cmd'
        MVN_SETTINGS = 'C:\\Users\\heg\\.m2\\settings.xml'


        PROXY_HOST     = '192.168.9.112'
        PROXY_PORT     = '808'
        NO_PROXY_VALUE = 'localhost,127.0.0.1,::1'


        ANDROID_HOME     = 'C:\\Users\\heg\\AppData\\Local\\Android\\Sdk'
        ANDROID_SDK_ROOT = 'C:\\Users\\heg\\AppData\\Local\\Android\\Sdk'
        PUB_CACHE        = 'C:\\flutter\\.pub-cache'


        DOCKER_IMAGE = 'heg-backend'
        DOCKER_TAG   = "build-${BUILD_NUMBER}"
    }


    stages {


        stage('Checkout') {
            steps {
                deleteDir()
                checkout scm
            }
        }


        stage('Build Spring Boot Backend') {
            steps {
                dir("${env.BACKEND_DIR}") {
                    bat "\"%MVN_CMD%\" -s \"%MVN_SETTINGS%\" clean verify -U"
                }
            }
        }


        stage('Build Flutter App') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'proxy-creds',
                        usernameVariable: 'PUSER',
                        passwordVariable: 'PPASS'
                    ),
                    file(
                        credentialsId: 'flutter-dotenv',
                        variable: 'DOTENV_FILE'
                    )
                ]) {
                    dir("${env.FLUTTER_DIR}") {
                        bat '''
@echo on


if not exist "%PUB_CACHE%" mkdir "%PUB_CACHE%"


git config --global --add safe.directory C:/flutter/flutter
git config --global --add safe.directory C:/ProgramData/Jenkins/.jenkins/jobs/Company-Fullstack-App/workspace/HEG


echo Copying .env to assets folder...
if not exist "assets" mkdir "assets"
copy /Y "%DOTENV_FILE%" "assets\\.env"
if errorlevel 1 (
    echo FAILED to copy .env file
    exit /b 1
)
echo .env copied successfully


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


echo ==== EFFECTIVE ENV ====
echo http_proxy=%http_proxy%
echo https_proxy=%https_proxy%
echo no_proxy=%no_proxy%
echo ANDROID_HOME=%ANDROID_HOME%
echo ANDROID_SDK_ROOT=%ANDROID_SDK_ROOT%
echo PUB_CACHE=%PUB_CACHE%


echo ==== START flutter doctor ====
call flutter doctor -v
if errorlevel 1 exit /b 1


echo ==== START flutter clean ====
call flutter clean
if errorlevel 1 exit /b 1


echo ==== START flutter pub get ====
call flutter pub get -v
if errorlevel 1 exit /b 1


echo ==== START flutter build apk ====
call flutter build apk --release -v
if errorlevel 1 exit /b 1


if not exist "build\\app\\outputs\\flutter-apk\\app-release.apk" (
    echo APK_NOT_FOUND
    exit /b 1
)


echo APK_FOUND
'''
                    }
                }
            }
        }


        stage('Copy Dependencies') {
            steps {
                dir("${env.BACKEND_DIR}") {
                    bat "\"%MVN_CMD%\" -s \"%MVN_SETTINGS%\" dependency:copy-dependencies -DoutputDirectory=target/dependency -q"
                }
            }
        }


        stage('SonarQube Analysis - Backend') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'
                    withSonarQubeEnv('SonarQube') {
                        dir("${env.BACKEND_DIR}") {
                            withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                                bat """
                                    "${scannerHome}\\bin\\sonar-scanner.bat" ^
                                    -Dsonar.projectKey=HEG-HRMS ^
                                    -Dsonar.projectName=HEG-HRMS ^
                                    -Dsonar.host.url=http://localhost:9000 ^
                                    -Dsonar.token=%SONAR_TOKEN% ^
                                    -Dsonar.sources=src/main/java ^
                                    -Dsonar.java.binaries=target/classes ^
                                    -Dsonar.java.libraries=target/dependency ^
                                    -Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
                                """
                            }
                        }
                    }
                }
            }
        }


        // ✅ UPDATED: Docker Build with proxy build args
        stage('Docker Build - Backend') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'proxy-creds',
                        usernameVariable: 'PUSER',
                        passwordVariable: 'PPASS'
                    )
                ]) {
                    dir("${env.BACKEND_DIR}") {
                        bat """
                            echo ====== Building Docker Image ======
                            docker build ^
                              --build-arg HTTP_PROXY=http://%PUSER%:%PPASS%@%PROXY_HOST%:%PROXY_PORT% ^
                              --build-arg HTTPS_PROXY=http://%PUSER%:%PPASS%@%PROXY_HOST%:%PROXY_PORT% ^
                              --build-arg NO_PROXY=%NO_PROXY_VALUE% ^
                              -t %DOCKER_IMAGE%:%DOCKER_TAG% .
                            docker tag %DOCKER_IMAGE%:%DOCKER_TAG% %DOCKER_IMAGE%:latest
                            echo ====== Docker Build Done ======
                        """
                    }
                }
            }
        }
        stage('Docker Run - Backend') {
            steps {
                dir("${env.BACKEND_DIR}") {
                   bat """
                       echo ====== Starting Backend Container ======
                       docker compose down --remove-orphans
                       docker compose up -d
                       echo ====== Backend Container Started ======
                    """
                }
            }
        }
        // ✅ Docker Verify - unchanged
        stage('Docker Verify - Backend') {
            steps {
                bat """
                    echo ====== Verifying Docker Image ======
                    docker images %DOCKER_IMAGE%
                    echo ====== Docker Image Verified ======
                """
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
            echo 'SUCCESS: Backend JAR, Flutter APK, and Docker image built successfully!'
        }
        failure {
            echo 'FAILED: Check Console Output for errors.'
        }
        always {
            echo 'Pipeline finished.'
        }
    }
}