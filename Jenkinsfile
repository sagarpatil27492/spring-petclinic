pipeline{
    agent any

    tools {
        jdk 'jdk-8'
        maven 'maven-3.8'
        // tool we configured in jenkins we are providing there name here
    }
    environment {
        imageName = "sprint-service"
        dev= 'develop'
        blank= ''
        Tags= '$BUILD_NUMBER'
        dockerHubRegistry = 'sagarppatil27041992'
        versionTags= 'sprint-service:0.1.0'
    }
    
    stages{
        stage("Dev-build"){
            when {
                branch 'develop'    
            }
            steps{
               withMaven (maven:'maven-3.8') {
                   sh "mvn clean install -DskipTests"
                   // we package the artifact jar of our java project and skip all the test with maven goal "maven clean install -DskipTests"
               }
            }
        }
        stage("Dev-Unit test"){
            when {
                branch 'develop'   
            }
            options { skipDefaultCheckout() }
            steps{
               sh "mvn test"
               // here we perform all unit test cases
            }
        }
        stage("Dev-Integration test"){
            when {
                branch 'develop'   
            }
            options { skipDefaultCheckout() }
            steps{
               sh "mvn verify -DskipUnitTests"
               // here we perform all integration test with maven goal "mvn verify -DskipUnitTests" and skip again all unit test cases

            }
        }
        stage ("Dev-static code analysis"){
            when {
                branch 'develop'   
            }
            options { skipDefaultCheckout() }
            steps {
                sh "mvn checkstyle:checkstyle"
                // here we perform the checkstyle static code analysis with maven goal "mvn checkstyle:checkstyle"
            }
            post {
                success {
                    echo 'Generated Analysis Result'
                }
            }
        }
         stage('DEV-CODE ANALYSIS with SONARQUBE') {
            when {
                branch 'develop'   
            }
            options { skipDefaultCheckout() }
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

                // we ferform code analysis using sonarqube by passing the unit test cases result, checkstyle result for uploading and doing code analysis
              }
            timeout(time: 10, unit: 'MINUTES') {
               waitForQualityGate abortPipeline: true
               // here we wait for quality gates from sonar server
            }
          }
        }

        stage ("Dev-docker build") {
            when {
                branch 'develop'   
            }
            options { skipDefaultCheckout() }
            steps{
                imageBuild(dockerHubRegistry,dev,Tags) // calling image build function to build image for dev envoirment
            }
        }
        stage('Dev-Docker Publish') {
            when {
                branch 'develop'   
            }
            options { skipDefaultCheckout() }
            steps {
               withCredentials([usernamePassword(credentialsId: 'dockerHub', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
                pushToImage(dockerHubRegistry,env, dockerHubUser, dockerHubPassword,Tags) 
                // calling pushToImage function to push image for dev envoirment to dockerhub registry
                deleteImages(dockerHubRegistry,env,Tags) // remove the image once its pushed to dockerhub registry from local
                }
            }
        }

        stage('Dev-Deploy') {
            when {
                branch 'develop'   
            }
            options { skipDefaultCheckout() }
            steps {
               withCredentials([usernamePassword(credentialsId: 'dockerHub', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
                   sh "sudo docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
                   sh "sudo docker run -d --name java-app-develop-${env.BUILD_NUMBER}  -p 3001:8080 sagarppatil27041992/develop:'${env.BUILD_NUMBER}' "
                // we run the docker imaage  that we build in privious steps 

                }
            }
        }
        stage('Push GitTag') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([usernameColonPassword(credentialsId: 'github-cred', variable: 'github')]) {
                   sh  "git tag $versionTags"
                   sh "git push --tag"
                }
            }
        }
        stage ("build-docker build") {
            when {
                branch 'main'   
            }
            options { skipDefaultCheckout() }
            steps{
                // we build the docker image of our apllication and tageed that image with build no env variable
                //sh "sudo docker build -t sagarppatil27041992/develop:'${env.BUILD_NUMBER}' ."
                imageBuild(dockerHubRegistry,dev,imageName,Tags) // calling image build function
                
            }
        }
    }

}

// define function to build docker images
void imageBuild(registry,env,Tags) {
    
    sh "docker build --rm -t $registry/$env:$Tags --pull --no-cache . "
    echo "Image build complete"
}


// define function to push images
void pushToImage(registry,env, dockerUser, dockerPassword,Tags) {
    
    sh "docker login $registry -u $dockerUser -p $dockerPassword" 
    sh "sudo docker push $registry/$env:$Tags"
    echo "Image Push $registry/$env:$Tags completed"
}

void deleteImages(registry,env,Tags) {
    //sh "docker rmi $registry/$env$imageName:latest"
    sh "docker rmi $registry/$env:$Tags"
    echo "Images deleted"
}
