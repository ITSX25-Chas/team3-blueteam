# KPI:er och säkerhetsmätningar

**Student:** Erik Alduaifi

**Utbildning:** IT- och cybersäkerhetstekniker, Chas Academy

**Projekt:** Team 3 Blue Team, hösten 2026

**Datum:** 2026-11-11

**Underlag:** Dokumenterad projektstatus till och med 3 november 2026, kompletterad med PR-historik hämtad 11 november 2026

**Klassificering:** TLP:CLEAR – sanerad KPI-rapport avsedd för kursinlämning i offentligt GitHub-repository. Råa hemligheter och känsliga loggar ska hanteras separat.

## KPI 1 – Konton med administratörsbehörighet

| Fält | Innehåll |
|---|---|
| Syfte | Visa hur många som kan göra stora ändringar på våra servrar och om behörigheten är motiverad och avgränsad. |
| Definition | Antal personkonton och tjänstekonton med administratörsbehörighet (sudo via `roles/compute.osAdminLogin` eller breda roller som `roles/compute.admin`), samt på vilken nivå rollen är tilldelad: enskild server eller hela projektet. |
| Formel | `antal konton i os_admin_users` + `antal admin-roller på projektnivå` |
| Datakälla | Terraform (`os_admin_users`, `google_compute_instance_iam_member`), GCP IAM och Git-historik. |
| Mottagare | Systemägare och ledningsgrupp. |
| Frekvens | Kvartalsvis samt vid rollbyten. |
| Nuläge | 5 konton har administratörsbehörighet efter PR #70, det vill säga hela teamet. 1 konto har vanlig inloggning. Personkontonas roller är tilldelade på instansnivå. Dessutom har CI-tjänstekontot `roles/compute.admin` på projektnivå (säkerhetsrapportens risk B02). Totalt: 5 personkonton på instansnivå och 1 tjänstekonto på projektnivå. |
| Mål | Endast konton med dokumenterat behov har admin-behörighet. CI-kontots roll begränsad till de operationer pipelinen behöver; 0 projektomfattande admin-roller utan beslut. |
| Åtgärd vid avvikelse | Ta bort eller begränsa behörigheten via PR, kontrollera i Audit Logs om den använts och uppdatera listan över behov. |
| Evidens | Commit `4d1344e` och `cc0aa6b` (OS Login och admin-roll på instansnivå), PR #65 (borttagen instruktörsåtkomst), PR #70 (sudo för teamet), säkerhetsrapporten avsnitt 4 och risk B02. |

**Egen motivering:** Jag byggde OS Login-lösningen och valde att tilldela admin-rollen på instansnivå, så att en administratör bara når den server som behövs. Det minskar konsekvensen om ett konto komprometteras. Samtidigt visar KPI:n att alla fem i teamet nu har sudo. Det var praktiskt under projektet, men i en verklig organisation behöver de flesta troligen bara vanlig inloggning. Att instruktörens åtkomst fick upptäckas manuellt (PR #65) visar varför siffran behöver följas upp regelbundet. KPI:n visar också att den största behörigheten inte ligger hos en person utan hos CI-tjänstekontot, som har `roles/compute.admin` på hela projektet. Ett komprometterat pipelineflöde kan därför påverka fler resurser än en enskild administratör. En begränsning är att KPI:n visar vem som *kan* göra ändringar, inte om behörigheten faktiskt missbrukas; det kräver loggar.

## KPI 2 – Andel ändringar via granskning och CI

| Fält | Innehåll |
|---|---|
| Syfte | Visa om infrastrukturen bara ändras på det sätt vi har bestämt, med granskning och automatiska säkerhetskontroller. |
| Definition | Andel ändringar på `main` som gått via pull request med godkänd granskning och godkända kontroller (TFLint, Checkov, `terraform fmt`, `validate` och `plan`). |
| Formel | `godkända och granskade PR-mergar / alla ändringar på main × 100` |
| Datakälla | GitHub (PR-historik, granskningar, Actions-körningar och ruleset för `main`). |
| Mottagare | IT-chef och ledningsgrupp. |
| Frekvens | Månadsvis. |
| Nuläge | 18 av 18 mergade PR:er sedan PR #62 (8 oktober) har godkänd granskning och godkända kontroller: 100 %. Kravet sänktes från två till ett godkännande när teamet gick över till rapportskrivning. Infra-repots `main` skyddas av ett aktivt GitHub-ruleset som kräver granskning och kontrollen Format & Validate samt blockerar force-push och radering, så direkta pushar förhindras. Eventuella bypass-aktörer är inte granskade. |
| Mål | 100 %, två godkännanden för infrastrukturändringar och granskade bypass-aktörer i rulesetet. |
| Åtgärd vid avvikelse | Granska ändringen i efterhand, kontrollera att `plan` och faktisk miljö stämmer och skärp rulesetet. |
| Evidens | PR #62 (TFLint och Checkov blockerande i stället för `soft_fail`, GitHub OIDC begränsad till `main`), lista över mergade PR:er sedan 2026-10-08, säkerhetsrapporten avsnitt 4 (aktivt ruleset). |

**Egen motivering:** Eftersom hela miljön är definierad i Terraform blir en okontrollerad ändring i repot en okontrollerad ändring i molnet. Mina egna ändringar, till exempel OS Login, kontrollerades på detta sätt innan de applicerades, och jag mergade själv PR #62. KPI:n visar också en svaghet: när granskningskravet sänktes från två till ett godkännande blev andelen fortfarande 100 %. En kontroll kan alltså försvagas utan att siffran märker det, och därför ska KPI:n alltid rapporteras tillsammans med vilket granskningskrav som gällde. Den fångar inte heller ändringar som görs direkt i GCP-konsolen.

## KPI 3 – Filer med känslig konfiguration i Git

| Fält | Innehåll |
|---|---|
| Syfte | Visa om verkliga konfigurationsvärden eller hemligheter ligger i kod som många har tillgång till. |
| Definition | Antal spårade filer i repot med verkliga miljövärden eller hemligheter (till exempel `terraform.tfvars`, nycklar och token) samt antal fynd från hemlighetsskanning. |
| Formel | `antal spårade känsliga filer + antal öppna skanningsfynd` |
| Datakälla | Git-historik, `.gitignore`, CI-konfiguration och GitHub secret scanning. |
| Mottagare | IT-chef och ledningsgrupp. |
| Frekvens | Vid varje PR (automatisk skanning) och månadsvis. |
| Nuläge | 1 fil: `terraform.tfvars` spåras i Git eftersom CI behövde den. `.example`-filer finns och `.gitignore` är uppdaterad. Flytten av variabler till deploy-workflowet har påbörjats (PR #58). Hemlighetsskanning har inte körts. |
| Mål | 0 spårade filer med verkliga värden. Alla variabler hämtas från GitHub Secrets eller GCP Secret Manager. |
| Åtgärd vid avvikelse | Ta bort filen ur Git, byt ut exponerade värden och flytta värdet till hemlighetshanteraren. |
| Evidens | Commit `d65ce87` (slutade spåra filen), `1424bda` (återinförd för CI), PR #58 (variabler i deploy-workflow). |

**Egen motivering:** Den här KPI:n kommer direkt ur mitt eget arbete. Att sluta spåra `terraform.tfvars` var rätt i princip, men det bröt CI, och filen fick läggas tillbaka. Det visar att säkerhet och fungerande drift måste lösas tillsammans och inte var för sig. En begränsning är att en fil som tagits bort ur Git ändå finns kvar i historiken. Har den innehållit hemligheter måste de bytas ut, inte bara raderas.

## Samlad ledningsrapportering

| KPI | Nuläge | Mål | Ledningssignal |
|---|---:|---:|---|
| Konton med administratörsbehörighet | 5 + 1 | Endast dokumenterade behov | Teamet har sudo på enskilda servrar; CI-kontot har bred behörighet i hela projektet |
| Ändringar via granskning och CI | 100 % (18/18) | 100 % | Alla ändringar granskas, men kravet har sänkts från två till ett godkännande |
| Filer med känslig konfiguration i Git | 1 | 0 | Känd risk där åtgärden har påbörjats |

Jag valde just dessa tre KPI:er eftersom de bygger på mitt eget arbete och tillsammans visar **hur väl vi kontrollerar åtkomsten till vår miljö**. KPI 1 visar *vem* som kan göra stora ändringar. KPI 2 visar *hur* ändringar görs. KPI 3 visar om *nycklarna* till miljön ligger säkert. En icke-teknisk beslutsfattare behöver inte förstå Terraform eller IAM för att förstå frågorna "hur många kan göra allt?", "följer alla ändringar våra regler?" och "ligger känsliga uppgifter öppet?".

**Trend att uppmärksamma:** Utvecklingen går åt rätt håll. Admin-åtkomsten är begränsad till enskilda servrar, kontrollerna har varit blockerande sedan PR #62 och flytten av variabler ur Git har påbörjats. Det finns ett undantag: kravet på granskning sänktes från två till ett godkännande. Det bör återställas innan nya infrastrukturändringar görs. Förbättringarna har dessutom skett genom enskilda insatser och inte genom fasta rutiner.

**Beslut som KPI:erna stödjer:** De stödjer tre beslut. Det första är att införa kvartalsvis behörighetsgranskning med en namngiven ägare och begränsa CI-kontots projektomfattande roll. Det andra är att återinföra två godkännanden och granska rulesetets bypass-aktörer. Det tredje är att avsätta tid för att flytta alla variabler till en hemlighetshanterare.

**Vad KPI:erna inte visar:** De mäter förebyggande kontroll, inte om ett angrepp faktiskt upptäcks. De fångar inte heller ändringar som görs direkt i molnkonsolen. Som komplement behövs lagets detektions-KPI, Red Team-post-mortem och en regelbunden kontroll av att koden och den verkliga miljön stämmer överens.

**Källor:** [Teamets säkerhetsrapport](../../blue-team-security-report.md) · [Min individuella bidragsredogörelse](../../erik-individuellt-bidrag.md) · [Individuell slutrapport](individual-report.md) · [Lessons learned](lessons-learned.md)
