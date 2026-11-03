# Blue Team – inlämningsunderlag för André Edvardsson

## Länkar

- Repository: https://github.com/ITSX25-Chas/team3-blueteam
- Säkerhetsrapport: https://github.com/ITSX25-Chas/team3-blueteam/blob/main/docs/blue-team-security-report.pdf
- Individuellt bidrag: https://github.com/ITSX25-Chas/team3-blueteam/blob/main/docs/andre-individuellt-bidrag.md
- AI-redogörelse: https://github.com/ITSX25-Chas/team3-blueteam/blob/main/docs/andre-ai-redogorelse.md

## Text att klistra in i Canvas

Jag har främst arbetat med åtkomst, nätverk, CI/CD, Kubernetes och säkerhetskontroller. Mina bidrag omfattar bland annat OS Login på primary, VPC Flow Logs, Headscale-regler för GitHub-runnern samt blockerande Terraform-, TFLint- och Checkov-kontroller.

I applikationsdelen arbetade jag med ingress och deployment, Cosign-signering, CycloneDX-SBOM, sårbarhetsskanning och containerhärdning. Jag har även verifierat ändringarna med pipelinekörningar, Trivy, Cosign, Kubernetes-status, RBAC-kontroller och health checks.

Efter flytten till Comerits miljö felsökte och återställde jag k3s på nya primary. Jag identifierade att en gammal Headscale-route ledde till fel kluster, jämförde certifikat, flyttade subnet-routen, roterade kubeconfig och verifierade en lyckad deployment med aktiv NetworkPolicy och HTTP 200.

Arbetet syns bland annat i commits `0e6b150`, `d2a91fb`, `41c066e`, `f8feff5`, `037a16d`, `6e85d55`, `dab93b8` och `c5c2003`, i app-repots PR #24–#29 samt i deployment `41608640621`.

AI användes som bollplank för felsökning, kodförslag och rapportstruktur. Jag kontrollerade svaren genom kodgranskning, dokumentation, statiska verktyg, tester och verifiering i den verkliga miljön. AI användes inte som ensam beslutsfattare för IAM, hemligheter eller riskacceptans.
