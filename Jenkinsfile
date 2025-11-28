pipeline {
  agent any

  environment {
    KUBECONFIG_CREDENTIAL_ID = 'kubeconfig-admin'
  }

  stages {
    stage('Init Env') {
      steps {
        script {
          env.BRANCH_SLUG = (env.BRANCH_NAME ?: 'unknown')
            .replaceAll('[^a-zA-Z0-9-]+', '-')
          echo "BRANCH_NAME=${env.BRANCH_NAME}, BRANCH_SLUG=${env.BRANCH_SLUG}"
        }
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Helm Lint') {
      steps {
        container('base') {
          sh '''
          helm lint charts/sglang-model
          '''
        }
      }
    }

    /************ 非 main 分支：只部署 TEST ************/
    stage('Deploy to TEST (non-main branches)') {
      when {
        not { branch 'main' }
      }
      steps {
        container('base') {
          withCredentials([
            kubeconfigFile(
              credentialsId: env.KUBECONFIG_CREDENTIAL_ID,
              variable: 'KUBECONFIG'
            )
          ]) {
            sh """
            echo "Using KUBECONFIG at: \$KUBECONFIG"
            kubectl config current-context || true

            echo "Deploying TEST env for branch ${BRANCH_SLUG} ..."

            # 8B TEST
            helm upgrade --install qwen3-8b-vl-${BRANCH_SLUG} charts/sglang-model \
              --namespace sglang-test-${BRANCH_SLUG} \
              --create-namespace \
              -f values/qwen3-8b-vl.yaml

            # 32B TEST
            helm upgrade --install qwen3-32b-vl-${BRANCH_SLUG} charts/sglang-model \
              --namespace sglang-test-${BRANCH_SLUG} \
              --create-namespace \
              -f values/qwen3-32b-vl.yaml
            """
          }
        }
      }
    }

    /************ main 分支：部署 PROD ************/
    stage('Deploy Qwen3-8B-VL (PROD)') {
      when {
        branch 'main'
      }
      steps {
        container('base') {
          withCredentials([
            kubeconfigFile(
              credentialsId: env.KUBECONFIG_CREDENTIAL_ID,
              variable: 'KUBECONFIG'
            )
          ]) {
            sh '''
            echo "Using KUBECONFIG at: $KUBECONFIG"
            kubectl config current-context || true

            echo "Deploying Qwen3-8B-VL to PROD (namespace: default)..."
            helm upgrade --install qwen3-8b-vl charts/sglang-model \
              --namespace default \
              -f values/qwen3-8b-vl.yaml
            '''
          }
        }
      }
    }

    stage('Deploy Qwen3-32B-VL (PROD)') {
      when {
        branch 'main'
      }
      steps {
        container('base') {
          withCredentials([
            kubeconfigFile(
              credentialsId: env.KUBECONFIG_CREDENTIAL_ID,
              variable: 'KUBECONFIG'
            )
          ]) {
            sh '''
            echo "Using KUBECONFIG at: $KUBECONFIG"
            kubectl config current-context || true

            echo "Deploying Qwen3-32B-VL to PROD (namespace: default)..."
            helm upgrade --install qwen3-32b-vl charts/sglang-model \
              --namespace default \
              -f values/qwen3-32b-vl.yaml
            '''
          }
        }
      }
    }
  }
}