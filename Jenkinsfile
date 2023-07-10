pipeline {
    agent any

    environment {
    region = "us-east-1"
    repo_name="my-app"
    tag="latest"
    repo_uri = "499632135972.dkr.ecr.us-east-1.amazonaws.com/${repo_name}"
    }

    stages {
        stage('Test') {
            steps {
                sh '''
                cd visitors_count
                pip install -r requirements.txt
                python3 -m pytest'''
            }
        }

        stage('Terraform') {
            steps {
                withCredentials([
                    aws(
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh '''
                        cd terraform
                        terraform init
                        terraform apply -auto-approve
                        '''
                    }
            }
        }

        stage('Build and push to ECR') {
            steps {
                withCredentials([
                    aws(
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh 'cd visitors_count'
                        sh "aws ecr get-login-password --region ${region} | docker login --username AWS --password-stdin ${repo_uri}"
                        sh 'docker build --no-cache -t my-app ./visitors_count'
                        sh "docker tag ${env.repo_name}:${env.tag} ${env.repo_uri}:${env.tag}"
                        sh "docker push ${env.repo_uri}:${env.tag}"
                    }
            }
        }

        stage('update lambda') {
            steps {
                withCredentials([
                    aws(
                    credentialsId: 'aws-credentials',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                        sh "aws lambda update-function-code --function-name visitor_count --image-uri ${env.repo_uri}:${env.tag} --region ${env.region}"
                    }
            }
        }
    }
}