pipeline{
    agent any

    tools {
        jdk 'jdk-8'
        maven 'maven-3.8'
        // tool we configured in jenkins we are providing there name here
    }
    environment {
        imageName = "sprint-service"
        dev= 'dev-'
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
                //sh "sudo docker build -t sagarppatil27041992/develop:'${env.BUILD_NUMBER}' ."
                // we build the docker image of our apllication and tageed that image with build no env variable
                imageBuild(dockerHubRegistry,dev,imageName,Tags) // calling image build function
            }
        }
        stage('Dev-Docker Publish') {
            when {
                branch 'develop'   
            }
            options { skipDefaultCheckout() }
            steps {
               withCredentials([usernamePassword(credentialsId: 'dockerHub', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
                   sh "sudo docker login -u ${env.dockerHubUser} -p ${env.dockerHubPassword}"
                   // make a login to docker hub registry using docker credential
                   sh "sudo docker push sagarppatil27041992/develop:'${env.BUILD_NUMBER}' "
                // we push the docker image to dockerhub registry that we build in privious steps 
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
void imageBuild(registry,env,imageName,Tags) {
    
    sh "docker build --rm -t $registry/$env$imageName:$Tags --pull --no-cache . -f $imageName'Dockerfile'"
    echo "Image build complete"
}


// define function to push images
void pushToImage(registry,env,imageName, dockerUser, dockerPassword,Tags) {
    
    sh "docker login $registry -u $dockerUser -p $dockerPassword" 
    //sh "docker tag $env-$imageName:${BUILD_NUMBER} $registry/$env-$imageName:${BUILD_NUMBER}"
    //sh "docker tag $registry/$env$imageName:$Tags $registry/$env$imageName:latest"
    sh "docker push $registry/$env$imageName:$Tags"
    echo "Image Push $registry/$env$imageName:$Tags completed"
    //sh "docker push $registry/$env$imageName:latest"
    //echo "Image Push $registry/$env$imageName:latest completed"   
}

void deleteImages(registry,env,imageName,Tags) {
    //sh "docker rmi $registry/$env$imageName:latest"
    sh "docker rmi $registry/$env$imageName:$Tags"
    echo "Images deleted"
}
