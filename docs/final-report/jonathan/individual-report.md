# Individuell slutrapport

**Namn:** Jonathan Tsubarah
**Projekt/team:** Team 3 Blue Team
**Datum:** 2026-11-11

---

## Syfte och kursmål

Rapporten sammanfattar projektets resultat och mina egna reflektioner för en fiktiv ledningsgrupp.

- **Kursmål 4:** säkerhetsmätningar, KPI:er och compliance-rapportering till ledningsnivå.
- **Kursmål 9:** incidentrespons, post-mortem och förbättringsarbete.
- **Kursmål 10:** KPI-rapportering för en icke-teknisk beslutsfattare.
- **Kursmål 11:** integrerad användning och professionell värdering av generativ AI och AI-assisterade säkerhetsverktyg.
- **Kursmål 13:** självständigt leda och leverera ett komplext säkerhetsprojekt med kvalitet, dokumentation och professionell kommunikation.

---

## 1. Professionell sammanfattning

Team 3 har byggt och härdat en molnmiljö i Google Cloud där en webbapp körs. Miljön är i dag betydligt säkrare än när vi började. Den automatiska leveransen använder inte längre en lösenordsliknande nyckel som kan stjälas, nätverket är inte längre öppet mot hela internet och appen skannas varje dag efter kända sårbarheter med larm till teamet.

Det finns ändå tre risker som ledningen behöver känna till. Den första är att åtkomstkontrollen till miljön inte kan återställas på ett säkert sätt. När en server byttes ut i oktober fick den byggas upp för hand och teamet var utelåst under tiden. Den andra är att ett tjänstekonto fortfarande har bredare behörighet än det behöver i ett molnprojekt som vi delar med fem andra lag. Den tredje är att vi bara har testat att larmet fungerar för en av fem viktiga händelser.

KPI:erna visar att det just nu finns 0 kritiska sårbarheter, men att nio accepterade risker går ut den 20 november och att larmtäckningen är 20 %. Målet är minst 80 %.

Jag rekommenderar att vi i den här ordningen:

1. tar beslut om de nio riskerna innan 20 november,
2. säkerhetskopierar och testar återställningen av åtkomstkontrollen,
3. begränsar tjänstekontots behörighet och testar de fyra larmfall som återstår.

Det som behöver beslutas är vem som äger de här åtgärderna och vem som får kontrollera behörigheter i det delade projektet, eftersom teamet i dag inte har rätt att verifiera allt själv.

---

## 2. Kontext och avgränsning

Projektet gick ut på att bygga en säker miljö som kod, hitta brister och åtgärda dom. Miljön består av en jumphost som är vägen in, en server med Kubernetes (k3s) där appen körs, Headscale för det interna nätverket och GitHub Actions för automatisk leverans. Allt ligger i ett GCP-projekt som delas med fem andra lag, vilket betydde att vi bara fick ändra våra egna resurser.

Rapporten gäller Blue Team-delen. Red Team-övningen mot Acme ingår inte. Underlaget är Git-historik, issues, pull requests, körningar i GitHub Actions och teamets [säkerhetsrapport](../../blue-team-security-report.md). Där jag inte själv har kontrollerat något i miljön skriver jag det.

---

## 3. Mitt individuella bidrag

Mitt arbete har mest handlat om identitet och behörigheter i GCP, nätverksåtkomst, Headscale och CI/CD. Allt har gått via PR med granskning och jag läste `terraform plan` innan varje merge.

- **Ingen långlivad nyckel i CI.** Jag bytte CI/CD-autentiseringen från en servicekontonyckel till Workload Identity Federation och tog sedan bort nyckeln ([PR #1](https://github.com/ITSX25-Chas/team3-blueteam/pull/1), [PR #20](https://github.com/ITSX25-Chas/team3-blueteam/pull/20)).
- **Mindre behörigheter.** Jag ersatte `roles/editor` för CI-kontot med specifika roller ([PR #57](https://github.com/ITSX25-Chas/team3-blueteam/pull/57)) och gav jumphosten ett eget servicekonto i stället för standardkontot ([PR #35](https://github.com/ITSX25-Chas/team3-blueteam/pull/35)).
- **Stängt nätverk.** Jag ersatte brandväggsregeln som släppte in all trafik från internet med en begränsad SSH-regel ([PR #23](https://github.com/ITSX25-Chas/team3-blueteam/pull/23), [#25](https://github.com/ITSX25-Chas/team3-blueteam/pull/25), [#30](https://github.com/ITSX25-Chas/team3-blueteam/pull/30)), ersatte `*:*` i Headscale-policyn med specifika regler ([PR #49](https://github.com/ITSX25-Chas/team3-blueteam/pull/49)) och tog bort SSH-nycklar ur jumphostens metadata ([PR #50](https://github.com/ITSX25-Chas/team3-blueteam/pull/50)).
- **State-bucket och Secure Boot.** Jag lade till skydd och loggning för state-bucketen ([PR #60](https://github.com/ITSX25-Chas/team3-blueteam/pull/60)) och dokumenterade varför Secure Boot inte fungerar med labbens image ([PR #33](https://github.com/ITSX25-Chas/team3-blueteam/pull/33)).
- **Appen.** Jag uppgraderade sårbara beroenden ([app-PR #20](https://github.com/ITSX25-Chas/Team3-ThaCompany/pull/20)), lade till scannerjobbet med larm till Discord ([app-PR #21](https://github.com/ITSX25-Chas/Team3-ThaCompany/pull/21)) och fixade så att en användare inte kan se andras interna anteckningar ([app-PR #22](https://github.com/ITSX25-Chas/Team3-ThaCompany/pull/22)).
- **Återställning.** När jumphosten stoppades flyttade jag den ([PR #61](https://github.com/ITSX25-Chas/team3-blueteam/pull/61)) och installerade om Headscale.

Ett beslut jag tog själv var att inte sätta IAP-rollen på projektnivå, eftersom det hade påverkat de andra lagen. Vi körde i stället begränsad SSH mot bara våra egna resurser. Mina commits finns också listade i [mitt individuella bidrag](../../jonathan-individuellt-bidrag.md).

---

## 4. Viktigaste projektresultat och evidens

### Resultat 1: CI loggar in utan nyckel men har fortfarande för bred behörighet

#### Resultat

CI loggar in med kortlivade tokens via WIF och det finns ingen nyckel kvar som kan stjälas. Editor-rollen är borttagen, men `roles/compute.admin` är kvar på hela projektet.

#### Evidens

[PR #1](https://github.com/ITSX25-Chas/team3-blueteam/pull/1), [PR #20](https://github.com/ITSX25-Chas/team3-blueteam/pull/20), [PR #57](https://github.com/ITSX25-Chas/team3-blueteam/pull/57) och säkerhetsrapportens risk B02. Efter att nyckeln togs bort kollade jag i GCP att det inte fanns några nycklar kvar på kontot.

#### Verksamhets- och säkerhetsbetydelse

En stulen nyckel var tidigare den enklaste vägen in i hela miljön, och den risken är borta. Men om CI-flödet missbrukas kan kontot fortfarande ändra servrar i ett projekt som delas med fem andra lag.

#### Rekommendation

IAM-ansvarig går igenom vad pipelinen faktiskt använder och begränsar rollen till det. Hög prioritet.

### Resultat 2: Nätverket är stängt men åtkomsten är inte testad från varje roll

#### Resultat

Det går inte längre att nå servrarna från hela internet, och Headscale släpper bara igenom det varje roll ska nå.

#### Evidens

[PR #30](https://github.com/ITSX25-Chas/team3-blueteam/pull/30), [PR #49](https://github.com/ITSX25-Chas/team3-blueteam/pull/49), [PR #50](https://github.com/ITSX25-Chas/team3-blueteam/pull/50) och säkerhetsrapportens avsnitt 4.

#### Verksamhets- och säkerhetsbetydelse

Det är mycket svårare för någon utomstående att ens hitta något att attackera. Men reglerna finns i kod och är inte testade från varje roll, och den tillfälliga SSH-öppningen från [PR #43](https://github.com/ITSX25-Chas/team3-blueteam/pull/43) blev aldrig följd upp. Enligt koden är den fortfarande aktiv i brandväggen.

#### Rekommendation

Nätverksansvarig testar tillåten och nekad åtkomst från varje roll och tar bort tillfälliga undantag. Medel prioritet.

### Resultat 3: Sårbarheter upptäcks och larmas, men nio risker är bara accepterade

#### Resultat

Appen skannas varje dag och larmar i Discord. Det är den enda larmkedjan som är testad hela vägen. Senaste skanningen gav 0 Critical, och de 44 High-träffarna (9 unika CVE:er) är accepterade till 20 november.

#### Evidens

[App-PR #20](https://github.com/ITSX25-Chas/Team3-ThaCompany/pull/20), [app-PR #21](https://github.com/ITSX25-Chas/Team3-ThaCompany/pull/21) och säkerhetsrapportens avsnitt 6 och 7.

#### Verksamhets- och säkerhetsbetydelse

Vi märker om en ny allvarlig sårbarhet dyker upp. Men en accepterad risk är inte fixad, och efter 20 november gäller inte beslutet längre.

#### Rekommendation

Säkerhetsansvarig tar beslut för varje undantag innan 20 november: uppdatera, nytt tidsbegränsat beslut eller blockera. Hög prioritet.

---

## 5. KPI:er och ledningsrapportering

I [kpi.md](kpi.md) använder jag tre KPI:er:

1. **Andel lyckade säkra deploymenter.** Mål minst 95 %. Senaste körningen gick igenom alla steg, men hela historiken är inte räknad.
2. **Critical-fynd och utgångna riskundantag.** Mål 0 och 0. Just nu är det 0 Critical och nio undantag som går ut 20 november.
3. **Testad detektionstäckning.** Mål minst 80 %. Just nu 1 av 5, alltså 20 %.

Tillsammans svarar dom på om vi kan leverera säkert, om vi har kända risker som ingen hanterar och om vi märker när något händer. Det är frågor en ledning kan förstå utan att veta något om Terraform eller Kubernetes.

KPI:erna kan stödja tre beslut: vem som äger undantagen innan 20 november, tid för att testa de fyra larmfallen som återstår och att en deployment bara räknas som lyckad om den gick mot rätt miljö.

Begränsningar: KPI:erna visar inte hur lätt en sårbarhet går att utnyttja, hur många som har breda behörigheter eller ändringar som görs direkt i molnkonsolen. KPI 1 har ingen riktig startpunkt än eftersom historiken inte är räknad.

---

## 6. Incidentrespons, post-mortem och förbättringsarbete

Mitt [post-mortem](lessons-learned.md) gäller när jumphosten stoppades på grund av resursbrist i zonen. Det var inget intrång, men det slog ut åtkomstkontrollen för både teamet och pipelinen. Vi märkte det när vi inte kom åt miljön. Jag flyttade jumphosten till en annan zon och installerade om Headscale med användare, routing, DNS och nya nycklar.

Orsaken var att Headscale var installerat för hand och inte fanns i Terraform eller i någon backup. Konsekvensen blev att teamet var utelåst tills jag var klar, och att ett DNS-fel från ominstallationen upptäcktes först elva dagar senare.

De andra två lärdomarna är att tillfälliga undantag i nödlägen behöver en ägare och ett slutdatum, och att en säkerhetsändring inte är klar bara för att PR:en är mergad.

Förbättringarna är att säkerhetskopiera Headscale och lägga installationen i kod, att alla tillfälliga undantag får en issue med ägare och slutdatum, och att ändringar kontrolleras i den riktiga miljön. Det följs upp med ett återställningstest på en separat VM, en genomgång av CI-kontots roller och att issue #12 stängs först när bucketens skydd är bekräftat.

---

## 7. AI i säkerhetsarbetet

### Konkreta användningsfall

Jag har använt Claude när jag fastnat, mest för att förstå felmeddelanden, läsa Terraform och få tips på hur jag kan felsöka. Claude kunde läsa repot men inte pusha, så alla kommandon har jag kört själv. Till den här slutrapporten använde jag Claude för att strukturera mitt eget material, alltså mina commits, PR:er och tidigare redogörelser, enligt kursens mallar och som stöd för formuleringar. Innehållet bygger på mitt arbete, och jag har läst igenom allt, ändrat det som inte stämde och kontrollerat sakuppgifterna mot repot.

I projektet använde vi också säkerhetsverktyg som Trivy, TFLint och Checkov. Dom är inte generativ AI utan ger samma resultat varje gång, men även dom måste tolkas. 44 Trivy-träffar betyder till exempel inte 44 hål som går att utnyttja.

### När AI var lämpligt

I Red Team-övningen var min del att ta mig från vanlig användare till root. Där använde jag AI som bollplank för att förstå vad det betyder när ett program har SUID-biten satt och varför det kan vara en risk. Det var lämpligt för att det handlade om att förstå ett begrepp i en avgränsad labbmiljö med godkänd Rules of Engagement. Själva testerna gjorde jag och teamet, och resultatet kontrollerades i miljön.

Det fungerade också bra när jag skulle förstå felmeddelanden från Terraform. Det gick snabbare att få en förklaring och ett förslag på vad jag skulle kolla än att leta i dokumentationen från början.

### När AI var olämpligt eller otillräckligt

AI föreslog att sätta IAP-rollen på projektnivå. Det hade fungerat tekniskt, men vi delar projektet med fem andra lag och då hade ändringen påverkat dom också. AI visste inte hur miljön var uppdelad, så förslaget var fel för vår situation. Jag körde i stället begränsad SSH för bara våra resurser.

AI har också haft fel om fakta. När jag skrev till gruppen om Headscale sa AI att några användare var okända, men i Git-historiken såg jag att dom kom från vår egen policy.

### Verifiering och mänsklig kontroll

Innan något mergades läste jag `terraform plan` så jag visste vad som skulle ändras. Efteråt kollade jag i GCP att det blev rätt, till exempel att det inte fanns några nycklar kvar när servicekontonyckeln var borttagen. Alla ändringar gick via PR med granskning. När AI säger något om hur miljön ser ut kollar jag själv i Git-historiken eller i miljön innan jag använder det.

### Risker och professionella gränser

Den största risken är att AI låter säker även när den har fel. Den kan hitta på saker, som med användarna i Headscale, och den föreslår ibland bredare behörigheter än nödvändigt eftersom det är det som "funkar". Det finns också risk för informationsläckage. Nycklar och lösenord har jag aldrig lagt in i någon prompt. Om man inte dokumenterar vad som kom från AI blir det också svårt för någon annan att förstå varför ett beslut togs.

### Professionell slutsats

AI är bra för att förstå något nytt, felsöka och få en struktur att börja med. Men när det gäller behörigheter, riskacceptans eller hur miljön faktiskt ser ut just nu måste man kolla själv. I ett skarpt uppdrag skulle jag inte använda AI för att besluta om IAM-ändringar, och jag skulle inte lägga in kundens loggar, konfiguration eller hemligheter i en AI-tjänst utan att det är godkänt. Besluten och ändringarna är mina.

---

## 8. Prioriterade rekommendationer

1. **Ta beslut om de nio riskundantagen före 20 november.** Efter det datumet finns inget giltigt beslut för de kända sårbarheterna. Adresserar KPI 2. Hög prioritet. Ägare: säkerhets- och applikationsansvarig.
2. **Säkerhetskopiera Headscale och testa återställningen.** Ett nytt serverbyte skulle annars låsa ute teamet igen. Adresserar risk B01 och post-mortemet. Hög prioritet. Ägare: infrastrukturansvarig.
3. **Begränsa CI-kontots behörighet och testa larm för ändrad molnbehörighet.** Kontot kan i dag påverka mer än våra egna resurser, och det fallet är inte testat. Adresserar risk B02 och KPI 3. Medel prioritet. Ägare: IAM-ansvarig tillsammans med projektadministratören.

---

## 9. Individuell reflektion

### Vad kan jag nu som jag inte kunde när kursen började?

Jag kan sätta upp Workload Identity Federation så att en pipeline loggar in i molnet utan en sparad nyckel. När jag började visste jag inte att det gick, och jag hade inte förstått varför en nyckel i GitHub Secrets är en risk. Nu förstår jag också skillnaden mellan att ha tagit bort en dålig roll och att ha nått minsta behörighet.

### Vilket moment har förändrat mitt sätt att arbeta med cybersäkerhet mest?

När jumphosten byttes ut och Headscale försvann. Fram till dess tänkte jag att det som är byggt i Terraform är säkert. Men det som inte är byggt som kod försvinner när infrastrukturen byts ut. Nu frågar jag mig alltid vad som händer om maskinen försvinner i morgon.

### Vad skulle jag göra annorlunda om projektet började idag?

Jag skulle lägga in Headscale i kod och backup från början i stället för att installera det för hand. När jag öppnade SSH för min egen IP i ett nödläge skulle jag direkt ha skapat en issue med slutdatum, så att det inte blev liggande. Och jag skulle kontrollera mina ändringar i den riktiga miljön och inte bara lita på att PR:en var mergad.

### Vad tar jag med mig till LIA och min framtida yrkesroll?

Först att alltid läsa `terraform plan` eller motsvarande innan en ändring och sedan kontrollera resultatet i miljön. Det är något jag kommer göra oavsett vilket verktyg det gäller. Sen att tillfälliga lösningar måste ha en ägare och ett slutdatum, annars blir dom permanenta. Det känner jag igen från när jag jobbade med fysisk säkerhet, där en dörr som ställs upp "bara en stund" ofta blir stående. Och att jag måste kunna förklara en teknisk risk för någon som ska fatta beslut, inte bara för andra tekniker.

---

## 10. Källor och referenser

**Projektets evidens**

- [Team 3 Blue Team-repository](https://github.com/ITSX25-Chas/team3-blueteam) och [Team3-ThaCompany](https://github.com/ITSX25-Chas/Team3-ThaCompany): Git-historik, issues, PR:er och GitHub Actions
- [Teamets säkerhetsrapport](../../blue-team-security-report.md): risker B01–B07 och avsnitt 4, 6 och 7
- [Mitt individuella bidrag](../../jonathan-individuellt-bidrag.md) och [min AI-redogörelse](../../jonathan-ai-redogorelse.md)
- [kpi.md](kpi.md) och [lessons-learned.md](lessons-learned.md)

**AI-genererat material**

- Claude användes för felsökning under projektet och för att strukturera mitt material enligt mallarna och ge formuleringsstöd i de tre slutrapportfilerna. Innehållet är mitt, och sakuppgifterna är kontrollerade mot projektets evidens ovan.

**Egna bedömningar**

- Prioriteringar, rekommendationer och reflektioner är mina egna bedömningar utifrån evidensen.

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
- [ ] Inga lösenord, tokens, API-nycklar, personuppgifter eller andra skyddsvärda uppgifter finns i repositoryt. Inga hemligheter finns, men min publika IP-adress ligger i `terraform.tfvars.example` och i Git-historiken, se [lessons learned 2](lessons-learned.md#lesson-learned-2).
- [x] Alla ändringar är committade och pushade till GitHub.
