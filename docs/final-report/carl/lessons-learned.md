# Lessons learned, post-mortem och professionell sammanfattning – Carl Persson

**Projekt:** Team 3 Blue Team · **Underlag till och med:** 3 november 2026  
**Klassificering:** TLP:CLEAR – sanerad rapport för offentlig kursinlämning. Känslig råevidens delas inte här.

## Sammanfattning för beslutsfattare

Team 3 har byggt en säkerhetsarkitektur i Google Cloud med Terraform, OS Login, begränsade nätverksregler, Headscale/Tailscale, k3s och en leveranskedja med SBOM, imagesignering, sårbarhetsskanning och notifiering. Efter flytten till Comerits projekt verifierades den 3 november en fungerande applikation (`1/1 Ready`, HTTP 200), aktiv NetworkPolicy och Sigstore-policy i `enforce` i det återställda klustret. Säkerhetsarbetet gav därmed konkreta skydd och en spårbar leveransprocess.

De största kvarstående riskerna är inte bara sårbara paket, utan **återställningsbarhet, identitetsbegränsning och bevisad detektionsförmåga**. Headscale-state förlorades vid VM-ersättning; efter migration nådde en pipeline först fel kluster genom en gammal route; och endast ett av fem prioriterade detektionsfall hade verifierats end-to-end. Ledningens prioriterade beslut bör vara att finansiera/testa återställning, minska kvarvarande behörigheter och avsätta tid för detektionstester.

## Lärdom 1 – Infrastruktur som kod återställer inte automatiskt tjänstens state

**Händelse:** När jumphosten ersattes efter zonproblem förändrades SSH-hostkey och Headscale-registrering/state behövde återskapas. Vid senare flytt till Comerits GCP-projekt fanns VM-resurserna men nya primary saknade k3s.

**Orsak:** Terraform beskriver resurser som VM, nät, brandvägg och routes, men hela Headscale-databasen, servernycklar, klientregistreringar och k3s-bootstrap var inte fullständigt beständiga eller deklarerade i samma återställningskedja.

**Konsekvens:** Åtkomst och deployment påverkades. En lyckad `terraform apply` och GCP-statusen `RUNNING` kunde inte användas som bevis för att den faktiska tjänsten var återställd.

**Min roll och lärdom:** Jag arbetade med GCP, SSH, Headscale/Tailscale och felsökning vid zonflytten. Jag lärde mig att först skilja på VM-livscykel, nätverksväg och tjänstens beständiga identitet. Jag borde ha identifierat var Headscale-state lagrades och vilken återställningsplan som fanns innan en maskin behövde ersättas.

**Förbättring:** Inför säkerhetskopiering av Headscale-databas och nyckelmaterial med begränsad åtkomst, dokumentera beroenden till GitHub-secrets, versionsstyr k3s-bootstrap och genomför ett kontrollerat återställningstest. **Klart när:** en ny VM kan ersätta den gamla och klienter, ACL, DNS, routes och applikation fungerar enligt testprotokoll.

**Evidens:** [Individuellt bidrag](../../carl-individuellt-bidrag.md), [säkerhetsrapportens incidenter](../../blue-team-security-report.md), [återställningsguide](../../restore-primary-k3s.md).

## Lärdom 2 – En grön pipeline kan verifiera fel miljö

**Händelse:** Efter migration kunde app-pipelinen nå `10.0.3.3`, men trafiken gick först till gamla Kubernetes-klustret via en tidigare annonserad subnet-route för `10.0.3.0/24`. Skillnaden avslöjades genom klustercertifikat/fingerprint.

**Orsak:** Samma interna IP-nät användes i gammal och ny miljö. En kvarvarande Headscale-route och äldre autentiseringsmaterial gjorde att anslutningskontrollen inte ensam visade vilken miljö som användes.

**Konsekvens:** Det fanns risk för falskt godkänd deployment och för att ändringar hamnade i fel kluster. Teamet återställde k3s, registrerade rätt subnet-router, tog bort den gamla routen och roterade kubeconfig. Efteråt lyckades [körning 41608640621](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621), och applikationen verifierades i nya miljön.

**Min roll och lärdom:** Jag gjorde tidigare en egen [ändring för Spectre-routing och split DNS](https://github.com/ITSX25-Chas/team3-blueteam/commit/88d73d48) och felsökte intern kontra publik åtkomst. Därför är detta en viktig slutsats för mig, även om återställningen den 3 november var ett **teamresultat**. Jag skulle framöver kräva kontroll av miljöidentitet innan en release räknas som lyckad.

**Förbättring:** Lägg in kontroller av GCP-projekt, Tailnet-routeägare, Kubernetes-certifikat, image-digest och `/healthz` i releasechecklistan. **Klart när:** varje deployment kan knytas till rätt projekt, kluster och workload – inte bara en IP-adress.

**Evidens:** [Säkerhetsrapport](../../blue-team-security-report.md), [k3s-återställningsguide](../../restore-primary-k3s.md), [min routing-commit](https://github.com/ITSX25-Chas/team3-blueteam/commit/88d73d48).

## Lärdom 3 – Minsta behörighet och detektion måste provas praktiskt

**Händelse:** Teamets RBAC-granskning visade att en deployidentitet kunde sakna direkt rätt att läsa secrets men ändå nå dem indirekt genom att ändra ett scanner-CronJob. Den möjligheten togs bort; kvar finns viss secret-läsning/-uppdatering i applikationens namespace. Samtidigt var bara **1/5 = 20 %** prioriterade detektionstester verifierade end-to-end.

**Orsak:** Behörigheter hade delvis bedömts som enskilda API-rättigheter, snarare än möjliga kedjor av åtgärder. För detektion hade loggkällor och larmvägar inte konsekvent prövats med kontrollerade händelser och sparad evidens.

**Konsekvens:** En komprometterad identitet kan få större effekt än en snabb RBAC-kontroll antyder. Vid en faktisk incident kan teamet sakna bevis för att ett larm når ansvarig mottagare.

**Min roll och lärdom:** Jag arbetade själv med [Headscale-ACL:er för användargrupper](https://github.com/ITSX25-Chas/team3-blueteam/commit/92af4437). Den konkreta RBAC-eskaleringsvägen var ett **gemensamt teamfynd**, inte mitt personliga test. Jag ser samma princip i Tailnet: medlemskap eller en nekad direktoperation räcker inte som bevis för att alla indirekta vägar är stängda.

**Förbättring:** Testa positiva och negativa behörighetsfall för alla roller; granska pod-/jobbrättigheter, begränsa CI-identiteter och genomför fyra kvarvarande end-to-end-detektionstester. Prioritera Headscale-avbrott och SSH/OS Login. **Klart när:** minst fyra av fem larmfall har reproducerbar evidens och kritiska indirekta åtkomstvägar är blockerade.

**Evidens:** [Säkerhetsrapportens B04 och detektionsavsnitt](../../blue-team-security-report.md), [KPI:er](kpi.md).

## Post-mortem: händelse, respons och förbättring

**Avgränsning:** Detta är en teknisk efteranalys av **dokumenterade drift- och säkerhetshändelser i vårt Blue Team-projekt**. Det är inte en påstådd bekräftad angriparincident, och vi har inte försvarslagets detektionsresultat från den separata Red Team-övningen.

| Fas | Dokumenterat förlopp | Slutsats |
|---|---|---|
| **Upptäckt** | Anslutningsfel efter jumphost-ersättning; fel klustercertifikat/route efter Comerit-flytt; Secure Boot gav GRUB-/signaturfel trots VM-status `RUNNING`. | Kontrollera faktiska tjänster och identiteter, inte bara molnstatus. |
| **Analys** | SSH-hostkey, Headscale-state, DNS/routing och certifikat jämfördes med förväntad miljö. | Samma symptom kan ha olika rotorsak; arbeta lager för lager. |
| **Begränsning** | Felaktig Secure Boot-inställning återställdes; gammal subnet-route togs bort. | Säkerhetsförändringar måste ha återställningsväg. |
| **Återställning** | Headscale-anslutningar återregistrerades efter VM-byte; k3s, route och kubeconfig återställdes i Comerit; applikationen verifierades. | Funktionstest måste kompletteras med identitets- och säkerhetskontroll. |
| **Uppföljning** | Dokumentation, issues, PR:er och återställningsguide skapades. | Automatisera återställning och verifiera larm innan nästa större ändring. |

**Kvarstående evidensluckor:** Ingen fullständig mätning av avbrottstid, ingen bevisad återläsning av Headscale-backup och ingen komplett tabletop-/detektionsövning. Därför redovisas inte MTTD eller MTTR som om de vore uppmätta.

## Threat intelligence → åtgärd och uppföljning

MITRE ATT&CK används här för att beskriva **möjliga angriparbeteenden**, inte för att påstå att en hotaktör faktiskt angripit teamet.

| Hot- eller riskscenario | ATT&CK | Prioriterad actionable intelligence | Uppföljning |
|---|---|---|---|
| Missbruk av giltig GCP-/CI-identitet | [T1078.004 – Valid Accounts: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/) | Granska projektomfattande IAM, använd kortlivade identiteter, larma på ovanliga IAM-ändringar och korrelera aktör/tid. | Detektionstest för IAM och öppna behörighetsavvikelser. |
| Missbruk av deploybehörighet för att starta pod | [T1610 – Deploy Container](https://attack.mitre.org/techniques/T1610/) | Neka oönskat pod-/CronJob-skapande, separera scanneradministration och granska Kubernetes Audit. | Negativa RBAC-test och larm på oväntad workload. |
| Åtkomst till credentials i filer/secrets | [T1552.001 – Credentials In Files](https://attack.mitre.org/techniques/T1552/001/) | Begränsa secret-läsning och tokenlivslängd; lagra inte hemligheter i Git/loggar. | RBAC-test, secret-åtkomstgranskning. |
| Försvagning av scanner eller säkerhetskontroll | [T1562.001 – Impair Defenses](https://attack.mitre.org/techniques/T1562/001/) | Lås scanner-version, verifiera attestering och bevaka ändrade undantag/CI-steg. | KPI 2 och kontroll av blockerande pipeline. |

**Tillförlitlighet:** Teknikerna är relevanta hypoteser utifrån dokumenterade behörigheter och kontrollbrister; ingen attribution eller observerad exploatering kan styrkas. **TLP:CLEAR** är motiverat eftersom denna text är sanerad och avsedd för offentlig kursinlämning; detaljerade råloggar och hemligheter ska bedömas separat. [FIRST TLP](https://www.first.org/tlp/).

## Rekommendationer till ledningen

1. **Omedelbart – säkra återställningsbarhet.** Utse infrastrukturansvarig för Headscale-backup, nyckelhantering och återställningstest. Godkänn inte lösningen förrän en ersättnings-VM fungerar utan manuell improvisation.
2. **Nästa förbättringsperiod – verifiera detektion.** Ge drift-/säkerhetsansvarig tid för fyra återstående tester, börja med Headscale och SSH/OS Login. Mät andelen i [KPI 3](kpi.md).
3. **Löpande – minska identitets- och leveransrisk.** Begränsa kvarvarande CI-/secret-behörigheter, ompröva tidsbegränsade CVE-undantag före 20 november och kräv miljöidentitet i releasekontroller.

## Min professionella slutsats

Det som fungerade bäst var spårbara ändringar i Git, tester efter ändring och ett samarbete där infrastruktur, applikation och CI/CD kunde felsökas tillsammans. Det som skapade mest osäkerhet var antagandet att rätt kod eller rätt IP-adress automatiskt betydde rätt driftläge. Jag tar med mig ett mer disciplinerat arbetssätt: **observera → samla evidens → avgränsa rotorsak → ändra kontrollerat → verifiera → dokumentera restrisk**. För en framtida roll inom säkerhetsdrift och SOC/SIEM är kopplingen mellan logg, identitet, nätverkshändelse och åtgärdsbeslut särskilt viktig.

**Referenser:** [Teamets säkerhetsrapport](../../blue-team-security-report.md) · [Min bidragsredogörelse](../../carl-individuellt-bidrag.md) · [AI-redogörelse](../../carl-ai-redogorelse.md) · [Individuell slutrapport](individual-report.md).