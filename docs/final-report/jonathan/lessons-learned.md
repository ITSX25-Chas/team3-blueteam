# Post-mortem, lessons learned och professionell sammanfattning

**Student:** Jonathan Tsubarah
**Projekt:** Team 3 Blue Team

## Syfte och kursmål

Här gör jag ett kort post-mortem på en händelse i projektet, tar upp tre lärdomar och sammanfattar resultatet för en mottagare som inte är teknisk.

- **Kursmål 9:** utföra incidentrespons, post-mortem och förbättringsarbete efter ett verkligt eller simulerat intrångsförsök.
- **Kursmål 13:** självständigt leda och leverera ett komplext säkerhetsprojekt med höga krav på kvalitet, dokumentation och professionell kommunikation.

---

## Händelse och avgränsning

Post-mortemet gäller när jumphosten stoppades på grund av stockout i zonen europe-north2-c, alltså att zonen hade slut på resurser. Den flyttades den 1 oktober. Jumphosten är vägen in till vår interna miljö och kör Headscale, som styr vem som får nå vad i nätverket. När den låg nere kom varken teamet eller app-pipelinen åt miljön.

Det var inget intrång och ingen angripare. Men det slog ut åtkomstkontrollen, och det visade hur vi klarar att återställa en säkerhetsfunktion.

Det var jag som hanterade det. Jag flyttade jumphosten till europe-north2-b ([PR #61](https://github.com/ITSX25-Chas/team3-blueteam/pull/61)). Headscale var installerat för hand och försvann när disken byttes, så jag installerade om det, skapade användarna, routing och split DNS igen och tog fram nya nycklar till teamet och CI. Efteråt kollade jag med `tailscale status`, `headscale nodes list` och `curl` mot Spectre.

Lärdom 2 och 3 kommer från andra delar av mitt arbete men handlar om samma sak: att det som står i koden inte alltid är det som gäller i miljön.

---

## Lesson learned 1

### Observation

Terraform kunde skapa en ny jumphost direkt, men Headscale följde inte med. Användare, registreringar, routes och DNS fick göras om för hand. `github-ci` fick nytt ID och CI behövde en ny nyckel. Den 12 oktober märktes också att DNS-inställningarna inte hade blivit rätt efter ominstallationen, så Spectre löstes till fel adress ([säkerhetsrapport, avsnitt 6](../../blue-team-security-report.md#6-incidenter-och-lärdomar)).

### Orsak

Headscale låg utanför Terraform och dess data och nycklar säkerhetskopierades inte. Det fanns ingen nedskriven plan för hur det skulle återställas, så allt fick göras för hand.

### Konsekvens

Teamet och pipelinen var utan åtkomst tills jag var klar. Alla fick nya nycklar. Eftersom allt gjordes för hand blev DNS fel utan att jag märkte det, och det upptäcktes först när någon försökte nå Spectre. Ominstallationen syns inte heller i Git, så det är svårt för någon annan att se exakt vad som gjordes.

### Förbättring

Säkerhetskopiera Headscale-databasen och nycklarna med begränsad åtkomst. Lägg installation och konfiguration i kod eller ett versionerat skript så att den kan köras om på samma sätt varje gång.

### Uppföljning

Gör ett återställningstest på en separat VM. Det räknas som klart när klienter, ACL, DNS, routes och CI fungerar efteråt utan manuella steg som inte står i skriptet. Säkerhetsrapportens risk B01 kan stängas först då.

---

## Lesson learned 2

### Observation

Den 15 september aktiverades Headscale-ACL:n utan en regel som släppte igenom SSH till jumphosten. Publik SSH var redan begränsad och vi hade inte IAP-behörighet, så vi blev utelåsta. Jag löste det med en hotfix som öppnade SSH från min egen publika IP ([PR #43](https://github.com/ITSX25-Chas/team3-blueteam/pull/43)). I commiten skrev jag att den skulle tas bort så fort det gick, men IP-adressen ligger fortfarande kvar i `terraform.tfvars.example` på `main`. Det är den filen CI använder vid deploy, så enligt koden är regeln fortfarande aktiv i brandväggen. Det har jag inte kontrollerat i GCP.

### Orsak

ACL:n testades inte mot alla vägar in innan den aktiverades, och det fanns ingen reservväg om något gick fel. Mitt tillfälliga undantag hade ingen ägare, inget slutdatum och ingen issue som påminde om att det skulle bort. Att CI läser en fil som heter `example` gjorde det också lätt att tro att den inte gällde på riktigt.

### Konsekvens

Teamet kom inte åt jumphosten förrän hotfixen var på plats. Undantaget löste problemet men lämnade en öppning som ingen följde upp. SSH kan fortfarande nås från en adress som inte behövs längre, och min IP-adress syns i ett publikt repo och i Git-historiken.

### Förbättring

Testa en ny ACL från varje roll innan den aktiveras och se till att det finns en reservväg in som inte beror på samma ändring. Varje tillfälligt undantag ska ha en issue med ägare och slutdatum, på samma sätt som riskundantagen i KPI 2.

### Uppföljning

Ta bort adressen i en egen PR, läs `terraform plan` och kontrollera sedan i GCP att brandväggsregeln är uppdaterad och att ingen förlorat åtkomst de behöver. Inför nästa ACL-ändring ska testresultatet från varje roll finnas med i PR:en.

---

## Lesson learned 3

### Observation

Två av mina ändringar är mergade men gör inte hela jobbet i miljön. I [PR #57](https://github.com/ITSX25-Chas/team3-blueteam/pull/57) tog jag bort Editor-rollen från CI-kontot, men `roles/compute.admin` är kvar på hela projektet (risk B02). I [PR #60](https://github.com/ITSX25-Chas/team3-blueteam/pull/60) lade jag till skydd och loggning för state-bucketen, men när teamet skulle kontrollera det nekades vi läsrätt, så vi vet inte om skyddet faktiskt är aktivt (risk B07, [issue #12](https://github.com/ITSX25-Chas/team3-blueteam/issues/12) är fortfarande öppen).

### Orsak

Jag såg en mergad PR och en grön pipeline som att saken var klar. Jag kollade `terraform plan`, men inte alltid vad som faktiskt gällde i GCP efteråt eller vem som hade rätt att kontrollera det. Least privilege gjordes i ett steg, när det egentligen behöver göras om tills bara det nödvändiga är kvar.

### Konsekvens

CI-kontot kan fortfarande göra mycket mer än det behöver i ett projekt som delas med fem andra lag. Blir kontot komprometterat kan det påverka fler resurser än våra egna. För state-bucketen kan vi inte visa att skyddet finns, och då kan vi inte räkna med det.

### Förbättring

En säkerhetsändring räknas som klar först när den är kontrollerad i den riktiga miljön, inte när PR:en är mergad. Gå igenom CI-kontots behörigheter igen och ta bort det pipelinen inte använder.

### Uppföljning

Lista CI-kontots roller i GCP och jämför med vad pipelinen faktiskt behöver. Be projektadministratören bekräfta bucketens inställningar och stäng issue #12 först när det är bekräftat.

---

## Professionell sammanfattning

Under projektet stoppades vår jumphost av resursbrist hos molnleverantören. Den servern styr vem som kommer åt vår interna miljö. Servern kunde skapas om snabbt, men åtkomstkontrollen på den fick byggas upp för hand eftersom den inte fanns i kod eller backup. Teamet och vår automatiska leverans var utan åtkomst under tiden, och ett DNS-fel som följde med upptäcktes först elva dagar senare. Det var inget intrång, men det visar att vi i dag inte kan återställa en viktig säkerhetsfunktion på ett säkert och upprepningsbart sätt.

Projektet visade också två andra saker. En tillfällig öppning som gjordes i ett nödläge blev kvar eftersom ingen ägde den. Och flera säkerhetsändringar finns i koden men är inte kontrollerade i miljön, bland annat att ett tjänstekonto fortfarande har bred behörighet i ett projekt som vi delar med fem andra lag.

Jag rekommenderar att organisationen prioriterar i den här ordningen:

1. Säkerhetskopiera och testa återställningen av åtkomstkontrollen så att ett serverbyte inte låser ute teamet.
2. Begränsa tjänstekontots behörighet och få bekräftat att skyddet för lagringen av infrastrukturens tillstånd är aktivt.
3. Kräv att alla tillfälliga undantag har en ägare och ett slutdatum.

Det som kräver beslut är vem som äger återställningstestet och vem som får kontrollera behörigheter i det delade molnprojektet. I dag har teamet inte rätt att verifiera allt själv.

---

## Kontroll före commit

- [x] Jag har avgränsat vilket intrångsförsök eller vilken incident mitt post-mortem gäller.
- [x] Jag har beskrivit min egen roll i incidentresponsen.
- [x] Jag har formulerat tre tydliga lessons learned.
- [x] Jag skiljer på observation och bakomliggande orsak.
- [x] Jag beskriver konsekvensen av varje lärdom.
- [x] Varje lesson learned leder till en konkret förbättring och uppföljning.
- [x] Den professionella sammanfattningen fokuserar på resultat, risk och betydelse.
- [x] Texten är begriplig utan alla tekniska detaljer från projektet.
