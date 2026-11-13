# Individuell slutrapport

**Student:** André Edvardsson  
**Projekt:** Team 3, kurs 6 – avancerad IT-säkerhet  
**Mottagare:** Fiktiv ledningsgrupp

## 1. Sammanfattning

Projektet gick ut på att bygga, härda och följa upp en molnbaserad miljö samt genomföra ett avgränsat penetrationstest mot en separat målmiljö. I Blue Team-delen byggde vi infrastrukturen som kod och lade till identitetsstyrd åtkomst, nätverksskydd, CI/CD-kontroller, SBOM, imagesignering, sårbarhetsskanning och Kubernetes-policyer. I Red Team-delen följde vi en godkänd Rules of Engagement och dokumenterade en attackkedja från SQL-injektion till root-rättighet och intern dataåtkomst i den särskilda Acme-labben.

Mitt viktigaste resultat var att bidra till att skydden inte bara fanns i kod utan också verifierades i drift. Efter migrationen till Comerits GCP-projekt deltog jag i återställningen av k3s, routing, kubeconfig och säkerhetspolicyer. Den slutliga appdeploymenten blev grön och kontrollerades med körande pod, NetworkPolicy och HTTP 200. Samtidigt visade post-mortem-loggarna att loggning och faktisk detektion är olika saker: sex prioriterade attacksteg lämnade spår, men inget observerat larm utlöstes.

## 2. Mitt bidrag

### Åtkomst och nätverk

Jag arbetade med OS Login på primary, VPC Flow Logs och Headscale-regler för GitHub-runnern. Syftet var att ersätta svårspårade SSH-lösningar, förbättra nätverksevidens och begränsa runnerns åtkomst till Kubernetes API. Arbetet syns bland annat i commits [`0e6b150`](https://github.com/ITSX25-Chas/team3-blueteam/commit/0e6b150), [`d2a91fb`](https://github.com/ITSX25-Chas/team3-blueteam/commit/d2a91fb) och [`41c066e`](https://github.com/ITSX25-Chas/team3-blueteam/commit/41c066e).

### CI/CD och säkerhetskontroller

Jag arbetade med blockerande kontroller för Terraform, TFLint och Checkov samt med WIF-baserad autentisering. I appflödet arbetade jag med ingress, SBOM i CycloneDX-format, Cosign, begränsad deploy-RBAC, non-root-runtime och sårbarhetsscannern. Exempel på infraevidens är [`f8feff5`](https://github.com/ITSX25-Chas/team3-blueteam/commit/f8feff5), [`037a16d`](https://github.com/ITSX25-Chas/team3-blueteam/commit/037a16d) och [`6e85d55`](https://github.com/ITSX25-Chas/team3-blueteam/commit/6e85d55). Appförbättringarna går att följa i PR #24–#28 i `Team3-ThaCompany`.

### Återställning efter miljöbytet

Efter flytten upptäckte vi att nya primary saknade k3s samtidigt som Headscale-routen fortfarande ledde till det gamla klustret. Jag jämförde klustercertifikat och tjänstestatus, installerade om k3s, ingress och Sigstore policy-controller, skapade ny kubeconfig och flyttade subnet-routen. Jag dokumenterade återställningen i [`dab93b8`](https://github.com/ITSX25-Chas/team3-blueteam/commit/dab93b8) och driftläget i [`c5c2003`](https://github.com/ITSX25-Chas/team3-blueteam/commit/c5c2003). Appkörning [`41608640621`](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621) verifierade slutresultatet.

### Säkerhetsanalys och rapportering

Jag deltog i granskning av behörigheter, sårbarheter och kvarstående risker samt sammanställde evidens i säkerhetsrapporten. I Red Team-arbetet dokumenterade jag reproduktionssteg, ATT&CK-kopplingar och post-mortem. När försvarsloggarna kom jämförde jag originalmiljön med den nollställda kopian och korrigerade tidigare antaganden mot faktiska tidsstämplar.

## 3. Resultat och evidens

| Resultat | Min insats | Evidens |
|---|---|---|
| Spårbar och begränsad åtkomst | OS Login, Flow Logs och Headscale-ACL | Commits `0e6b150`, `d2a91fb`, `41c066e` |
| Blockerande infra-kontroller | WIF, Terraform-, TFLint- och Checkov-härdning | Commits `f8feff5`, `037a16d`, `6e85d55` |
| Härdad leveranskedja | SBOM, Cosign, non-root, RBAC och scannerförbättringar; scannerkoden finns men den dagliga CronJobben saknas i nuvarande kluster | App-PR #24–#28 och [säkerhetsrapporten](../../blue-team-security-report.md) |
| Återställd Comerit-miljö | k3s, ingress, policy-controller, kubeconfig och route | Commits `dab93b8`, `c5c2003`, run `41608640621` |
| Evidensbaserat post-mortem | Jämförelse av webb-, intern- och databasloggar | [Red Team-rapport, avsnitt post-mortem](../../red-team-pentest-report.md#post-mortem-detektion-och-förbättring) |

## 4. Säkerhetsuppföljning

De tre KPI:erna finns definierade i [kpi.md](kpi.md):

1. **Säkra deploymenter:** 24 av 30 slutförda körningar lyckades, 80 %. Målet är minst 95 % utan att säkerhetssteg tas bort.
2. **Critical och utgångna undantag:** senaste verifierade skanning den 3 november visade 0 Critical och nio tidsbegränsade undantag. Den 13 november saknades scanner-CronJobben i det nya klustret, så nuläget kan inte beskrivas som löpande verifierat förrän scannern har återställts.
3. **Testad larmtäckning i Red Team-målmiljön:** 0 av 6 prioriterade attacksteg gav observerat larm. Målet är minst 5 av 6 och högst fem minuters MTTD för RCE, root och intern export. Detta är en separat mätning från Blue Teams gemensamma baslinje på 1 av 5 verifierade detektionstester.

Jag bedömer larmtäckningen som viktigast för ledningen. Tekniska skydd och loggar har begränsat värde om organisationen inte kan upptäcka, eskalera och hantera en pågående incident.

## 5. Post-mortem och lärdomar

Red Team-loggarna kom från Acme Corp Internportal, som var helt separat från vår Blue Team-app. Set A innehöll 17 720 webbrader och Set B 147. Den stora skillnaden berodde främst på att Set A innehöll omfattande automatiserad enumerering medan Set B var mer fokuserat. Samma SQLi-, IDOR-, RCE-, root- och exportvägar fungerade fortfarande i den nollställda miljön.

Fyra av sex attacksteg var fullt synliga i efterhand och två delvis synliga. POST-innehåll, cookies och tydlig användaridentitet saknades, medan RCE-kommandon, `find -exec`, `/bin/sh -p` och intern export syntes tydligt. Inget automatiskt larm eller incidentflöde kunde verifieras. Orsaken var alltså inte enbart brist på loggar, utan att insamlingen saknade tillräcklig kontext, analysregler, notifiering och tydligt ansvar.

Mina tre viktigaste lärdomar utvecklas i [lessons-learned.md](lessons-learned.md):

- IaC behöver kompletteras med backup och testad återställning av driftstillstånd.
- En grön pipeline måste verifieras mot rätt miljö och faktisk effekt.
- Roller, ansvar, dokumentation och post-mortem är säkerhetskontroller, inte administration vid sidan av.

## 6. AI-användning och professionellt ansvar

Jag använde AI som bollplank vid felsökning, kodförslag, analys av felmeddelanden och strukturering av rapporter. Den var särskilt användbar för att ta fram hypoteser och förklara Terraform, Kubernetes, Headscale och loggmönster. Jag använde också AI för att jämföra säkerhetsalternativ och göra tekniska resonemang begripligare.

Jag märkte samtidigt flera begränsningar. AI blandade ibland ihop vår Blue Team-app med den separata Red Team-miljön, föreslog kommandon som inte passade aktuell miljö eller rekommenderade större behörigheter än nödvändigt. Vid migrationen var den första hypotesen att problemet endast var en gammal kubeconfig, men praktiska kontroller visade även saknat k3s och felaktig routing.

Därför verifierade jag svar mot kod, officiell dokumentation, Git-historik och verkligt driftläge. Jag använde bland annat `terraform validate`, TFLint, Checkov, Trivy, Cosign, `kubectl auth can-i`, hälsokontroller, certifikatjämförelser och SHA-256-kontroll av loggpaketet. AI var inte lämplig som ensam beslutsfattare för IAM, hemligheter, riskacceptans eller destruktiva kommandon. Det professionella ansvaret låg kvar hos mig och teamet.

## 7. Prioriterade rekommendationer

### Nu – ompröva sårbarhetsundantagen

**Ansvar:** Säkerhets- och applikationsansvarig.  
**Åtgärd:** Återställ först scanner-CronJobben och Discord-secreten, verifiera en ny körning och bedöm därefter de nio CVE-undantagen före 20 november. Uppdatera imagen där fix finns och dokumentera nytt beslut där risk kvarstår.  
**Mätning:** KPI 2 ska fortsatt vara 0 Critical och 0 utgångna undantag.

### Nästa steg – automatisera och öva återställningen

**Ansvar:** Plattform-/infrastrukturansvarig.  
**Åtgärd:** Automatisera k3s, ingress, policyer, routing och kortlivad deployautentisering. Genomför ett återställningstest från dokumenterad backup.  
**Mätning:** Mät återställningstid och andel komponenter som kan återskapas utan odokumenterade manuella steg.

### Längre sikt – bygg en verifierad detektionskedja

**Ansvar:** Övervakningsansvarig tillsammans med systemägaren.  
**Åtgärd:** Centralisera säkerhetsrelevanta loggar, skapa prioriterade regler, definiera larmmottagare och testa kedjan regelbundet.  
**Mätning:** Minst 5 av 6 larmfall och högst fem minuters MTTD för de mest kritiska stegen.

## 8. Min utveckling och framtida yrkesroll

Projektet har lärt mig att cybersäkerhet inte bara handlar om att hitta eller rätta en teknisk brist. En fungerande lösning behöver identitet, nätverk, leveranskedja, övervakning, återställning och ansvar som hänger ihop. Jag har också blivit bättre på att skilja mellan kod som ser korrekt ut och ett skydd som faktiskt har verifierats i drift.

Jag tar med mig ett mer metodiskt arbetssätt till LIA: avgränsa problemet, dokumentera nuläget, göra små förändringar, bevara en väg tillbaka och verifiera resultatet med evidens. Vid incidenter vill jag arbeta med tydliga roller och ett post-mortem utan skuldfokus, där både bra och mindre bra beslut granskas och varje förbättring får ägare och uppföljning.

Det viktigaste är att kunna förklara tekniska resultat för människor som ska fatta beslut. En lista med verktyg eller CVE:er räcker inte. Jag behöver kunna beskriva verksamhetsrisk, osäkerhet, prioritering och hur förbättringen ska mätas över tid.

## 9. Referenser

- [Team 3 Blue Team-repository](https://github.com/ITSX25-Chas/team3-blueteam)
- [Blue Team-säkerhetsrapport](../../blue-team-security-report.md)
- [Red Team-pentest-rapport](../../red-team-pentest-report.md)
- [Min tidigare individuella bidragsbeskrivning](../../andre-individuellt-bidrag.md)
- [Min AI-redogörelse](../../andre-ai-redogorelse.md)
- [KPI-definitioner](kpi.md)
- [Lessons learned](lessons-learned.md)
