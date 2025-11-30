pipeline {
  agent any

  environment {
    KUBECONFIG_CREDENTIAL_ID = 'kubeconfig-admin'
    HF_TOKEN = credentials('hf-token-plain')
  }

  stages {
    stage('Init Env') {
      steps {
        script {
          env.BRANCH_SLUG = (env.BRANCH_NAME ?: 'unknown')
            .replaceAll('[^a-zA-Z0-9-]+', '-')

          def isMain = (env.BRANCH_NAME == 'main')

          def changedFiles = sh(
            script: 'git diff --name-only HEAD~1 HEAD || true',
            returnStdout: true
          ).trim().split('\n') as List<String>

          def changedValues = changedFiles.findAll { it.startsWith('values/') && (it.endsWith('.yaml') || it.endsWith('.yml')) }

          env.CHANGED_VALUES = changedValues.join(',')

          if (!isMain && changedValues.size() == 0) {
            env.HELM_CHANGED = 'false'
          } else {
            env.HELM_CHANGED = 'true'
          }

          echo "BRANCH_NAME=${env.BRANCH_NAME}, BRANCH_SLUG=${env.BRANCH_SLUG}"
          echo "CHANGED_VALUES=${env.CHANGED_VALUES}"
          echo "HELM_CHANGED=${env.HELM_CHANGED}"
        }
      }
    }

    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('Helm Lint') {
      when {
        expression { env.HELM_CHANGED == 'true' }
      }
      steps {
        container('base') {
          sh '''
          set -e

          if ! helm version --short 2>/dev/null | grep -q "v3"; then
            echo "Helm v3 not found, installing local Helm 3 client..."
            curl -sSL https://get.helm.sh/helm-v3.16.0-linux-amd64.tar.gz -o /tmp/helm3.tgz
            tar -C /tmp -xzf /tmp/helm3.tgz
            export PATH="/tmp/linux-amd64:$PATH"
          fi

          helm version || true

          helm lint charts/sglang-model
          '''
        }
      }
    }

    stage('Deploy to TEST (non-main branches)') {
      when {
        allOf {
          not { branch 'main' }
          expression { env.HELM_CHANGED == 'true' }
        }
      }
      steps {
        container('base') {
          withCredentials([
            kubeconfigFile(
              credentialsId: env.KUBECONFIG_CREDENTIAL_ID,
              variable: 'KUBECONFIG'
            ),
            usernamePassword(
              credentialsId: 'dockerhub-regcred',
              usernameVariable: 'DOCKERHUB_USERNAME',
              passwordVariable: 'DOCKERHUB_PASSWORD'
            )
          ]) {
            sh """
            set -e

            if [ -z "\$CHANGED_VALUES" ]; then
              echo "No changed values files, skip TEST deploy."
              exit 0
            fi

            TEST_NS=sglang-test-${BRANCH_SLUG}
            echo "Ensuring namespace: \$TEST_NS"
            kubectl get ns "\$TEST_NS" >/dev/null 2>&1 || kubectl create ns "\$TEST_NS"

            echo "Ensuring HF token Secret in \$TEST_NS"
            kubectl -n "\$TEST_NS" create secret generic hf-token \
              --from-literal=token="${HF_TOKEN}" \
              --dry-run=client -o yaml | kubectl apply -f -

            echo "Ensuring image pull secret in \$TEST_NS"
            kubectl -n "\$TEST_NS" create secret docker-registry regcred \
              --docker-server=https://index.docker.io/v1/ \
              --docker-username="\$DOCKERHUB_USERNAME" \
              --docker-password="\$DOCKERHUB_PASSWORD" \
              --dry-run=client -o yaml | kubectl apply -f -

            IFS=',' read -r -a VALUE_FILES <<< "\$CHANGED_VALUES"

            for v in "\${VALUE_FILES[@]}"; do
              echo "Deploying for values file: \$v"
              base=\$(basename "\$v")
              base="\${base%.*}"

              release="\${base}-${BRANCH_SLUG}"

              echo "Release name: \$release"

              /tmp/linux-amd64/helm upgrade --install "\$release" charts/sglang-model \
                --namespace "\$TEST_NS" \
                -f "\$v" \
                --set replicaCount=1 \
                --set keda.enabled=false
            done
            """
          }
        }
      }
    }

    stage('Wait TEST rollout') {
      when {
        allOf {
          not { branch 'main' }
          expression { env.HELM_CHANGED == 'true' }
        }
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
            set -e

            if [ -z "\$CHANGED_VALUES" ]; then
              echo "No changed values files, skip wait."
              exit 0
            fi

            TEST_NS=sglang-test-${BRANCH_SLUG}
            IFS=',' read -r -a VALUE_FILES <<< "\$CHANGED_VALUES"

            for v in "\${VALUE_FILES[@]}"; do
              base=\$(basename "\$v")
              base="\${base%.*}"
              release="\${base}-${BRANCH_SLUG}"
              deployName="\${release}-sglang-model"

              echo "Waiting for rollout of deployment: \$deployName in namespace: \$TEST_NS"

              kubectl -n "\$TEST_NS" rollout status deploy "\$deployName" --timeout=20m
            done

            kubectl -n "\$TEST_NS" get pods -o wide || true
            """
          }
        }
      }
    }

    stage('Cleanup TEST env (manual)') {
      when {
        allOf {
          not { branch 'main' }
          expression { env.HELM_CHANGED == 'true' }
        }
      }
      steps {
        input(
          id: 'cleanup-test-env',
          message: "Clean up TEST namespace for branch ${BRANCH_SLUG} ?",
          ok: 'Yes, delete namespace'
        )
        container('base') {
          withCredentials([
            kubeconfigFile(
              credentialsId: env.KUBECONFIG_CREDENTIAL_ID,
              variable: 'KUBECONFIG'
            )
          ]) {
            sh """
            set -e

            TEST_NS=sglang-test-${BRANCH_SLUG}
            echo "Deleting TEST namespace: \$TEST_NS"

            kubectl delete ns "\$TEST_NS" || true
            """
          }
        }
      }
    }
  }
}