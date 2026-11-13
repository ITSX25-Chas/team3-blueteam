# KPI:er och säkerhetsmätningar

**Student:** André Edvardsson  
**Projekt:** Team 3, kurs 6 – avancerad IT-säkerhet  
**Mottagare:** Teknisk ledning och verksamhetsledning  
**Mätperiod:** 21 september–10 november 2026

## Sammanfattning för ledningen

Jag har valt tre KPI:er som tillsammans visar om vi kan leverera säkert, om kända sårbarheter hanteras i tid och om angrepp faktiskt upptäcks. De är avsiktligt få och går att följa utan att mottagaren behöver förstå Terraform, Kubernetes eller enskilda CVE:er.

| KPI | Nuläge | Mål | Ledningssignal |
|---|---:|---:|---|
| Säkra deploymenter | 80 % | minst 95 % | Leveranskedjan fungerar, men är inte tillräckligt stabil |
| Critical och utgångna undantag | 0 + 0 | 0 + 0 | Inget akut överskridande, men nio undantag måste omprövas senast 20 november |
| Testad larmtäckning i Red Team-målmiljön | 0 % | minst 80 % | Loggar fanns, men inga av sex prioriterade attacksteg gav observerat larm |

## KPI 1 – Andel lyckade säkra deploymenter

| Fält | Innehåll |
|---|---|
| Syfte | Visa om leveranskedjan både fungerar och genomför beslutade säkerhetskontroller. |
| Definition | En körning räknas som lyckad när tester, imagebygge, SBOM, Cosign-signering, anslutning till rätt kluster och Kubernetes-rollout passerar. |
| Formel | `lyckade kompletta deploykörningar / alla slutförda deploykörningar × 100` |
| Datakälla | GitHub Actions, workflow `deploy.yml` i `Team3-ThaCompany`. |
| Frekvens | Veckovis samt efter större ändringar eller miljöbyte. |
| Nuläge | 24 av de 30 senaste slutförda körningarna på `main` lyckades: **80 %**. Den senaste verifierade körningen, `41608640621`, lyckades i Comerits miljö. |
| Mål | Minst **95 %**, samtidigt som inga säkerhetssteg får hoppas över för att förbättra siffran. |
| Ansvar | Applikations-/plattformansvarig följer upp. Den som äger den felande komponenten åtgärdar. |
| Åtgärd vid avvikelse | Stoppa release, klassificera om felet gäller kod, kontroll, autentisering eller målmiljö, skapa issue och verifiera med ny körning. |
| Evidens | [GitHub Actions](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions) och [senaste lyckade deployment](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621). |

### Min bedömning

KPI:n visar både driftsäkerhet och säkerhetsdisciplin. En grön körning är dock inte ensam tillräcklig. Under migrationen kunde samma interna adress leda till det gamla klustret. Därför måste körningen även verifiera projekt, klustercertifikat, image-digest och tjänstehälsa. Annars kan KPI:n bli grön trots att fel miljö används.

## KPI 2 – Critical-fynd och utgångna riskundantag

| Fält | Innehåll |
|---|---|
| Syfte | Förhindra att allvarliga sårbarheter eller gamla riskbeslut blir liggande utan ägare. |
| Definition | Antal öppna Critical-fynd plus antal High/Critical-undantag vars slutdatum har passerat. Aktiva undantag redovisas separat. |
| Formel | `öppna Critical + utgångna undantag` |
| Datakälla | Trivy, CycloneDX-SBOM, signerad Cosign-attestering, scannerloggar och `trivyignore.yaml`. |
| Frekvens | Avsikten är skanning vid imagebygge och dagligen mot den körande imagen. Den dagliga körningen är tillfälligt bruten efter miljöbytet. Formell omprövning ska ske minst veckovis när undantag närmar sig slutdatum. |
| Nuläge | Senaste verifierade skanning den 3 november gav **0 Critical**, 44 High-paketträffar och **9 tidsbegränsade CVE-undantag** till 20 november 2026. Vid kontroll den 13 november saknades `security-tools`, scanner-CronJobben och Discord-secreten i det nya klustret. Automatisk daglig skanning pågår därför inte. |
| Mål | 0 Critical, 0 utgångna undantag och 100 % av aktiva undantag med motivering, ägare och slutdatum. |
| Ansvar | Säkerhetsansvarig bedömer risken; applikationsansvarig uppdaterar image eller beroende. |
| Åtgärd vid avvikelse | Blockera eller återställ deployment, triagera fyndet och besluta om åtgärd eller en ny dokumenterad och tidsbegränsad riskacceptans. |
| Evidens | [Blue Team-säkerhetsrapport, avsnitt 6](../../blue-team-security-report.md#6-incidenter-och-lärdomar) och appens `k8s/sbom-scanner/trivyignore.yaml`. |

### Min bedömning

Ett undantag betyder inte att sårbarheten är borta. Det betyder att en känd risk accepteras under en begränsad tid. Ledningen behöver därför se både utgångna och fortfarande aktiva undantag. Enbart siffran `0 Critical` skulle ge en för positiv bild. KPI:n kan inte betraktas som aktuell igen förrän CronJobben har återställts och en ny skanning har verifierats.

## KPI 3 – Testad larmtäckning i Red Team-målmiljön

| Fält | Innehåll |
|---|---|
| Syfte | Mäta om prioriterade angrepp upptäcks i praktiken, inte bara om loggfiler existerar. |
| Definition | Antal prioriterade attacksteg som testats end-to-end och gett ett begripligt larm, dividerat med sex planerade fall: SQLi, cookie-/adminmissbruk, IDOR, kommandoinjektion, root-eskalering och intern export. |
| Formel | `attacksteg med verifierat larm / 6 × 100` |
| Datakälla | Red Team-målens webb-, intern- och databasloggar samt framtida SIEM-/notifieringsloggar. Acme-målet var separat från vår Blue Team-app. Detta är därför inte samma mätning som Blue Teams gemensamma baslinje på 1 av 5 verifierade detektionstester. |
| Frekvens | Efter förändringar i loggning och minst månadsvis som kontrollerat detektionstest. |
| Nuläge | **0 av 6 gav observerat larm: 0 %**. Fyra steg var fullt synliga i efterhand och två var delvis synliga eftersom POST-data, cookies och användaridentitet saknades. |
| Mål | Minst **5 av 6 (83 %)** inom nästa förbättringsperiod och 6 av 6 på längre sikt. MTTD för RCE, root och intern export ska vara högst fem minuter. |
| Ansvar | SOC-/övervakningsansvarig äger regler och notifiering; systemägaren säkerställer loggkälla och kontext. |
| Åtgärd vid avvikelse | Avgör om luckan finns i insamling, regel, notifiering eller ansvar. Skapa förbättringsärende och kör om samma test. |
| Evidens | [Red Team-rapportens post-mortem](../../red-team-pentest-report.md#post-mortem-detektion-och-förbättring). |

### Min bedömning

Det här är den viktigaste KPI:n för en ledningsgrupp. Projektet visade att loggning kan finnas utan att ett angrepp upptäcks i tid. I loggpaketet syntes hela RCE- och rootkedjan tydligt, men först vid efteranalys. KPI:n gör skillnaden mellan ”vi sparar loggar” och ”vi kan reagera” mätbar.

## Beslut och uppföljning

För en teknisk chef skulle jag först visa säkra deploymenter eftersom den pekar direkt på var leveransflödet fallerar. För ledningsgruppen skulle jag börja med larmtäckningen: den uttrycker verksamhetsrisken tydligt och visar om organisationen kan upptäcka ett pågående intrång. KPI 2 säkerställer därefter att känd teknisk skuld inte glöms bort.
