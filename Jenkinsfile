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

        stage('Verify AWS Identity') {
            steps {
                sh '''
                    echo "=== Current AWS Identity ==="
                    aws sts get-caller-identity
                    echo "=== Should show eks-admin-role, NOT root ==="
                '''
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
                sh """
                    echo "⚙️ Using IAM role for Helm deployment"
                    export KUBECONFIG=/var/lib/jenkins/.kube/config

                    echo "📡 Updating kubeconfig for EKS..."
                    aws eks update-kubeconfig --name ${params.ENV}-eks --region ${AWS_REGION} --kubeconfig \$KUBECONFIG

                    echo "🔍 Verifying kubectl access..."
                    kubectl get nodes
                    kubectl get namespaces

                    echo "⛵ Deploying Helm chart..."
                    helm upgrade --install app \
                      ./helm/app \
                      -f ./helm/app/values-${params.ENV}.yaml \
                      --namespace default \
                      --create-namespace
                """
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
