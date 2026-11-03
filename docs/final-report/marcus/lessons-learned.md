# Lessons learned och professionell sammanfattning

**Student:** Marcus Gustafsson
**Projekt:** Team 3 Blue Team

## Lärdom 1 – Infrastruktur som kod omfattar inte automatiskt tjänstedata

- **Observation:** VM:erna kunde återskapas i Comerits GCP-projekt, men nya primary saknade k3s och den gamla Headscale-routen pekade mot det tidigare klustret.
- **Orsak:** Terraform beskrev VM-resurserna men inte full återställning av k3s, Headscale-state, routes och kubeconfig.
- **Konsekvens:** En grön infrastrukturdeployment betydde inte att applikationsplattformen var återställd.
- **Förbättring:** Versionsstyr återställningsskript, säkerhetskopiera state och genomför ett dokumenterat återställningstest.
- **Egen reflektion:** _Vad hade du kontrollerat tidigare nästa gång?_

## Lärdom 2 – En grön pipeline måste verifieras mot rätt miljö

- **Observation:** Appens pipeline kunde nå adressen `10.0.3.3`, men nådde först det gamla klustret via en gammal subnet-route.
- **Orsak:** Samma interna adress användes i gammal och ny miljö medan routing och kubeconfig hade olika förtroendekedjor.
- **Konsekvens:** Resultat kunde misstolkas som bevis för den nya miljön.
- **Förbättring:** Kontrollera klusteridentitet, certifikat, image-digest och målprojekt efter migrationer.
- **Egen reflektion:** _Vilken evidens tycker du bäst visar att rätt miljö används?_

## Lärdom 3 – Minsta behörighet måste testas praktiskt

- **Observation:** En roll kunde indirekt nå secrets genom att ändra ett scannerjobb trots att direkt secret-läsning var nekad.
- **Orsak:** Behörigheter bedömdes resursvis i stället för som möjliga attackkedjor.
- **Konsekvens:** Ett komprometterat deploykonto kunde få större åtkomst än avsett.
- **Förbättring:** Separera deploy och scanneradministration, använd `kubectl auth can-i` och testa missbruksvägar.
- **Egen reflektion:** _Ge ett exempel på när en nekad direktbehörighet ändå inte räcker._

## Professionell sammanfattning

Team 3 byggde en säkerhetsarkitektur med Terraform, OS Login, begränsade nätverksregler, GitHub Actions med Workload Identity Federation, k3s, signerade images, SBOM och sårbarhetsskanning. Den återställda Comerit-miljön verifierades med ett grönt deploymentflöde, en körande non-root-applikation, NetworkPolicy och HTTP 200.

De viktigaste kvarstående riskerna är manuellt hanterad Headscale- och k3s-återställning, långlivad Kubernetes-autentisering, begränsad testning av detektionsfallen och tidsbegränsade riskundantag för High-fynd. Rekommenderad prioritet är att automatisera återställningen, korta livslängden på deployidentiteter och införa återkommande detektionstester med tydligt ansvar.

**Egen anpassning:** _Skriv om sammanfattningen med egna ord och välj de två rekommendationer du själv bedömer som viktigast._
