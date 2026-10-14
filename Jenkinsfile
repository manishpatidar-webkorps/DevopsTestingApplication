
pipeline {
    agent { label 'dev' }

    stages {
        stage("Clone") {
            steps {
                git url: "https://github.com/manishpatidar-webkorps/DevopsTestingApplication.git",
                    branch: "main"
            }
        }

        stage("Test cases is run") {
            steps {
                echo "Here test cases is run"
            }
        }

        // stage("Docker build and push") {
        //     steps {
        //         withCredentials([
        //             usernamePassword(
        //                 credentialsId: "dockerhubCred",
        //                 usernameVariable: "dockerHubUser",
        //                 passwordVariable: "dockerHubPass"
        //             )
        //         ]) {
        //             sh '''
        //                 set -eu

        //                 echo "$dockerHubPass" | docker login \
        //                     -u "$dockerHubUser" --password-stdin

        //                 docker buildx build \
        //                     --platform linux/amd64 \
        //                     -t "$dockerHubUser/my-app:latest" \
        //                     --push \
        //                     .
        //             '''
        //         }
        //     }
        // }
        stage("Docker build and push") {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: "dockerhubCred",
                        usernameVariable: "dockerHubUser",
                        passwordVariable: "dockerHubPass"
                    )
                ]) {
                   sh ' echo "$dockerHubPass" | docker login -u "$dockerHubUser" --password-stdin'
                    sh 'docker build -t "$dockerHubUser/my-app:latest" .'
                    sh 'docker push "$dockerHubUser/my-app:latest" '
                }
            }
        }
    }

    post {
        always {
            sh 'docker image rm my-app || true'
            sh 'docker image prune -f'
        }
    }
}
