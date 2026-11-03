# Team 3 – Blue Team

Detta repository innehåller Team 3:s infrastruktur och säkerhetsarbete i kursen Avancerad IT-säkerhet. Miljön är byggd med Terraform i GCP och består av en jumphost, en intern primary-server med k3s samt säker deployment av applikationen `Team3-ThaCompany`.

Målet har varit att få nätverksskydd, identitet, CI/CD, containersäkerhet, övervakning och incidenthantering att fungera som en sammanhängande lösning.

## Arkitektur

```mermaid
flowchart LR
    U[Teammedlem] -->|IAP och OS Login| J[Jumphost]
    U -->|Headscale/Tailscale| J
    J -->|Routing och NAT| P[Primary]
    P --> K[k3s]
    K --> A[Company Website]
    G[GitHub Actions] -->|Workload Identity Federation| C[GCP]
    G -->|Signerad image och kubeconfig| K
    R[GHCR] -->|Image, signatur och SBOM| K
    S[Trivy CronJob] -->|Larm| D[Discord]
```

Miljön körs i GCP-projektet `itsx25-comerit`. Primary saknar extern IP och nås via jumphosten. SSH-identitet hanteras med OS Login och infrastrukturen deployas från GitHub Actions med Workload Identity Federation i stället för statiska GCP-nycklar.

## Driftstatus

Miljön återställdes i Comerits GCP-projekt den 3 november 2026:

- `team3-primary` kör ett nytt k3s-kluster och rapporterar `Ready`.
- `team3-comerit-router` annonserar `10.0.3.0/24` via Headscale.
- Den gamla jumphosten annonserar inte längre Team 3:s subnät.
- ingress-nginx, Sigstore policy-controller och applikationens NetworkPolicy är aktiva.
- Senaste [deploymenten i Team3-ThaCompany](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621) är grön.
- `company-website.team3.arpa` svarade med HTTP 200 efter deployment.

## Säkerhetskontroller

- OS Login och separata nivåer för vanlig åtkomst och sudo.
- Begränsade och loggade brandväggsregler.
- VPC Flow Logs för nätverksspårbarhet.
- Skyddad `main` med pull request, granskning och automatiska kontroller.
- Terraform-format, validering, TFLint och Checkov före merge.
- GitHub Actions autentiserar mot GCP genom Workload Identity Federation.
- Container-images byggs med spårbar commit och immutable digest.
- CycloneDX-SBOM skapas och binds till imagen med Cosign.
- Trivy skannar sårbarheter och skickar larm till Discord.
- Applikationen kör utan root, utan service-account-token och utan extra Linux-capabilities.
- seccomp, NetworkPolicy, resursgränser och health checks verifierades efter deployment.

## Repositorystruktur

```text
.
├── .github/workflows/       # PR-kontroller och Terraform-deployment
├── bootstrap/               # Äldre bootstrap för fristående miljö
├── docs/                    # Rapporter och individuella redogörelser
├── headscale/               # Headscale-policy
├── scripts/                 # Återställning av k3s på primary
├── backend.tf               # Terraform-state i GCS
├── main.tf                  # GCP-resurser, nätverk och IAM
├── variables.tf             # Terraform-variabler
└── terraform.tfvars.example # Teamets miljökonfiguration
```

> `bootstrap/` ska inte köras i Comerits delade GCP-miljö. Projektets grund, state-bucket, API:er och CI-identitet hanteras centralt av Comerit.

## CI/CD-flöde

1. En ändring görs i en separat branch.
2. En pull request kör Terraform format, validate, TFLint och Checkov.
3. `main` kräver granskning och godkända kontroller.
4. Efter merge autentiserar deploy-workflowen mot GCP med WIF.
5. Terraform skapar eller uppdaterar Team 3:s resurser.

Applikationen finns i [Team3-ThaCompany](https://github.com/ITSX25-Chas/Team3-ThaCompany). Dess pipeline testar koden, bygger imagen, skapar SBOM, signerar imagen och deployar den till k3s.

## Verifiera infrastrukturen lokalt

Följande kommandon ändrar inte infrastrukturen:

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
tflint --recursive
checkov -d . --framework terraform
```

Deployment görs av GitHub Actions. Lägg aldrig API-nycklar, kubeconfig, lösenord eller andra hemligheter i repot.

Om en ny primary saknar Kubernetes finns en [återställningsguide](docs/restore-primary-k3s.md) och ett återkörbart [installationsskript](scripts/bootstrap-primary-k3s.sh).

## Dokumentation för Blue Team-examinationen

- [Säkerhetsrapport – Markdown](docs/blue-team-security-report.md)
- [Säkerhetsrapport – PDF](docs/blue-team-security-report.pdf)
- [André Edvardsson – AI-redogörelse](docs/andre-ai-redogorelse.md)
- [André Edvardsson – individuellt bidrag](docs/andre-individuellt-bidrag.md)
- [Guide för OS Login](docs/os-login.md)

Git-historik, issues, pull requests och pipelinekörningar används som spårbar evidens för teamets och varje students arbete.

## Red Team-material

Red Team-arbetet är en separat examination men förvaras i samma repository:

- [Red Team pentest-rapport – Markdown](docs/red-team-pentest-report.md)
- [Red Team pentest-rapport – PDF](docs/red-team-pentest-report.pdf)

Blue Team- och Red Team-rapporterna ska inte blandas ihop vid inlämningen.

## Kvarstående risker

De viktigaste kvarstående riskerna beskrivs mer utförligt i säkerhetsrapporten:

- Headscale är fortfarande beroende av manuellt hanterat tillstånd och backup.
- k3s och subnet-routern återställs fortfarande med ett separat skript och hanteras inte helt av Terraform.
- Kubernetes-deploymenten använder fortfarande en långlivad autentisering.
- Full TLS saknas för den interna applikationen.
- Terraform-state och centrala GCP-rättigheter måste verifieras tillsammans med Comerit.
- Riskundantag för sårbarheter måste omprövas när de löper ut eller när en fix blir tillgänglig.

En grön pipeline betyder att de definierade kontrollerna passerade. Det är inte samma sak som att miljön saknar risker.
