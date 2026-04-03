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

        stage('Auto-Setup EKS Access') {
            when { expression { params.ACTION == "apply" } }
            steps {
                script {
                    sh '''
                        CLUSTER_NAME="${ENV}-eks"
                        ROLE_ARN="arn:aws:iam::941960167356:role/eks-admin-role"
                        
                        echo "=== Checking EKS access for $CLUSTER_NAME ==="
                        
                        # Test if kubectl already works
                        if aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION >/dev/null 2>&1 && kubectl get nodes >/dev/null 2>&1; then
                            echo "✅ kubectl access already working for $CLUSTER_NAME"
                            exit 0
                        fi
                        
                        echo "⚙️ kubectl access not working, setting up automatically..."
                        
                        # Check if cluster exists
                        if ! aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION >/dev/null 2>&1; then
                            echo "❌ Cluster $CLUSTER_NAME does not exist yet"
                            echo "This is normal if Terraform hasn't created it yet"
                            exit 0
                        fi
                        
                        # Check authentication mode
                        AUTH_MODE=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query 'cluster.accessConfig.authenticationMode' --output text 2>/dev/null || echo "CONFIG_MAP")
                        echo "Current authentication mode: $AUTH_MODE"
                        
                        # Handle different authentication modes
                        if [ "$AUTH_MODE" = "CONFIG_MAP" ]; then
                            echo "🔄 Updating cluster to API_AND_CONFIG_MAP mode..."
                            aws eks update-cluster-config \
                                --name $CLUSTER_NAME \
                                --region $AWS_REGION \
                                --access-config authenticationMode=API_AND_CONFIG_MAP
                            
                            echo "⏳ Waiting for authentication mode update..."
                            # Wait for update to complete (with timeout)
                            for i in {1..30}; do
                                sleep 30
                                STATUS=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query 'cluster.status' --output text)
                                AUTH_MODE=$(aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION --query 'cluster.accessConfig.authenticationMode' --output text)
                                echo "Attempt $i/30: Status=$STATUS, AuthMode=$AUTH_MODE"
                                
                                if [ "$STATUS" = "ACTIVE" ] && [ "$AUTH_MODE" != "CONFIG_MAP" ]; then
                                    echo "✅ Authentication mode update completed"
                                    break
                                fi
                                
                                if [ $i -eq 30 ]; then
                                    echo "❌ Timeout waiting for authentication mode update"
                                    exit 1
                                fi
                            done
                        fi
                        
                        # Create access entry if cluster supports API mode
                        if [ "$AUTH_MODE" = "API" ] || [ "$AUTH_MODE" = "API_AND_CONFIG_MAP" ]; then
                            echo "🔑 Creating access entry..."
                            aws eks create-access-entry \
                                --cluster-name $CLUSTER_NAME \
                                --principal-arn $ROLE_ARN \
                                --type STANDARD 2>/dev/null || echo "Access entry already exists"
                            
                            echo "🛡️ Associating admin policy..."
                            aws eks associate-access-policy \
                                --cluster-name $CLUSTER_NAME \
                                --principal-arn $ROLE_ARN \
                                --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
                                --access-scope type=cluster 2>/dev/null || echo "Policy already associated"
                            
                            # Test access
                            echo "🧪 Testing kubectl access..."
                            aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
                            kubectl get nodes
                            kubectl get namespaces
                            echo "✅ EKS access setup completed successfully!"
                        fi
                    '''
                }
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
