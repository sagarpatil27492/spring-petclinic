pipeline{
    agent any

    tools {
        jdk 'jdk-8'
        maven 'maven-3.8'
        // tool we configured in jenkins we are providing there name here
    }
    environment {
        dev= 'develop'
        qa= 'main'
        staging='stage'
        Tags= '$BUILD_NUMBER'
        dockerHubRegistryID = 'sagarppatil27041992'
        versionTags= versiontags(Tags)
        //anchoreUrl = "http://localhost:8228/v1"
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

               // we perform code analysis using sonarqube by passing the unit test cases result, checkstyle result for uploading and doing code analysis
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
                imageBuild(dockerHubRegistryID,dev,Tags) // calling image build function to build image for dev environment
            }
        }
        stage('Dev-Docker Publish') {
            when {
                branch 'develop'   
            }
            options { skipDefaultCheckout() }
            steps {
               withCredentials([usernamePassword(credentialsId: 'dockerHub', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
                   
                    // calling pushToImage function to push image for dev environment to docker hub registry
                     pushToImage(dockerHubRegistryID,dev,dockerHubUser,dockerHubPassword,Tags)
                
                   // remove the image once its pushed to dockerhub registry from local
                    deleteImages(dockerHubRegistryID,dev,Tags) 

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
                   
                  // we run the docker image  that we build in previous steps by pulling it from docker hub registry
                    deploy(dockerHubRegistryID,dev,dockerHubUser,dockerHubPassword,Tags)
                }
            }
        }
        stage('Push GitTag') {
            when {
                branch 'main'
            }
            steps {
                withCredentials([gitUsernamePassword(credentialsId: 'github-cred', gitToolName: 'Default')]) {
                   sh  "git tag $versionTags"
                   // here we tag master branch
                   sh "git push origin $versionTags"
                   // here push the git tag
                }
            }
        }
        stage ("BuildDockerImage") {
            when {
                branch 'main'   
            }
            steps{
                withMaven (maven:'maven-3.8') {
                   sh "mvn clean install -DskipTests"
                   // we package the artifact jar of our java project and skip all the test with maven goal "maven clean install -DskipTests"
                }
                imageBuild(dockerHubRegistryID,qa,Tags) 
                // calling image build function for qa env
                
            }
        }
        //anchore engine security scanner
       /* stage('Anchore analyse') {
            when {
                branch 'main'
            }
            options { skipDefaultCheckout() }
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerHub', passwordVariable: 'dockerHubPassword', usernameVariable: 'dockerHubUser')]) {
                {
                sh "echo $registry/$qa:$Tags ${WORKSPACE}/Dockerfile > anchore_images"
                anchore name:'anchore_images', engineurl:"$anchoreUrl", engineCredentialsId:'anchore-engine', bailOnFail: false
                }
            }
        } */
    }

}

// define function to build docker images
void imageBuild(registry,env,Tags) {
    
    sh "sudo docker build --rm -t $registry/$env:$Tags --pull --no-cache . "
    echo "Image build complete"
}


// define function to push images
void pushToImage(registry,env,dockerUser,dockerPassword,Tags) {
    
    sh "sudo docker login -u $dockerUser -p $dockerPassword " 
    sh "sudo docker push $registry/$env:$Tags"
    echo "Image Push $registry/$env:$Tags completed"
}

// function to delete image from local

void deleteImages(registry,env,Tags) {

    sh "sudo docker rmi $registry/$env:$Tags"
    echo "Images deleted"
}

// function to deploy a container to an environment by pulling the image from docker hub registry
void deploy(registry,env,dockerUser,dockerPassword,Tags){
    sh "sudo docker login -u $dockerUser -p $dockerPassword "
    sh "sudo docker run -d --name java-app-$env-$Tags -p 3001:8080 $registry/$env:$Tags "   
}

// function to deploy a container to an environment by pulling the image from docker hub registry
void versiontags(Tags) {
    def tag= "Rleease-V-$Tags-0.0"
   return tag
}
