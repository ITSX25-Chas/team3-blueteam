# Individuellt bidrag – Andre Edvardsson

Text att använda i Canvas och anpassa vid behov:

Jag arbetade främst med identitet, nätverk, CI/CD, supply-chain-säkerhet, Kubernetes-härdning, övervakning och säkerhetsrapporten. I infra-repot syns mitt arbete bland annat i commits `0e6b150` (OS Login på primary), `d2a91fb` (VPC Flow Logs), `41c066e` (ACL för GitHub-runner), `f8feff5` (blockerande CI och begränsad WIF), `037a16d` (TFLint) och `6e85d55` (Checkov). Jag tog även fram och verifierade den slutliga säkerhetsrapporten.

I app-repot arbetade jag bland annat med ingress/deployment, image-digest och spårbarhet, Cosign-signering, CycloneDX-SBOM, säkerhetsscanner, kontroller av sessioner och deployflöde, uppdaterad runtime-image, scannerisolering, non-root-container och tidsbegränsad riskacceptans. Relevanta PR:er är #24–#28. Jag verifierade ändringarna med tester, signerad SBOM, Trivy, Kubernetes-status, hälsokontroller och praktiska RBAC-/skrivtester.

Mitt arbetssätt var iterativt: identifiera risk, skapa avgränsad ändring, köra automatiska kontroller, verifiera i drift och dokumentera kvarstående risk. AI användes som stöd enligt den separata AI-redogörelsen, men beslut och verifiering baserades på kod, tester, officiella källor och faktisk miljöstatus.
