pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Select environment')
        choice(name: 'ACTION', choices: ['plan', 'apply'], description: 'Terraform Action')
    }

    environment {
        AWS_REGION = "us-east-1"
        SCRIPTS_DIR = "terraform/scripts"
    }

    stages {

        stage('Checkout Code') {
            steps {
                echo "✅ Checking out repository..."
                checkout scm
            }
        }

        stage('Terraform Validate') {
            steps {
                script {
                    echo "🧪 Validating Terraform for ENV: ${params.ENV}"
                    sh """
                        chmod +x ${SCRIPTS_DIR}/validate.sh
                        ${SCRIPTS_DIR}/validate.sh ${params.ENV}
                    """
                }
            }
        }

        stage('Terraform Plan') {
            when { expression { params.ACTION == "plan" } }
            steps {
                script {
                    echo "📘 Terraform PLAN for: ${params.ENV}"
                    sh """
                        chmod +x ${SCRIPTS_DIR}/plan.sh
                        ${SCRIPTS_DIR}/plan.sh ${params.ENV}
                    """
                }
            }
        }

        stage('Approval for Apply') {
            when { 
                expression { params.ACTION == "apply" && params.ENV != 'dev' }
            }
            steps {
                script {
                    echo "⚠️ Manual approval required for ${params.ENV}"
                }
                input message: "Deploy to ${params.ENV}? Confirm to proceed!"
            }
        }

        stage('Terraform Apply') {
            when { expression { params.ACTION == "apply" } }
            steps {
                script {
                    echo "🚀 Terraform APPLY for: ${params.ENV}"
                    sh """
                        chmod +x ${SCRIPTS_DIR}/apply.sh
                        ${SCRIPTS_DIR}/apply.sh ${params.ENV}
                    """
                }
            }
        }

        stage('Helm Deploy to EKS') {
            when { expression { params.ACTION == "apply" } }
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
                                  credentialsId: 'aws-credentials']]) {

                    sh """
                        echo "⚙️ Using AWS Credentials inside Helm stage"
                        export KUBECONFIG=/var/lib/jenkins/.kube/config

                        echo "📡 Updating kubeconfig for EKS..."
                        aws eks update-kubeconfig --name ${params.ENV}-eks --region ${AWS_REGION} --kubeconfig \$KUBECONFIG

                        echo "⛵ Deploying Helm chart..."
                        helm upgrade --install app \
                          ./helm/app \
                          -f ./helm/app/values-{params.ENV}.yaml \
                          --namespace default
                    """
                }
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully for ${params.ENV}"
        }
        failure {
            echo "❌ Pipeline FAILED for ${params.ENV}"
        }
    }
}
