#!/usr/bin/env bash
set -Eeuo pipefail

# Återställer Team 3:s Kubernetes-plattform på nya primary.
# Kör på team3-primary: sudo ./scripts/bootstrap-primary-k3s.sh

if [[ ${EUID} -ne 0 ]]; then
  echo "Kör skriptet med sudo." >&2
  exit 1
fi

PRIMARY_IP="${PRIMARY_IP:-10.0.3.3}"
APP_REPO="ITSX25-Chas/Team3-ThaCompany"
APP_IMAGE="ghcr.io/itsx25-chas/team3-thacompany"
WORKFLOW_IDENTITY="^https://github.com/ITSX25-Chas/Team3-ThaCompany/.github/workflows/deploy.yml@refs/heads/main$"
TARGET_USER="${SUDO_USER:-root}"
TARGET_GROUP="$(id -gn "${TARGET_USER}")"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
KUBECONFIG_OUTPUT="${TARGET_HOME}/team3-kubeconfig.b64"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

echo "[1/7] Installerar grundpaket"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y curl git gpg apt-transport-https ca-certificates

if ! command -v k3s >/dev/null 2>&1; then
  echo "[2/7] Installerar k3s"
  curl -fsSL https://get.k3s.io -o "${TMP_DIR}/install-k3s.sh"
  sh "${TMP_DIR}/install-k3s.sh" --disable=traefik --disable=metrics-server --tls-san="${PRIMARY_IP}"
else
  echo "[2/7] k3s finns redan"
fi

systemctl enable --now k3s
kubectl wait --for=condition=Ready node --all --timeout=180s

if ! command -v helm >/dev/null 2>&1; then
  echo "[3/7] Installerar Helm"
  HELM_KEY_ID="DDF78C3E6EBB2D2CC223C95C62BA89D07698DBC6"
  curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey -o "${TMP_DIR}/helm.gpg"
  ACTUAL_KEY_ID="$(gpg --show-keys --with-colons "${TMP_DIR}/helm.gpg" | awk -F: '$1 == "fpr" {print $10}' | head -n 1)"
  if [[ "${ACTUAL_KEY_ID}" != "${HELM_KEY_ID}" ]]; then
    echo "Fel Helm-nyckel: ${ACTUAL_KEY_ID}" >&2
    exit 1
  fi
  gpg --dearmor < "${TMP_DIR}/helm.gpg" > /usr/share/keyrings/helm.gpg
  echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" \
    > /etc/apt/sources.list.d/helm-stable-debian.list
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y helm
else
  echo "[3/7] Helm finns redan"
fi

echo "[4/7] Installerar ingress-nginx"
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx --force-update
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace --wait --timeout 5m

echo "[5/7] Skapar GitHub-deployerns Kubernetes-behörigheter"
curl -fsSL \
  "https://raw.githubusercontent.com/${APP_REPO}/main/k8s/github-permissions.yaml" \
  -o "${TMP_DIR}/github-permissions.yaml"
kubectl apply -f "${TMP_DIR}/github-permissions.yaml"

echo "[6/7] Installerar Sigstore policy-controller"
helm repo add sigstore https://sigstore.github.io/helm-charts --force-update
helm repo update
kubectl create namespace cosign-system --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install policy-controller sigstore/policy-controller \
  --namespace cosign-system --wait --timeout 5m
kubectl label namespace default policy.sigstore.dev/include=true --overwrite

cat > "${TMP_DIR}/image-policy.yaml" <<EOF
apiVersion: policy.sigstore.dev/v1beta1
kind: ClusterImagePolicy
metadata:
  name: verify-company-website
spec:
  mode: enforce
  images:
    - glob: "${APP_IMAGE}**"
  authorities:
    - name: github-actions-keyless
      keyless:
        identities:
          - issuer: https://token.actions.githubusercontent.com
            subjectRegExp: "${WORKFLOW_IDENTITY}"
EOF
kubectl apply -f "${TMP_DIR}/image-policy.yaml"

echo "[7/7] Skapar ny kubeconfig för GitHub Actions"
for _ in {1..30}; do
  TOKEN="$(kubectl get secret github-deployer-token -n default -o jsonpath='{.data.token}' 2>/dev/null || true)"
  [[ -n "${TOKEN}" ]] && break
  sleep 2
done
if [[ -z "${TOKEN:-}" ]]; then
  echo "ServiceAccount-token skapades inte." >&2
  exit 1
fi

CA_CERT="$(base64 -w 0 /var/lib/rancher/k3s/server/tls/server-ca.crt)"
TOKEN_TEXT="$(printf '%s' "${TOKEN}" | base64 -d)"
cat <<EOF | base64 -w 0 > "${KUBECONFIG_OUTPUT}"
apiVersion: v1
kind: Config
clusters:
  - cluster:
      certificate-authority-data: ${CA_CERT}
      server: https://${PRIMARY_IP}:6443
    name: k3s-cluster
contexts:
  - context:
      cluster: k3s-cluster
      namespace: default
      user: github-deployer
    name: k3s
current-context: k3s
users:
  - name: github-deployer
    user:
      token: ${TOKEN_TEXT}
EOF
echo >> "${KUBECONFIG_OUTPUT}"
chown "${TARGET_USER}:${TARGET_GROUP}" "${KUBECONFIG_OUTPUT}"
chmod 600 "${KUBECONFIG_OUTPUT}"

kubectl auth can-i get networkpolicies \
  --as=system:serviceaccount:default:github-deployer -n default | grep -qx yes

echo
echo "Klart. Ny base64-kodad kubeconfig: ${KUBECONFIG_OUTPUT}"
echo "Lägg filens innehåll i GitHub-secret KUBECONFIG och kör deploy-workflowen igen."
