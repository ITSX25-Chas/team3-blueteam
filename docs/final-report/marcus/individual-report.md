# Individuell slutrapport

- **Namn:** Marcus Gustafsson
- **Projekt/team:** Team 3 Blue Team
- **Datum:** 2026-11-13

## Syfte och kursmål

Rapporten sammanställer projektets säkerhetsresultat, uppföljning, förbättringsarbete och mina egna reflektioner för en fiktiv ledningsgrupp. Den knyter an till kursmål 4, 9, 10, 11 och 13: säkerhetsmätning, incidentrespons, KPI-rapportering, professionell AI-användning och självständigt projektarbete.

---

## 1. Professionell sammanfattning

Team 3 genomförde ett Blue Team-projekt för att stärka och verifiera säkerheten i en GCP- och k3s-baserad labbmiljö för en containeriserad applikation. Arbetet omfattade identitets- och nätverkskontroller, CI/CD, signerade images och SBOM, Kubernetes-RBAC, NetworkPolicy, sårbarhetsskanning och larmning. En kontrollerad genomgång visade att en scannerbehörighet kunde ha nått monterade secrets indirekt via en CronJob trots att direkt secret-läsning var spärrad; inget faktiskt läckage är belagt. Miljöbytet visade dessutom att VM:er som kan återskapas med Terraform inte automatiskt återställer Headscale-state, k3s eller routes, och en gammal route ledde först deploymenten till fel kluster. Teamet tog bort scanner-apply från appens pipeline och verifierade efter migration att rätt nod och applikation var tillgängliga; deployment 41608640621 passerade de dokumenterade kontrollerna. Resultaten visar att flera skydd fungerade i den verifierade testmiljön, men inte att alla kontroller är fullständiga eller kontinuerligt övervakade. KPI:erna följer andelen säkra deploymenter, öppna Critical-fynd plus utgångna riskundantag och testad detektionstäckning, men baslinjerna är ännu begränsade. Den senaste dokumenterade skanningen visade 0 Critical, 44 High-paketträffar och nio tidsbegränsade undantag; statusen behöver uppdateras innan ledningen fattar beslut om nuläget. Ledningen bör prioritera minsta behörighet, verifierad återställning och kontroll av klusteridentitet före deployment. Varje förbättring behöver en ansvarig och ett uppföljningsdatum, särskilt för kvarvarande secret-åtkomst, riskundantag och detektionstester.

---

## 2. Kontext och avgränsning

Projektet var ett Blue Team-labb under kursen Avancerad IT-säkerhet. Teamet byggde och granskade skydd för en containeriserad webbapplikation i GCP och k3s, med Headscale/Tailscale för nätverksåtkomst och GitHub Actions för CI/CD. Rapporten bygger på teamets säkerhetsrapport, versionshanterad Terraform- och Kubernetes-konfiguration, Git-historik, pull requests, GitHub Actions-resultat samt mina dokumenterade bidrag och AI-redogörelse. Analysen omfattar även en kontrollerad genomgång av en möjlig RBAC-väg från scanner-CronJob till monterade secrets. Den beskriver inte ett bekräftat intrång; ingen faktisk secret-läsning eller angriparattribution är belagd. Skanningsresultat och driftstatus återger senaste dokumenterade kontroller, huvudsakligen från 3 november 2026, och ska inte tolkas som en ny kontroll av dagens läge. Labben motsvarar inte en fullständigt övervakad produktionsmiljö.

---

## 3. Mitt individuella bidrag

Mitt individuella arbete fokuserade främst på Headscale/Tailscale, åtkomstpolicy och felsökning. Jag lade till en Headscale-policy som gav studentgruppen åtkomst till Spectre på 10.0.0.2:443, korrigerade användarreferenser och lade till DNS-åtkomst till Headscale på 100.64.0.2:53. Ändringarna går att spåra i commits dea72e1, a4855ae och 13e3f08. Jag testade också att återaktivera Secure Boot på jumphosten. Det ledde till uppstartsproblem och ändringen återställdes; jag beskriver det därför som ett test och en felsökningslärdom, inte som en färdig härdningsåtgärd.

Efter zonflytten felsökte jag klientanslutning från min Mac. Jag testade DNS och SSH och tog bort en gammal värdnyckel ur known_hosts så att anslutningen fungerade igen. Det verifierade inte i sig den nya serverns identitet; fingeravtrycket behöver jämföras med en betrodd källa. Själva Headscale-åtgärden utfördes av en gruppkamrat, vilket jag skiljer från mitt eget arbete. Jag deltog också i genomgång och test av den simulerade RBAC-vägen via scanner-CronJob till monterade secrets. Teamet genomförde den efterföljande ändringen i appens pipeline. Min roll var att bidra till felsökning, åtkomstanalys och verifiering, inte att ensam äga hela teamets säkerhetsarkitektur.

[Mina dokumenterade bidrag](../../marcus-individuellt-bidrag.md) · [Min AI-redogörelse](../../marcus-ai-redogorelse.md)

---

## 4. Viktigaste projektresultat och evidens

### Resultat 1 – Headscale-åtkomst och DNS-policyn blev mer ändamålsenlig

**Resultat:** Jag lade till och korrigerade Headscale-regler för studentåtkomst till Spectre och DNS till Headscale.

**Evidens:** [Commit dea72e1](https://github.com/ITSX25-Chas/team3-blueteam/commit/dea72e1), [commit a4855ae](https://github.com/ITSX25-Chas/team3-blueteam/commit/a4855ae), [commit 13e3f08](https://github.com/ITSX25-Chas/team3-blueteam/commit/13e3f08) och [mitt individuella bidrag](../../marcus-individuellt-bidrag.md).

**Verksamhets- och säkerhetsbetydelse:** Tydliga accessregler gjorde önskad åtkomst möjlig och gav en konkret policy att granska. Policyn måste fortfarande testas från avsedda roller och tillsammans med DNS och routes; en konfigurationsändring ensam bevisar inte att åtkomsten fungerar säkert.

**Rekommendation:** Behåll reglerna versionsstyrda och testa både tillåten och nekad åtkomst efter policyändringar. Ägare: plattforms-/nätverksansvarig. Prioritet: löpande.

### Resultat 2 – En indirekt väg till monterade secrets identifierades

**Resultat:** En kontrollerad RBAC-genomgång visade att nekad direktläsning av en Secret inte i sig uteslöt åtkomst via en scanner-CronJob. Teamet tog bort scanner-apply från appens pipeline och verifierade begränsningar i klustret.

**Evidens:** [Säkerhetsrapport, avsnitt 5](../../blue-team-security-report.md#5-prioriterade-kvarvarande-risker) och [appens PR #26](https://github.com/ITSX25-Chas/Team3-ThaCompany/pull/26).

**Verksamhets- och säkerhetsbetydelse:** Om en CI-identitet komprometteras kan indirekta behörighetskedjor öka konsekvensen. Ingen faktisk secret-läsning är belagd, och rapporten anger att appens pipeline fortfarande har läs-/skrivåtkomst till applikationshemligheter i namespace default.

**Rekommendation:** Granska den kvarvarande secret-åtkomsten och testa både direkta och indirekta rättighetsvägar. Ägare: app-/IAM-ansvarig. Prioritet: hög.

### Resultat 3 – Miljöidentitet och återställning behövde verifieras separat

**Resultat:** Efter miljöflytten nådde en gammal route först det tidigare klustret trots att den interna adressen var densamma. Certifikat, route och faktisk workload behövde jämföras. Efter korrigeringen passerade deployment 41608640621 och appen verifierades i den återställda miljön.

**Evidens:** [Säkerhetsrapport, avsnitt 6](../../blue-team-security-report.md#6-incidenter-och-lärdomar), [deployment 41608640621](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621) och [min AI-redogörelse om felsökningen](../../marcus-ai-redogorelse.md).

**Verksamhets- och säkerhetsbetydelse:** En grön nätverkskontroll eller pipeline kan ge falsk trygghet om den inte bevisar vilken miljö som nåddes. Återskapade VM-resurser återställer inte automatiskt Headscale-state, k3s eller routes.

**Rekommendation:** Automatisera återställning och verifiera projekt, klusteridentitet, certifikat och workload före deployment. Ägare: plattforms-/CI-ansvarig. Prioritet: hög.

---

## 5. KPI:er och ledningsrapportering

De tre KPI:erna kompletterar varandra: andelen säkra deploymenter visar leveranskvalitet, Critical-fynd och utgångna undantag visar aktuell sårbarhetsrisk, och testad detektionstäckning visar om larmkedjan fungerar från händelse till evidens. De är skrivna för att ledningen ska kunna prioritera risk och ansvar utan att läsa scannerloggar eller Kubernetes-konfiguration.

Jag skulle lyfta KPI 2 först när ledningen ska fatta beslut om aktuell risk, eftersom öppna Critical-fynd eller utgångna undantag kräver en tydlig åtgärd eller riskacceptans. Den senaste dokumenterade skanningen rapporterade 0 Critical och 44 High-paketträffar, motsvarande nio granskade CVE:er; nio undantag hade slutdatum 20 november 2026. Skanningsdatumet är 3 november och undantagens aktuella status är inte verifierad i detta underlag. De 44 paketträffarna ska därför inte presenteras som 44 separata sårbarheter eller som åtgärdade fynd.

KPI 1 har ett mål på minst 95 %, men en enda lyckad deployment, 41608640621, räcker inte för en stabil baslinje. KPI 3 har en dokumenterad baslinje på 1 av 5 verifierade detektionsfall, 20 %, med mål på 80 % nästa förbättringsperiod och 100 % på längre sikt. De fyra övriga fallen är inte dokumenterade som godkända, vilket inte i sig visar att de har misslyckats. Ledningen bör därför begära uppdaterade mätningar, ansvariga och trender över tid innan den drar slutsatser om säkerhetsnivån.

[Fullständiga KPI-definitioner](kpi.md)

---

## 6. Incidentrespons, post-mortem och förbättringsarbete

Post-mortemet gäller en kontrollerad simulering av en möjlig behörighetsväg från CI-/scannerrollen via en CronJob till monterade secrets. Genom RBAC-genomgång och test av tillåtna och nekade åtgärder upptäcktes att direkt Secret-läsning kunde vara spärrad medan en indirekt väg via en ändringsbar workload ändå fanns. Jag deltog i genomgången och testet. Ingen faktisk hemlighet lästes eller fördes ut enligt tillgängligt underlag. Teamet tog bort scanner-apply från appens pipeline och verifierade att deployidentiteten nekades relevanta åtgärder i det återställda klustret.

Den centrala orsaken var att behörigheter först bedömdes var för sig i stället för som en kedja av möjliga handlingar. Lärdomen är att granska vad en roll kan få andra resurser att göra, inte bara om rollen kan läsa en Secret direkt. Uppföljningen ska visa både tillåtna och nekade åtkomstvägar och utreda kvarvarande läs-/skrivåtkomst till applikationshemligheter i namespace default.

Övriga lärdomar är att Terraform inte automatiskt återställer tjänstedata och att en grön pipeline måste visa att rätt miljö och identitet används. Förbättringar bör följas upp med en dokumenterad Headscale-/k3s-återställningsövning, verifiering av klusteridentitet före deployment och återkommande tester av detektionsfallen.

[Post-mortem och lessons learned](lessons-learned.md)

---

## 7. AI i säkerhetsarbetet

### Konkreta användningsfall

Jag använde ChatGPT/Codex som stöd för att förstå felmeddelanden, planera felsökning och jämföra möjliga orsaker till problem med Headscale, DNS, Tailscale och SSH. AI hjälpte mig att strukturera hypoteser och föreslå diagnostiska kommandon. Jag använde även AI som bollplank kring Terraform- och säkerhetskonfiguration samt för att organisera tekniska resultat i rapporttext.

### När AI var lämpligt

AI var användbart när jag behövde sortera flera möjliga orsaker till att Headscale-domänen inte fungerade samtidigt som andra domäner gick att slå upp. Förslagen hjälpte mig att planera kontroller av DNS och anslutning. Jag körde kontrollerna själv och jämförde resultaten med konfigurationen och teamets dokumentation. AI gav snabbare struktur åt felsökningen, men resultatet från kommandon och projektunderlag avgjorde vad som faktiskt kunde sägas.

AI fungerade också som stöd för att göra tekniskt material begripligt och organisera rapportens slutsatser. Den typen av stöd är lämplig när jag själv kan kontrollera fakta och behålla ansvaret för formulering och beslut.

### När AI var olämpligt eller otillräckligt

AI kan föreslå en rimlig hypotes utan att bevisa den. Att vanliga domäner kunde slås upp medan Headscale-domänen inte kunde det pekade mot DNS eller Headscale, men avgjorde inte ensamt var felet låg. En gruppkamrat utförde själva Headscale-åtgärden. Därför beskriver jag min del som klientfelsökning och inte som att jag åtgärdade tjänsten.

SSH-felsökningen visade också en viktig gräns. När jag tog bort den gamla värdnyckeln ur known_hosts fungerade anslutningen igen, men det bevisade inte att den nya servern var rätt server. Varken ett AI-svar eller en lyckad anslutning räcker som identitetskontroll; fingeravtrycket ska jämföras med en betrodd källa innan en ny nyckel accepteras.

AI ska inte ensam fatta beslut om IAM, riskacceptans, hemligheter eller ändringar med stor driftpåverkan. Jag ska heller inte mata in API-nycklar, tokens, kubeconfig, privata loggar eller personuppgifter. Råloggar ska saneras och endast minsta nödvändiga information delas. AI kan hallucinera, missa sammanhang eller återanvända antaganden från en annan miljö, så dess förslag måste granskas.

### Verifiering och mänsklig kontroll

AI utförde inte den praktiska felsökningen åt mig. Jag körde kommandona själv och jämförde resultaten med repositorykonfiguration, Git-historik, teamets säkerhetsrapport och faktiska testresultat. Jag skiljde mellan observation och hypotes och skrev inte att ett problem var löst enbart för att ett föreslaget kommando lyckades. Säkerhetskritiska slutsatser behövde stöd av projektets evidens eller en oberoende kontroll.

### Risker och professionella gränser

De största riskerna i detta arbetssätt är felaktiga råd, övertro på välformulerade svar, läckage av känslig information och svag spårbarhet om AI-förslag kopieras utan granskning. Ett AI-förslag ska därför behandlas som en hypotes. Ändringar ska granskas som diff, testas i rätt miljö och kunna återställas. Jag ansvarar själv för kommandon och ändringar jag väljer att genomföra.

### Professionell slutsats

I en framtida säkerhetsroll använder jag AI för att förklara, strukturera och generera kontrollerbara hypoteser. Jag avstår från AI som enda beslutsunderlag för behörigheter, incidentklassning eller riskacceptans. Jag delar aldrig hemligheter, verifierar kritiska påståenden mot primära källor eller praktiska tester och dokumenterar när AI har bidragit till en slutsats.

---

## 8. Prioriterade rekommendationer

1. **Nu — minska kvarvarande secret-åtkomst.** App-/IAM-ansvarig bör granska och begränsa app-pipelineidentitetens läs-/skrivåtkomst till secrets i namespace default. Motiveringen är den simulerade indirekta vägen och den kvarvarande direkta behörigheten. Följ upp med positiva och negativa RBAC-tester och dokumenterad ägare.
2. **Nästa steg — bevisa återställning och rätt miljö.** Plattformsteamet bör automatisera Headscale- och k3s-återställning samt lägga in kontroll av klusteridentitet, certifikat och route före deployment. Följ upp med en separat återställningsövning och ett negativt test mot fel kluster.
3. **Längre sikt — öka verifierad detektionstäckning.** Säkerhets-/driftansvarig bör planera tester för de fem prioriterade detektionsfallen, med särskilt ansvar för de fyra som ännu inte är tydligt verifierade. Följ KPI 3 mot 80 % nästa förbättringsperiod och 100 % på längre sikt.

---

## 9. Individuell reflektion

### Vad kan jag nu som jag inte kunde när kursen började?

Jag kan nu felsöka en åtkomstkedja som spänner över Headscale, DNS, routes och SSH i stället för att behandla varje fel som samma problem. Jag har praktiskt ändrat Headscale-ACL och DNS-policy och lärt mig följa vad en identitet kan göra indirekt genom en annan resurs. Genom RBAC-genomgången förstod jag att en nekad direktläsning av en Secret inte bevisar minsta behörighet. Jag kan också skilja mellan att en anslutning fungerar och att serverns identitet faktiskt är verifierad.

### Vilket moment har förändrat mitt sätt att arbeta med cybersäkerhet mest?

Miljöflytten och SSH-felsökningen förändrade mest hur jag bedömer verifiering. Jag tog bort en gammal värdnyckel och kunde ansluta, men det var inte samma sak som att bekräfta serverns identitet. På motsvarande sätt nådde pipelinen en intern adress men först fel kluster via en gammal route. Jag tar därför med mig principen att kontrollera identitet och målmiljö, inte bara att en åtgärd ser grön ut.

### Vad skulle jag göra annorlunda om projektet började idag?

Jag skulle tidigare fråga vilken data, konfiguration och identitet som inte återskapas när en VM ersätts och vem som äger återställningen. Före migrations- och hårdningsändringar skulle jag skriva ner förväntat resultat, säkerställa backup och återställningsväg och testa både tillåtna och nekade åtkomstflöden. Vid ändrad SSH-värdnyckel skulle jag först hämta fingeravtrycket via en betrodd kanal. Vid Secure Boot-testet skulle jag kontrollera operativsystemets faktiska start och åtkomstväg, inte nöja mig med att VM:n visades som RUNNING.

### Vad tar jag med mig till LIA och min framtida yrkesroll?

Till LIA tar jag med mig att dokumentera observationer, hypoteser, tester och kvarstående risk var för sig så att en annan person kan följa resonemanget. Jag vill också testa behörigheter från den identitet som faktiskt används och bekräfta både vad den ska kunna göra och vad som ska nekas. I samarbetet skiljer jag tydligt mellan mitt bidrag och teamets resultat och använder evidens när jag rapporterar status. Jag använder AI som stöd för hypoteser och struktur, men verifierar säkerhetskritiska råd själv och delar inte hemligheter. Det gör att jag kan bidra tekniskt samtidigt som jag kommunicerar risk och rekommendationer begripligt för driftansvariga och beslutsfattare.

---

## 10. Källor och referenser

- [Team 3 Blue Team-säkerhetsrapport](../../blue-team-security-report.md)
- [Mitt individuella bidrag](../../marcus-individuellt-bidrag.md)
- [Min AI-redogörelse](../../marcus-ai-redogorelse.md)
- [Mina KPI:er](kpi.md)
- [Mitt post-mortem och lessons learned](lessons-learned.md)
- [Appens PR #26 om scannerbehörighet](https://github.com/ITSX25-Chas/Team3-ThaCompany/pull/26)
- [Lyckad appdeployment 41608640621](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621)
- Egna commitbevis: dea72e1, a4855ae, 13e3f08 och 27c511e i team3-blueteam-repositoryt.
- Kursmaterial: uppgiftsbeskrivningen och mallen för individuell slutrapport.

AI-genererade förslag användes som stöd och verifierades mot projektkonfiguration, Git-historik, säkerhetsrapport och egna testresultat. Mina slutsatser och prioriteringar är mina egna bedömningar.

---

## Slutkontroll

- Mina egna bidrag går att hitta i Git-historiken och länkar till relevanta underlag.
- Viktiga resultat stöds av projektets evidens och källor.
- KPI:erna kommunicerar säkerhetsstatus och sina databegränsningar för en icke-teknisk mottagare.
- Post-mortemet skiljer den simulerade attackvägen från ett bekräftat intrång och leder till konkreta förbättringar.
- AI-användning, lämplighet, begränsningar och verifiering beskrivs med konkreta exempel.
- Rekommendationerna är prioriterade och kopplade till risker och KPI:er.
- Den professionella sammanfattningen kan läsas fristående.
- Den individuella reflektionen utgår från dokumenterade erfarenheter.
- Källor och länkar bör kontrolleras före inlämning.
- Inga lösenord, tokens, API-nycklar eller andra hemligheter ska finnas i rapporten.
- Ändringarna ska vara committade och pushade före inlämning.
