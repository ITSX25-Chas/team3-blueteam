# Post-mortem, lessons learned och professionell sammanfattning

- **Student:** Marcus Gustafsson
- **Projekt:** Team 3 Blue Team

## Syfte och kursmål

Den här delen dokumenterar en kontrollerad simulering av en möjlig intrångsväg, tre lärdomar och rekommendationer för en professionell mottagare.

- **Kursmål 9:** Utföra incidentrespons, post-mortem och förbättringsarbete efter ett verkligt eller simulerat intrångsförsök.
- **Kursmål 13:** Självständigt leda och leverera ett komplext säkerhetsprojekt med höga krav på kvalitet, dokumentation och professionell kommunikation.

---

## Händelse och avgränsning

Post-mortemet gäller en kontrollerad simulering av hur en CI- eller scannerbehörighet i Kubernetes kunde försöka nå monterade secrets via en scanner-CronJob. Direkt läsning av en Secret var spärrad, men rätten att ändra scannerjobbet kunde ge en indirekt väg till hemligheter som workloaden monterade. Genomgången gällde k3s-miljön och scannerjobben i namespace security-tools. RBAC-granskning och test av tillåtna och nekade åtgärder gjorde vägen synlig. Det finns inget belägg för att en hemlighet faktiskt lästes eller fördes ut. Jag deltog i genomgången och testet av attackvägen. Teamets respons var att ta bort scanner-apply från appens pipeline och kontrollera att deployidentiteten nekades pod-skapande och ändring av scanner-CronJobs efter åtgärden. Post-mortemet gäller denna behörighetsväg, inte en bekräftad angripare.

[Evidens: säkerhetsrapportens avsnitt om deployidentiteten](../../blue-team-security-report.md#5-prioriterade-kvarvarande-risker) · [Appens PR #26](https://github.com/ITSX25-Chas/Team3-ThaCompany/pull/26)

---

## Lesson learned 1 – Indirekta behörighetsvägar måste testas

### Observation

Genomgången visade att direkt läsning av en Secret var spärrad, men en scannerbehörighet kunde ändra en CronJob som använde monterade secrets. Efter teamets ändring verifierades att deployidentiteten nekades pod-skapande i namespace default och ändring av CronJobs i namespace security-tools.

### Orsak

Behörigheterna granskades först som enskilda rättigheter. Den sammansatta vägen — ändra en workload och låta den använda en monterad hemlighet — bedömdes inte tillräckligt tidigt.

### Konsekvens

En komprometterad CI-identitet hade kunnat få större åtkomst än den direkta behörighetskontrollen visade. Det är en identifierad möjlighet, inte belägg för att någon faktiskt läste eller exfiltrerade en hemlighet. Rapporten anger också att appens pipeline fortfarande kan läsa och uppdatera applikationshemligheter i namespace default.

### Förbättring

Håll scanneradministration åtskild från appdeployment. Begränsa varje identitets möjlighet att ändra CronJobs, skapa poddar eller montera hemligheter. Ge en workload bara de secrets den behöver.

### Uppföljning

Kör dokumenterade positiva och negativa RBAC-tester före release. Kontrollera både direkt secret-läsning och indirekta vägar via poddar och CronJobs. Följ upp den kvarvarande åtkomsten till applikationshemligheter med ansvarig och datum för omprövning.

### Egen reflektion

Jag deltog i genomgången och testet av attackvägen. Det lärde mig att en nekad direktbehörighet inte räcker som bevis på minsta behörighet; man måste följa vad identiteten kan få andra resurser att göra. I mitt eget arbete med Headscale-ACL vill jag därför testa både avsedd åtkomst och vägar som ska vara nekade.

**Evidens:** [Säkerhetsrapport, B04](../../blue-team-security-report.md#5-prioriterade-kvarvarande-risker) · [PR #26](https://github.com/ITSX25-Chas/Team3-ThaCompany/pull/26)

---

## Lesson learned 2 – Infrastructure as Code återställer inte automatiskt tjänstetillstånd

### Observation

När jumphosten ersattes behövde Headscale installeras och klientregistreringar återställas. Användar-ID:t för github-ci ändrades också. Vid den senare miljöflytten saknade den nya primary-noden k3s, och subnet-routing behövde återställas separat.

### Orsak

Terraform beskrev VM-resurserna, men inte hela tjänstens tillstånd och återställning: Headscale-databas och konfiguration, klientidentiteter, routes, DNS och k3s-konfiguration.

### Konsekvens

Klient- och deploymentåtkomst stördes och behövde felsökas och återställas manuellt. Att VM-resurserna gick att skapa på nytt betydde inte att tjänsterna eller deras identiteter var tillbaka.

### Förbättring

Dokumentera och automatisera installation och återställning av Headscale och k3s. Säkerhetskopiera tjänstedata konsekvent och utse ansvariga för state, nycklar, DNS och routes. Håll hemligheter utanför rapporter och vanliga loggar.

### Uppföljning

Genomför en återställningsövning på en separat test-VM. Kontrollera att klienter, ACL, DNS, routes och deploymentidentitet fungerar efter återställningen. Spara resultatet och förbättringsärenden som evidens.

### Egen reflektion

Jag arbetade med Headscale-ACL och DNS och felsökte klientanslutningen från min Mac efter zonflytten. Själva Headscale-åtgärden gjordes av en gruppkamrat. Jag lärde mig att policyändringar bara är en del av åtkomstkedjan: tjänstens data, identiteter och routes måste också överleva en VM-ersättning. Nästa gång vill jag kontrollera backup och återställningsansvar innan en flytt börjar.

**Evidens:** [Säkerhetsrapport, avsnitt 6](../../blue-team-security-report.md#6-incidenter-och-lärdomar) · [Mitt dokumenterade bidrag](../../marcus-individuellt-bidrag.md)

---

## Lesson learned 3 – En grön kontroll måste bevisa rätt miljö och identitet

### Observation

Efter miljöflytten ledde en gammal subnet-route först appens pipeline till det tidigare klustret trots att den interna adressen var densamma. Certifikat och faktisk workload behövde jämföras för att hitta rätt mål. I min SSH-felsökning tog jag bort en gammal värdnyckel ur known_hosts; anslutningen fungerade därefter, men den nya serverns identitet verifierades inte av just det steget.

### Orsak

Samma adress användes före och efter flytten, och kontrollerna bekräftade först att anslutning fungerade — inte att rätt kluster eller SSH-server svarade.

### Konsekvens

En grön pipeline kunde ha tolkats som bevis på att den nya miljön var uppdaterad, fast den nådde det gamla klustret. Att acceptera en ny SSH-värdnyckel utan jämförelse med ett betrott fingeravtryck lämnar också identiteten obekräftad. Ingen man-in-the-middle-attack är belagd.

### Förbättring

Verifiera klusteridentitet, certifikat, GCP-projekt, routeägare och faktisk workload efter en migration. Jämför SSH-värdnyckelns fingeravtryck med en betrodd källa innan den nya nyckeln accepteras. Lägg in kontroll av förväntad miljö i deploymentflödet.

### Uppföljning

Testa att deployment stoppas när routen pekar mot fel kluster och lyckas först mot rätt miljö. Dokumentera klusterfingeravtryck, image-digest och körningslänk. Kontrollera SSH-identiteten separat från att anslutningen fungerar.

### Egen reflektion

Jag tog bort den gamla värdnyckeln och fick SSH att fungera igen. I efterhand ser jag att det löste anslutningshindret men inte bevisade vem servern var. Nästa gång jämför jag fingeravtrycket via en betrodd kanal först. Mitt Secure Boot-test lärde mig också att VM-statusen RUNNING inte ensam visar att operativsystemet har startat; jag behöver kontrollera den faktiska tjänsten och återställningsvägen.

**Evidens:** [Säkerhetsrapport, avsnitt 6](../../blue-team-security-report.md#6-incidenter-och-lärdomar) · [Min AI-redogörelse om felsökningen](../../marcus-ai-redogorelse.md) · [Deployment 41608640621](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621)

---

## Professionell sammanfattning

En kontrollerad genomgång av Kubernetes-behörigheter identifierade en möjlig väg från en CI- eller scanneridentitet till monterade secrets genom ändring av en scanner-CronJob, trots att direkt secret-läsning var spärrad. Inget belägg finns för att någon faktiskt läste eller förde ut en hemlighet. Teamet tog bort scanner-apply från appens pipeline och verifierade att deployidentiteten nekas pod-skapande och ändring av scanner-CronJobs. Rapporten visar samtidigt att appens pipeline fortfarande kan läsa och uppdatera applikationshemligheter i namespace default; den åtkomsten behöver begränsas och följas upp.

Miljöflytten visade att återskapade VM:er inte automatiskt återställer Headscale-data, k3s, routes eller kubeconfig. En gammal subnet-route ledde först deploymenten till det tidigare klustret trots samma interna adress. Certifikat och faktisk workload behövde kontrolleras för att identifiera rätt mål. Efter korrigeringen verifierades nodstatus, NetworkPolicy och HTTP 200 i körning 41608640621. Det rör sig om en simulerad behörighetsväg och dokumenterade drift- och konfigurationsbrister, inte bevis på ett verkligt intrång.

Organisationen bör prioritera tre åtgärder: separata identiteter med minsta behörighet för appdeployment och scanning, ett testat återställningsförfarande för Headscale och k3s samt en automatisk identitetskontroll av klustret före deployment. En IAM-ansvarig bör besluta hur den kvarvarande secret-åtkomsten ska begränsas och sätta datum för omprövning. Driftansvarig bör visa att backup går att återställa. CI-ansvarig bör visa att en deployment stoppas mot fel kluster. Uppföljningen bör styrkas med RBAC-tester, en återställningsövning och en deployment mot verifierad miljö.

---

## Kontroll före commit

- Jag har avgränsat vilket intrångsförsök eller vilken incident mitt post-mortem gäller.
- Jag har beskrivit min egen roll i incidentresponsen.
- Jag har formulerat tre tydliga lessons learned.
- Jag skiljer på observation och bakomliggande orsak.
- Jag beskriver konsekvensen av varje lärdom.
- Varje lesson learned leder till en konkret förbättring och uppföljning.
- Den professionella sammanfattningen fokuserar på resultat, risk och betydelse.
- Texten är saklig, begriplig och professionellt anpassad för mottagaren.
