# Återställ k3s på Team 3 primary

Den nya `team3-primary` i `itsx25-comerit` saknar k3s. Den här guiden bygger upp ett nytt kluster. Den återställer inte data från det gamla klustret.

## 1. Kopiera skriptet till primary

Kör från din egen WSL-terminal i repots katalog:

```bash
gcloud compute scp scripts/bootstrap-primary-k3s.sh \
  team3-primary:/tmp/bootstrap-primary-k3s.sh \
  --project=itsx25-comerit \
  --zone=europe-north2-a \
  --tunnel-through-iap
```

## 2. Kör skriptet

```bash
gcloud compute ssh team3-primary \
  --project=itsx25-comerit \
  --zone=europe-north2-a \
  --tunnel-through-iap
```

På primary:

```bash
chmod +x /tmp/bootstrap-primary-k3s.sh
sudo /tmp/bootstrap-primary-k3s.sh
```

Skriptet installerar k3s, Helm, ingress-nginx, GitHub-deployerns RBAC och Sigstores policy-controller. Det skapar sedan `~/team3-kubeconfig.b64`.

## 3. Uppdatera GitHub-secret

Visa kubeconfig-värdet:

```bash
cat ~/team3-kubeconfig.b64
```

Kopiera hela raden till `Team3-ThaCompany` → **Settings** → **Secrets and variables** → **Actions** → secret `KUBECONFIG`.

Radera sedan den lokala filen:

```bash
rm ~/team3-kubeconfig.b64
```

## 4. Kontrollera Headscale-routen

Innan deployment måste `10.0.3.0/24` gå till den nya miljön. Gammal och ny gateway får inte annonsera samma subnät samtidigt. Be Comerit verifiera routen om ni inte administrerar Headscale-servern.

## 5. Kör och verifiera deploymenten

Kör workflowen **Deploy to K3s** igen och kontrollera på primary:

```bash
sudo k3s kubectl get nodes
sudo k3s kubectl get pods -A
sudo k3s kubectl get deploy,pods,service,ingress,networkpolicy -n default
```

Workflowen ska bli grön och `company-website` ska få status `Available`.
