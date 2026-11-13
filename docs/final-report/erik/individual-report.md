# Individuell slutrapport

**Namn:** Erik Alduaifi

**Utbildning:** IT- och cybersäkerhetstekniker, Chas Academy

**Projekt:** Team 3 Blue Team, hösten 2026

**Datum:** 2026-11-13

**Underlag:** Dokumenterad projektstatus till och med 3 november 2026, kompletterad med PR-historik hämtad 11 november 2026

**Klassificering:** TLP:CLEAR – sanerad slutrapport avsedd för kursinlämning i offentligt GitHub-repository. Råa hemligheter och känsliga loggar ska hanteras separat.

---

## Syfte och kursmål

Rapporten sammanställer projektets säkerhetsresultat, uppföljning, förbättringsarbete och mina egna reflektioner för en fiktiv ledningsgrupp. Den knyter an till kursmål 4, 9, 10, 11 och 13: säkerhetsmätning och KPI:er, incidentrespons och post-mortem, KPI-rapportering för icke-tekniska beslutsfattare, professionell AI-användning och självständigt projektarbete.

---

## 1. Professionell sammanfattning

Projektet syftade till att bygga och förvalta en säker molnmiljö i Google Cloud Platform (GCP) där all infrastruktur definieras som kod i Terraform och förändringar går genom granskning och automatiska kontroller.

Det viktigaste resultatet ur ledningens perspektiv är att **åtkomsten till miljön nu är spårbar och knuten till personer** i stället för till delade, statiska SSH-nycklar. Med OS Login styrs vem som får logga in, och med vilken behörighet, via Googles identitets- och behörighetssystem (IAM). Personkontonas administratörsbehörighet är dessutom begränsad till enskilda maskiner i stället för hela projektet. Teamet har också infört **blockerande kontroller** som stoppar ändringar som inte klarar säkerhetskontrollerna, och tagit bort åtkomst för en tidigare instruktör.

De största kvarvarande riskerna gäller **behörighetshantering över tid** (att åtkomst inte tas bort när roller ändras) och **hantering av konfigurationsfiler** som kan innehålla känsliga värden. Post-mortem visade dessutom att en tidigare instruktörs åtkomst låg kvar utan att någon kontroll larmade.

Mina tre KPI:er visar att kontrollen över åtkomst förbättras men ännu inte är rutin: alla fem teammedlemmar har administratörsbehörighet på servrarna, begränsad till instansnivå, medan CI-kontot har bred behörighet i hela projektet, 18 av 18 ändringar sedan PR #62 har granskats och passerat blockerande kontroller (100 %), och en fil med verkliga konfigurationsvärden ligger kvar i Git (mål 0).

**Beslut som behövs:** (1) inför kvartalsvis behörighetsgranskning med en namngiven ägare, (2) begränsa CI-kontots projektomfattande behörighet, och (3) flytta alla verkliga variabelvärden till en hemlighetshanterare. Varje åtgärd behöver en ansvarig och ett uppföljningsdatum.

Resultaten bygger på dokumenterad status till och med 3 november 2026 och PR-historik från 11 november. De visar att flera skydd fungerar i labbmiljön, inte att miljön är riskfri eller kontinuerligt övervakad.

---

## 2. Kontext och avgränsning

Projektet gick ut på att som Blue Team bygga och säkra en GCP-miljö med jumphost, primary, Headscale, k3s och en webbapp, och som Red Team angripa separata målmiljöer. All infrastruktur hanterades i ett gemensamt Git-repo med Terraform. Ändringar gick via pull requests där CI körde bland annat `terraform fmt` och `validate`, och deployflödet körde `terraform plan` innan något applicerades. Autentiseringen från GitHub till GCP skedde via Workload Identity Federation (WIF).

**Avgränsningar:** Rapporten omfattar infrastrukturen i infra-repot, främst åtkomststyrning och CI/CD. Applikationssäkerhet och fysisk säkerhet ingår inte. Miljön är en kursmiljö, så verksamhetskonsekvenserna är antagna. Rapporten beskriver inga bekräftade intrång i Blue Team-miljön, och driftstatus återger senaste dokumenterade kontroller snarare än en ny kontroll av dagens läge.

**Underlag:** Teamets säkerhetsrapport, Git-historik och pull requests, Terraform-kod, CI-loggar, teamets dokumentation (`docs/os-login.md`), min bidrags- och AI-redogörelse, `kpi.md` och `lessons-learned.md`.

---

## 3. Mitt individuella bidrag

Mitt ansvar var främst **identitetsbaserad SSH-åtkomst med OS Login** och **hanteringen av Terraform-variabler i repot**.

- **OS Login på jumphosten:** Jag aktiverade `enable-oslogin = "TRUE"` i instansens metadata, så att SSH-åtkomst knyts till Google-identitet och IAM i stället för till statiska nycklar (`4d1344e`).
- **Minsta behörighet:** Jag lade till `google_compute_instance_iam_member.jumphost_os_login`, som tilldelar `roles/compute.osAdminLogin` *på instansnivå*. Administratörer får därmed bara åtkomst till jumphosten och inte till alla VM:ar i projektet (`4d1344e`).
- **Styrning via kod:** Jag skapade variabeln `os_admin_users` med en tom lista som standard, så att ingen får åtkomst av misstag och varje ändring syns i en granskningsbar diff (`cc0aa6b`).
- **`terraform.tfvars`:** Först slutade jag spåra filen och lade till `.example`-filer, så att verkliga värden inte behöver ligga i Git (`d65ce87`). Eftersom CI behövde filen för `terraform plan` återinförde jag den och uppdaterade `.gitignore` för framtida lokala filer (`1424bda`). Variablerna tillhandahölls senare i deploy-workflowet (PR #58).
- **Verifiering:** Jag rättade formateringen så att ändringen klarade `terraform fmt` (`fe86490`). Mina ändringar kontrollerades med `terraform fmt -check` och `terraform validate` i PR-kontrollerna, och deployflödet körde `terraform plan` före apply.

**Samarbete:** Teamet byggde vidare på mitt OS Login-arbete med dokumentation (`docs/os-login.md`) och OS Login på primary (PR #54). Mina ändringar granskades av andra i teamet via pull requests innan de mergades. Min roll var att äga OS Login- och variabeldelen, inte teamets hela säkerhetsarkitektur. Arbete som k3s-återställning, scannerhärdning och Headscale-drift utfördes av andra i teamet.

[Mitt individuella bidrag](../../erik-individuellt-bidrag.md) · [Min AI-redogörelse](../../erik-ai-redogorelse.md)

---

## 4. Viktigaste projektresultat och evidens

### 4.1 Identitetsbaserad och avgränsad SSH-åtkomst

**Resultat:** SSH-åtkomst till jumphosten (och senare primary) går via OS Login, och administratörsrollen är tilldelad per instans.

**Evidens:** Commit `4d1344e`, `cc0aa6b`, PR #54 och `docs/os-login.md`. `terraform plan` i deployflödet visade IAM-ändringarna innan de applicerades.

**Verksamhets- och säkerhetsbetydelse:** Statiska SSH-nycklar kan kopieras, glömmas och delas utan spårbarhet. Med OS Login kan åtkomst återkallas centralt, och varje inloggning kopplas till en person. Instansnivån minskar konsekvensen om ett konto komprometteras.

**Rekommendation:** Gör OS Login obligatoriskt för alla VM:ar och blockera projektgemensamma SSH-nycklar. Ägare: plattformsansvarig. Prioritet: **Hög**.

### 4.2 Konfiguration utanför Git måste lösas tillsammans med CI

**Resultat:** Försöket att sluta spåra `terraform.tfvars` i Git bröt CI-flödet, eftersom `terraform plan` behövde filen. Filen återinfördes, `.example`-filer lades till och variablerna flyttades senare till deploy-workflowet.

**Evidens:** Commit `d65ce87` och `1424bda`, PR #58.

**Verksamhets- och säkerhetsbetydelse:** Verkliga konfigurationsvärden i Git kan nås av alla med åtkomst till repot och finns kvar i historiken. Samtidigt visar händelsen att en säkerhetsåtgärd som bryter driften inte blir långvarig. En fil med verkliga värden ligger fortfarande kvar i Git (KPI 3).

**Rekommendation:** Flytta alla verkliga variabelvärden till GitHub Secrets eller GCP Secret Manager och testa ändringen mot CI innan filen tas bort ur Git. Ägare: DevOps-ansvarig. Prioritet: **Medel**.

### 4.3 Kvarglömd åtkomst kunde tas bort som en kodändring

**Resultat:** En tidigare instruktör hade kvar OS Login-behörighet efter att rollen upphört. Eftersom åtkomsten styrs via variabler i Terraform kunde den tas bort med en granskad kodändring (PR #65). Händelsen är grunden för mitt post-mortem.

**Evidens:** PR #65, [`lessons-learned.md`](lessons-learned.md).

**Verksamhets- och säkerhetsbetydelse:** Kvarglömda behörigheter är en vanlig väg in för angripare. Att åtkomsten togs bort först vid miljöbytet, och inte när rollen upphörde, visar att det saknas en rutin.

**Rekommendation:** Inför en kvartalsvis behörighetsgranskning. Ägare: systemägare/CISO. Prioritet: **Hög**.

---

## 5. KPI:er och ledningsrapportering

Fullständiga definitioner finns i [`kpi.md`](./kpi.md). Alla tre gäller vår egen Blue Team-miljö och bygger på mitt arbete med åtkomst och Terraform.

| KPI | Nuläge | Mål | Fråga till ledningen |
|---|---|---|---|
| 1. Konton med administratörsbehörighet | 5 personer (instansnivå) + 1 CI-konto (projektnivå) | Endast dokumenterade behov, 0 på projektnivå utan beslut | Hur många kan göra allt? |
| 2. Andel ändringar via granskning och CI | 100 % (18/18 sedan 8 okt) | 100 % | Följer alla ändringar våra regler? |
| 3. Filer med känslig konfiguration i Git | 1 (`terraform.tfvars`) | 0 | Ligger känsliga uppgifter öppet? |

**Hur de kommunicerar säkerhetsstatus:** Tillsammans visar de hur väl vi kontrollerar åtkomsten till miljön: *vem* som har makt att ändra, *hur* ändringar görs och om *nycklarna* ligger säkert. Varje KPI kan läsas som en enkel fråga utan teknisk förkunskap.

**Beslut de stödjer:** KPI 1 motiverar en rutin för behörighetsgranskning, KPI 2 visar att granskning och CI-kontroller följs, och KPI 3 motiverar att avsätta tid för en hemlighetshanterare.

**Begränsningar:** KPI:erna mäter förebyggande kontroll, inte detektion. De fångar inte heller ändringar som görs direkt i molnkonsolen utanför Terraform. KPI 3 tar inte hänsyn till att borttagna filer finns kvar i Git-historiken. Som komplement behövs lagets detektions-KPI, Red Team-post-mortem och mitt post-mortem i avsnitt 6. Lagets underlag redovisar dessutom deploymentkvoten olika ("saknas" jämfört med 80 %), vilket visar att datakällor och mätperiod måste fastställas innan siffror rapporteras.

---

## 6. Incidentrespons, post-mortem och förbättringsarbete

Fullständig analys finns i [`lessons-learned.md`](./lessons-learned.md).

**Intrångsförsöket:** Mitt post-mortem gäller ett simulerat intrång via giltig men kvarglömd åtkomst (MITRE T1078.004). En tidigare instruktör hade kvar OS Login-behörighet till våra servrar efter att rollen upphört. Inget missbruk har observerats; scenariot är vad som hade kunnat hända om kontot använts av fel person.

**Upptäckt och hantering:** Åtkomsten togs bort i PR #65 när vi bytte miljö till Comerit, inte när instruktörens roll upphörde. Det var alltså miljöbytet, inte en rutin eller ett larm, som ledde till att den försvann. Att borttagningen var en enkel kodändring berodde på att OS Login-åtkomsten styrs via variabler i Terraform, vilket var min del av lösningen.

**Orsaker och konsekvenser:** Tekniken fungerade, men processen saknades. Det fanns ingen rutin för att ta bort åtkomst vid rollbyte och ingen ägare för behörighetslistan. Behörigheter hade dessutom breddats över tid: alla fem i teamet har sudo, och CI-kontot har bred roll i hela projektet. Inget larm hade utlösts om kontot använts. Red Team-loggarna från kursens separata målmiljöer visar samma mönster, där angrepp syntes i loggarna men inte gav larm.

**Förbättringar:** Organisationen behöver gå från att *kunna* styra åtkomst till att *göra* det regelbundet: en avvecklingsrutin inom en arbetsdag, färre administratörer med namngivet behov och ett testat larm för oväntade SSH-inloggningar.

**Uppföljning:** Antal administratörskonton (KPI 1 i `kpi.md`), tid till borttagen åtkomst (mål ≤ 1 arbetsdag) och ett kontrollerat inloggningstest i teamets detektionsmätning som ska ge larm inom fem minuter.

---

## 7. AI i säkerhetsarbetet

### Konkreta användningsfall

Jag använde Claude och Claude Code i tre typer av arbetsmoment. Det första var att **lära mig nya områden**, framför allt hur OS Login knyter SSH-åtkomst till Google-identiteter, skillnaden mellan `osLogin` och `osAdminLogin` (vanlig inloggning respektive sudo) och hur behörighet kan tilldelas på instansnivå med `google_compute_instance_iam_member`. Det andra var att **tolka felmeddelanden** från `terraform fmt`, `terraform plan` och CI, för att avgöra om felet låg i syntax, formatering, saknade variabler eller resursdefinitionen. Det tredje var att använda AI som **bollplank i designfrågor**, till exempel om `terraform.tfvars` skulle ligga i Git.

### När AI var lämpligt

AI tillförde mest värde när jag snabbt behövde bygga upp en grundförståelse. Den hjälpte mig också att se att Headscale/Tailscale (nätverksåtkomst) och OS Login (vem som får logga in och med vilken behörighet) är två olika lager som kompletterar varandra. Det gjorde det lättare att resonera om vår säkerhetsmodell som helhet och att motivera instansnivå utifrån minsta behörighet. AI var lämpligt här eftersom informationen gick att kontrollera mot GCP:s dokumentation och eftersom felaktiga förklaringar skulle avslöjas i `plan`. Nyttan var att jag kunde lägga mer tid på att förstå och mindre på att leta.

### När AI var olämpligt eller otillräckligt

Rådet att sluta spåra `terraform.tfvars` var generellt rimligt, eftersom det minskar risken att känsliga värden hamnar i repot. I vår miljö gjorde det dock att CI-pipelinen slutade fungera, eftersom `terraform plan` behövde filen. Filen återinfördes, och variablerna flyttades senare till deploy-workflowet. AI kände inte till hur vår pipeline var uppbyggd, så rådet kunde inte följas utan anpassning. Det gäller ännu mer för **IAM-ändringar**. Där kan ett förslag som ser rimligt ut antingen ge för bred åtkomst eller låsa ute användare, och AI bör aldrig vara ensam beslutsgrund.

### Verifiering och mänsklig kontroll

Inga AI-förslag användes utan kontroll. Jag granskade varje ändring som Git-diff och körde `terraform fmt -check` och `terraform validate` i PR-kontrollerna före merge. Deployflödet visade sedan i `terraform plan` exakt vilka resurser som skulle skapas, ändras eller tas bort innan något applicerades. Vid IAM-ändringar kontrollerade jag särskilt vilken roll som tilldelades, på vilken nivå och till vilka konton. Förklaringar jämförde jag med GCP:s officiella dokumentation, och teamet granskade PR:erna. De slutliga besluten byggde alltså på tester, CI-resultat och mänsklig granskning, inte på AI:s svar.

### Risker och professionella gränser

Det största problemet är att **ett välformulerat och säkert formulerat svar ändå kan vara fel**, föråldrat eller fel för den egna miljön, vilket kan leda till övertro. Andra risker är **informationsläckage**: verkliga värden från `terraform.tfvars`, nycklar, tokens eller loggar med personuppgifter ska inte klistras in i en AI-tjänst. Det finns också **bristande spårbarhet** om man inte kan förklara varifrån en ändring kommer. Ansvaret för koden ligger alltid hos den som committar.

### Professionell slutsats

1. Jag använder AI för att lära mig, felsöka och få förslag, men inte för att fatta säkerhetsbeslut.
2. Allt AI föreslår ska gå genom samma kontroller som annan kod: diff, automatiska tester, `plan` och granskning av en kollega.
3. Behörighets- och åtkomständringar kräver att jag själv förstår konsekvensen, inte bara att koden ser rimlig ut.
4. Hemligheter, kunddata och skyddsvärd information delas aldrig med AI-tjänster.
5. Jag ska kunna förklara och motivera varje ändring utan AI.

---

## 8. Prioriterade rekommendationer

| # | Åtgärd | Varför och vilken risk | Prioritet | Ägare |
|---|---|---|---|---|
| 1 | Inför kvartalsvis behörighetsgranskning och en rutin för att ta bort åtkomst vid rollbyte | Kvarglömd åtkomst (jfr PR #65) är en vanlig väg in | Hög | Systemägare/CISO |
| 2 | Kräv OS Login på alla VM:ar och blockera statiska SSH-nycklar | Spårbarhet och central återkallelse av åtkomst | Hög | Plattformsansvarig |
| 3 | Flytta alla verkliga variabelvärden till Secret Manager eller GitHub Secrets och inför hemlighetsskanning | En fil med verkliga värden ligger kvar i Git (KPI 3) | Medel | DevOps |
| 4 | Begränsa CI-kontots `roles/compute.admin` till de operationer pipelinen behöver | En komprometterad pipeline kan påverka hela projektet (KPI 1, risk B02) | Hög | Plattformsansvarig |

---

## 9. Individuell reflektion

### Vad kan jag nu som jag inte kunde när kursen började?

Jag kan styra åtkomst till virtuella maskiner i GCP med identitet och IAM i stället för statiska nycklar, och avgränsa behörigheter till en enskild resurs. Till exempel kan jag motivera varför `osAdminLogin` på instansnivå är säkrare än på projektnivå. Innan kursen hade jag aldrig arbetat med IAM i GCP. Nu kan jag skriva Terraform-kod som ger rätt person rätt behörighet på rätt resurs, och förklara konsekvenserna.

### Vilket moment har förändrat mitt sätt att arbeta med cybersäkerhet mest?

Arbetet med OS Login förändrade mest hur jag tänker. Jag förstod att åtkomst sker i flera lager: Headscale/Tailscale avgör om man når nätverket, och OS Login avgör vem som får logga in och med vilken behörighet. Tidigare såg jag åtkomst som en enda fråga, men nu ser jag att varje lager behöver skyddas och följas upp för sig. Arbetet med `terraform.tfvars` förändrade också mitt arbetssätt. Jag lärde mig att en säkerhetsåtgärd som ser rätt ut i teorin måste testas mot hur pipelinen faktiskt fungerar, annars backas den tillbaka och risken finns kvar.

### Vad skulle jag göra annorlunda om projektet började idag?

Jag skulle undersöka hur CI-pipelinen använder filer *innan* jag ändrar hur de spåras i Git. Ändringen av `terraform.tfvars` bröt pipelinen eftersom jag inte hade kartlagt beroendet. Jag skulle också börja med att mäta. Under projektet förbättrade vi behörigheter och kontroller, men vi tog inte fram baslinjer innan vi ändrade något, så det är svårt att visa förbättringen i siffror.

### Vad tar jag med mig till LIA och min framtida yrkesroll?

1. Minsta behörighet i praktiken: att avgränsa roller till resurs och inte till hela projektet.
2. Arbetssättet med infrastruktur som kod, PR-granskning och `plan` före ändring.
3. Att alltid ta fram en baslinje innan en förbättring, så att effekten går att visa för en beslutsfattare.

På LIA vill jag kunna komma in i en ny molnmiljö, läsa vem som har vilken behörighet och föreslå konkreta begränsningar med evidens från koden, inte bara med generella råd.

---

## 10. Källor och referenser

**Källor:** [Teamets säkerhetsrapport](../../blue-team-security-report.md) · [Min individuella bidragsredogörelse](../../erik-individuellt-bidrag.md) · [Min AI-redogörelse](../../erik-ai-redogorelse.md) · [KPI:er och säkerhetsmätningar](kpi.md) · [Lessons learned](lessons-learned.md)

- **Projektets evidens:** egna commits `4d1344e`, `fe86490`, `cc0aa6b`, `d65ce87`, `1424bda`; teamets PR #54, #58, #65 och #70; post-mortem-loggar för Team 3 (A_original och B_testfonster).
- **Externa källor:** Google Cloud, *About OS Login* och *IAM overview*; HashiCorp, *google_compute_instance_iam* (Terraform Registry); MITRE ATT&CK; FIRST, *Traffic Light Protocol*.
- **Kursmaterial:** uppgiftsbeskrivningen och mallen för individuell slutrapport.
- **AI-stöd:** Claude användes under projektet enligt avsnitt 7. Förslagen verifierades mot projektkonfiguration, Git-historik, säkerhetsrapporten och egna testresultat.
- **Egna bedömningar:** prioriteringar i avsnitt 4 och 8, KPI-val samt reflektionen i avsnitt 9.

---

## Slutkontroll

- [x] Jag har tydligt beskrivit mitt eget bidrag och länkat till relevant underlag.
- [x] Mina viktigaste resultat stöds av evidens och källor.
- [x] Mina KPI:er är anpassade för en icke-teknisk beslutsfattare.
- [x] Mitt post-mortem leder till konkreta förbättringar och uppföljning.
- [x] Jag har beskrivit konkret AI-användning och självständigt värderat när AI är lämpligt eller olämpligt.
- [x] Jag har beskrivit hur AI-genererade resultat verifierades.
- [x] Mina rekommendationer följer av analysen och är prioriterade.
- [x] Den professionella sammanfattningen fungerar fristående.
- [x] Min individuella reflektion innehåller konkreta exempel.
- [x] Källor, länkar och referenser fungerar.
- [ ] Inga lösenord, tokens, API-nycklar, personuppgifter eller andra skyddsvärda uppgifter finns i repositoryt. Inga hemligheter finns, men teammedlemmarnas e-postadresser ligger i `terraform.tfvars.example` och i Git-historiken.
- [x] Alla ändringar är committade och pushade till GitHub.
