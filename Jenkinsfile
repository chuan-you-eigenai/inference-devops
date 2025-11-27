pipeline {
  agent any

  environment {
    KUBE_CONFIG = credentials('kubeconfig-cred-id')
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Deploy Qwen3-8B-VL') {
      steps {
        sh '''
        export KUBECONFIG=$KUBE_CONFIG
        helm upgrade --install qwen3-8b-vl charts/sglang-model -n default -f values/qwen3-8b-vl.yaml
        '''
      }
    }

    stage('Deploy Qwen3-32B-VL') {
      steps {
        sh '''
        export KUBECONFIG=$KUBE_CONFIG
        helm upgrade --install qwen3-32b-vl charts/sglang-model -n default -f values/qwen3-32b-vl.yaml
        '''
      }
    }
  }
}
