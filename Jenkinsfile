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

            TEST_NS=sglang-test-${BRANCH_SLUG}
            echo "Ensuring namespace: \$TEST_NS"
            kubectl get ns "\$TEST_NS" >/dev/null 2>&1 || kubectl create ns "\$TEST_NS"

            echo "Deploying TEST env for branch ${BRANCH_SLUG} ..."

            helm upgrade --install qwen3-8b-vl-${BRANCH_SLUG} charts/sglang-model \
              --namespace "\$TEST_NS" \
              -f values/qwen3-8b-vl.yaml

            helm upgrade --install qwen3-32b-vl-${BRANCH_SLUG} charts/sglang-model \
              --namespace "\$TEST_NS" \
              -f values/qwen3-32b-vl.yaml
            """
          }
        }
      }
    }

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

    stage('Cleanup TEST env (manual)') {
      when {
        not { branch 'main' }
      }
      steps {
        input(
          id: 'cleanup-test-env',
          message: "Clean up TEST env for branch ${BRANCH_SLUG} ?",
          ok: 'Yes, delete it'
        )
        container('base') {
          withCredentials([
            kubeconfigFile(
              credentialsId: env.KUBECONFIG_CREDENTIAL_ID,
              variable: 'KUBECONFIG'
            )
          ]) {
            sh """
            echo "Using KUBECONFIG at: \$KUBECONFIG"
            TEST_NS=sglang-test-${BRANCH_SLUG}
            echo "Cleaning up TEST namespace: \$TEST_NS"

            helm uninstall qwen3-8b-vl-${BRANCH_SLUG} --namespace "\$TEST_NS" || true
            helm uninstall qwen3-32b-vl-${BRANCH_SLUG} --namespace "\$TEST_NS" || true

            kubectl delete ns "\$TEST_NS" || true
            """
          }
        }
      }
    }
  }
}