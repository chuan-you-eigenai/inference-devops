pipeline {
  agent {
    node {
      label 'base'
    }
  }

  environment {
    KUBECONFIG_CREDENTIAL_ID = 'kubeconfig-admin'
  }

  stages {
    stage('Init Env') {
      steps {
        script {
          env.BRANCH_SLUG = (env.BRANCH_NAME ?: 'main').replaceAll('[^a-zA-Z0-9-]+', '-')
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
        sh '''
        helm lint charts/sglang-model
        '''
      }
    }

    /************ 非 main 分支：只部署到测试环境 ************/
    stage('Deploy to TEST (non-main branches)') {
      when {
        not { branch 'main' }
      }
      steps {
        withKubeConfig([credentialsId: env.KUBECONFIG_CREDENTIAL_ID]) {
          sh """
          echo "Deploying TEST env for branch ${BRANCH_SLUG} ..."

          # 8B 测试部署
          helm upgrade --install qwen3-8b-vl-${BRANCH_SLUG} charts/sglang-model \
            -n sglang-test-${BRANCH_SLUG} \
            --create-namespace \
            -f values/qwen3-8b-vl.yaml

          # 32B 测试部署
          helm upgrade --install qwen3-32b-vl-${BRANCH_SLUG} charts/sglang-model \
            -n sglang-test-${BRANCH_SLUG} \
            --create-namespace \
            -f values/qwen3-32b-vl.yaml
          """
        }
      }
    }

    /************ main 分支：部署到线上 default ************/
    stage('Deploy Qwen3-8B-VL (PROD)') {
      when {
        branch 'main'
      }
      steps {
        withKubeConfig([credentialsId: env.KUBECONFIG_CREDENTIAL_ID]) {
          sh '''
          echo "Deploying Qwen3-8B-VL to PROD (namespace: default)..."
          helm upgrade --install qwen3-8b-vl charts/sglang-model \
            -n default \
            -f values/qwen3-8b-vl.yaml
          '''
        }
      }
    }

    stage('Deploy Qwen3-32B-VL (PROD)') {
      when {
        branch 'main'
      }
      steps {
        withKubeConfig([credentialsId: env.KUBECONFIG_CREDENTIAL_ID]) {
          sh '''
          echo "Deploying Qwen3-32B-VL to PROD (namespace: default)..."
          helm upgrade --install qwen3-32b-vl charts/sglang-model \
            -n default \
            -f values/qwen3-32b-vl.yaml
          '''
        }
      }
    }
  }
}