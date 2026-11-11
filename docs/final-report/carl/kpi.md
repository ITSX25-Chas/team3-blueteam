# KPI:er och säkerhetsmätningar – Carl Persson

**Projekt:** Team 3 Blue Team, Chas Academy  
**Underlag:** Teamets säkerhetsrapport, GitHub Actions och individuella bidrag. Senast dokumenterade mätvärden: **3 november 2026**.  
**Klassificering:** **TLP:CLEAR** – denna sanerade text kan delas i kursens GitHub-repository. Råloggar, nycklar, token och kubeconfig ingår inte.

## Ledningssammanfattning

Teamet har verifierat en fungerande säker deployment i den återställda Comerit-miljön, men det går ännu inte att beräkna en tillförlitlig historisk andel lyckade deploymenter. Senaste dokumenterade imageskanning gav **0 Critical** och **44 High-paketträffar fördelade på nio unika CVE:er**; tidsbegränsade riskundantag måste följas upp. Endast **ett av fem** prioriterade detektionsfall är verifierat end-to-end, motsvarande **20 %**. Min bedömning är att **detektionstäckningen är den mest angelägna uppföljningsfrågan**, samtidigt som återställning av Headscale-state och korrekt miljöidentitet måste säkras.

## KPI 1 – Andel lyckade säkra deploymenter

| Fält | Definition |
|---|---|
| **Beslutsfråga** | Kan vi leverera förändringar utan att kringgå säkerhetskontroller eller av misstag nå fel kluster? |
| **Mått** | Andelen relevanta deploymentförsök på `main` där tester, imagebygge, SBOM, Cosign-signering, policykontroll, rätt klusteridentitet och Kubernetes-rollout godkänns. |
| **Beräkning** | `godkända säkra deploymenter / samtliga relevanta deploymentförsök × 100` |
| **Baslinje** | En verifierad lyckad körning den 3 november: [GitHub Actions 41608640621](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621). **Historisk kvot saknas**; en lyckad körning ger inte ett procenttal. |
| **Mål** | Minst **95 %** lyckade säkra deploymenter; **100 %** av godkända körningar ska passera obligatoriska säkerhetssteg. |
| **Datakälla** | GitHub Actions, image-digest, Kubernetes-rollout, klustercertifikat, kontroll av aktuell workload. |
| **Frekvens/ansvar** | Veckovis och efter migration; föreslagen ägare: CI-/Kubernetesansvarig tillsammans med nätverksansvarig. |
| **Vid avvikelse** | Pausa release, identifiera felsteg, verifiera route och klusteridentitet, skapa issue och kör om testet. |

**Analys:** Vid migrationen till Comerit kunde samma privata adress `10.0.3.3` nås via en gammal Headscale-subnet-route och peka mot det gamla klustret. Därför ska ett grönt workflow **inte** ensamt räknas som lyckad deployment i rätt miljö. För att etablera en riktig baslinje måste samtliga relevanta körningar i en avgränsad period räknas och kontrolleras mot rätt målkluster.

**Ledningsbeslut:** Avsätt tid för automatisk kontroll av målmiljö och klusteridentitet innan release godkänns.

## KPI 2 – Öppna Critical-fynd och förfallna riskundantag

| Fält | Definition |
|---|---|
| **Beslutsfråga** | Finns allvarliga eller inte längre godkända sårbarhetsrisker som kräver beslut? |
| **Mått** | Antal öppna Critical-fynd **och** antal förfallna tidsbegränsade High/Critical-undantag; de två delvärdena rapporteras separat. |
| **Beräkning** | `öppna Critical`; `undantag med slutdatum före rapportdatum utan förnyat beslut eller åtgärd`. |
| **Baslinje** | **0 Critical**, **44 High-paketträffar**, **nio unika CVE:er** i senaste dokumenterade image. Nio tidsbegränsade undantag med slutdatum **20 november 2026**. Driftsättningen av den senaste omprövade undantagskonfigurationen var inte slutligt bekräftad i säkerhetsrapporten. |
| **Mål** | **0 öppna Critical** och **0 förfallna undantag**. High-risker ska fortfarande vara synliga. |
| **Datakälla** | Trivy, verifierad CycloneDX-SBOM, scannerjobb, riskundantagsfil, GitHub och Discord-larm. |
| **Frekvens/ansvar** | Vid varje imagebygge och minst dagligen; föreslagen ägare: sårbarhets-/applikationsansvarig. |
| **Vid avvikelse** | Triagera exploaterbarhet, påverkan och kompensatoriska kontroller; blockera vid oacceptabel risk, utse ägare och dokumentera åtgärd eller nytt tidsbegränsat riskbeslut. |

**Analys:** 44 paketträffar är inte 44 separata verifierat exploaterbara sårbarheter. Ett undantag innebär **riskacceptans**, inte att sårbarheten är borttagen. En grön scanner efter ett undantag är därför inte likvärdig med riskfrihet. Innan 20 november behöver ansvariga besluta om uppdatering, kompensatoriska skydd eller uttrycklig omprövning.

**Ledningsbeslut:** Säkerställ ansvarig, beslutsgrund och slutdatum för varje accepterad risk.

## KPI 3 – Verifierad detektionstäckning

| Fält | Definition |
|---|---|
| **Beslutsfråga** | Upptäcker och vidarebefordrar våra kontroller faktiskt prioriterade säkerhetshändelser? |
| **Mått** | Andelen av fem prioriterade fall där loggkälla, regel, notifiering och mottagning har testats end-to-end. |
| **Beräkning** | `godkända end-to-end-detektionstester / 5 × 100` |
| **Baslinje** | **1/5 = 20 %**. Scanner-/sårbarhetslarm med notifiering via Discord är verifierat. Övriga fyra är **inte verifierade**, vilket inte är samma sak som att angrepp bevisligen passerat oupptäckta. |
| **Mål** | **Minst 4/5 = 80 %** nästa förbättringsperiod, därefter 5/5. |
| **Datakälla** | GCP Audit Logs, sshd/OS Login, Headscale-journal och extern hälsokontroll, GitHub Actions, Kubernetes och Discord. |
| **Frekvens/ansvar** | Månadsvis och efter förändring i identitet, nätverk eller larm; föreslagen ägare: detektions-/driftansvarig. |
| **Vid avvikelse** | Lokalisera brist i loggning, korrelation, regel, notifiering eller ansvar; dokumentera och repetera testet. |

| Prioriterat fall | Förväntat verifieringsbevis | Dokumenterad status |
|---|---|---|
| Oväntad SSH-inloggning | Faktisk sshd-session korrelerad med identitet och VM | Ej verifierat end-to-end |
| Ändring i GCP-IAM | Audit Log med aktör, objekt och ändring | Ej verifierat end-to-end |
| Headscale-avbrott | Oberoende hälsokontroll och mottaget larm | Ej verifierat end-to-end |
| Ny sårbar image | Scannerresultat och rätt Discord-notifiering | **Verifierat** |
| Oväntad deployment | GitHub-run, digest och rätt kluster korreleras | Ej verifierat end-to-end |

**Min prioritering:** Testa **Headscale-avbrott** först. Under projektet medförde VM-/zonbyte att Headscale-anslutning och state behövde felsökas. En extern hälsokontroll måste fungera även när själva Tailnet är nere. Testa därefter SSH/OS Login, eftersom molnbehörighetskontroll inte ensam bevisar en genomförd SSH-session.

**Ledningsbeslut:** Avsätt ett avgränsat testtillfälle för de fyra kvarstående fallen med namngiven ansvarig och bevarad evidens.

## Threat intelligence → KPI → åtgärd

MITRE ATT&CK används här för att **modellera möjliga angreppssätt**, inte för att hävda att en angripare observerats i vår Blue Team-miljö.

| Hot-/riskhypotes | MITRE ATT&CK | Detektions-/skyddsåtgärd | KPI-koppling |
|---|---|---|---|
| Missbruk av legitim molnidentitet | [T1078.004 – Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/) | Granska IAM-ändringar, kortlivade identiteter, avvikande inloggningar | KPI 3 |
| Oönskad container i klustret | [T1610 – Deploy Container](https://attack.mitre.org/techniques/T1610/) | Begränsad Kubernetes-RBAC, audit av pod-skapande | KPI 1 och 3 |
| Manipulerade beroenden i leveranskedjan | [T1195.001 – Compromise Software Dependencies and Development Tools](https://attack.mitre.org/techniques/T1195/001/) | SBOM, signering, verifierad attestering och skanning | KPI 1 och 2 |
| Åtkomst till hemligheter i filer | [T1552.001 – Credentials In Files](https://attack.mitre.org/techniques/T1552/001/) | Begränsa secrets-åtkomst och CI-behörigheter | KPI 2 och 3 |

**Actionable intelligence:** Prioritera övervakning av IAM-förändringar och oväntade pod-skapanden, följ upp scannerundantag före 20 november och verifiera att larm når mottagare. Hypoteserna har **måttlig analytisk säkerhet**; miljöns dokumenterade konfiguration och mätresultat har starkare stöd än antaganden om hotaktörers avsikt.

**TLP-motivering:** Denna sammanställning är **TLP:CLEAR** eftersom den är avsedd för offentligt kursrepo och inte innehåller hemligheter eller personliga råloggar. TLP beskriver **spridningsbegränsning**, inte riskens allvar. Känsliga driftuppgifter och credentials ska aldrig publiceras här. [FIRST TLP](https://www.first.org/tlp/).

## Samlad rekommendation till beslutsfattare

| Mått | Nuläge | Mål | Bedömning |
|---|---|---|---|
| Säker deployment | En verifierad körning, historisk kvot okänd | ≥95 % | **Kan ännu inte bedömas** |
| Critical / förfallna undantag | 0 Critical; undantag kräver fortsatt kontroll | 0 / 0 | **Delvis verifierat** |
| Detektionstäckning | 20 % (1 av 5) | ≥80 % | **Under mål** |

För en **teknisk chef** bör KPI 3 visas först tillsammans med exakt vilka fyra testfall som återstår. För **ledning** bör KPI 3 och KPI 2 presenteras tillsammans: *kan vi upptäcka problem och vilka accepterade risker löper ut?* KPI 1 visar om förbättringar samtidigt kan levereras utan driftstörning.

**Källor:** [Teamets säkerhetsrapport](../../blue-team-security-report.md) · [Min individuella bidragsredogörelse](../../carl-individuellt-bidrag.md) · [Individuell slutrapport](individual-report.md) · [Lessons learned](lessons-learned.md).
