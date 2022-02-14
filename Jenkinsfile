pipeline{
    agent any

    tools {
        jdk 'jdk-8'
        maven 'maven-3.8'
    }
    
    stages{
        stage("build"){
            steps{
               withMaven (maven:'maven-3.8') {
                   sh "mvn clean install -DskipTests"
               }
            }
        }
        stage("Unit test"){
            steps{
               sh "mvn test"
            }
        }
        stage("Integration test"){
            steps{
               sh "mvn verify -DskipUnitTests"
            }
        }
        stage ("static code analysis"){
            steps {
                sh "mvn checkstyle:checkstyle"
            }
            post {
                success {
                    echo 'Generated Analysis Result'
                }
            }
        }
         stage('CODE ANALYSIS with SONARQUBE') {
          environment {
             scannerHome = tool 'sonarscanner4'
            }
          steps {
             withSonarQubeEnv('sonar-qube') {
                 sh '''${scannerHome}/bin/sonar-scanner -Dsonar.projectKey=petclinic \
                   -Dsonar.projectName=petclinic \
                   -Dsonar.projectVersion=1.0 \
                   -Dsonar.sources=src/ \
                   -Dsonar.java.binaries=target/classes/ \
                   -Dsonar.junit.reportsPath=target/surefire-reports/ \
                   -Dsonar.jacoco.reportsPath=target/jacoco.exec \
                   -Dsonar.java.checkstyle.reportPaths=target/checkstyle-result.xml'''
              }
             timeout(time: 10, unit: 'MINUTES') {
               waitForQualityGate abortPipeline: true
             }
          }
        }

        stage ("docker build") {
            steps{
                sh "sudo docker build -t sagarppatil27041992/stage:'${env.BUILD_NUMBER}' ."
            }
        }
        stage('Docker Publish') {
           steps {
               withCredentials([usernamePassword(credentialsId: 'dockerHub', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
                   sh "sudo docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
                   sh "sudo docker push sagarppatil27041992/stage:'${env.BUILD_NUMBER}' "
                }
            }
        }

        stage('Deploy') {
           steps {
               withCredentials([usernamePassword(credentialsId: 'dockerHub', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
                   sh "sudo docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
                   sh "sudo docker run -d --name java-app-${env.BUILD_NUMBER}  -p 3000:80 sagarppatil27041992/stage:'${env.BUILD_NUMBER}' "
                }
            }
        }
    }

}
