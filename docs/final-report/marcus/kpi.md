# KPI:er och säkerhetsmätningar

- **Student:** Marcus Gustafsson
- **Projekt:** Team 3 Blue Team

## Syfte och kursmål

KPI:erna följer säkerhetsläget och effekten av säkerhetsarbetet och ska ge beslutsunderlag till en icke-teknisk mottagare.

- **Kursmål 4:** Säkerhetsmätningar, KPI:er och compliance-rapportering används för att kommunicera säkerhetsstatus till ledningsnivå.
- **Kursmål 10:** Säkerhetsmätningar och KPI-rapportering anpassas för en icke-teknisk beslutsfattare.

KPI:erna utgår från projektets befintliga resultat. Inga nya tekniska tester har lagts till för denna rapport.

---

## KPI 1

### Namn

Andel lyckade säkra deploymenter

### Syfte och mottagare

Visar för IT- och säkerhetsansvariga samt ledningen om releaser både fungerar och passerar projektets säkerhetskontroller.

### Definition och beräkning

Antal deploymentförsök på `main` där tester, imagebygge, SBOM, Cosign-signering, anslutning och Kubernetes-rollout lyckas, dividerat med samtliga deploymentförsök på `main`.

`Lyckade säkra deploymenter / alla deploymentförsök × 100`

### Datakälla och datakvalitet

GitHub Actions i `Team3-ThaCompany`. Den senaste verifierade körningen `41608640621` klarade samtliga angivna steg. En enskild körning räcker inte för att fastställa en stabil andel över tid; längre körhistorik behöver räknas innan en baslinje anges.

[Evidens: lyckad deployment](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621)

### Målvärde eller önskad riktning

Minst 95 %. Alla lyckade deploymenter ska ha passerat samtliga säkerhetssteg.

### Mätfrekvens

Veckovis och efter större ändringar.

### Tolkning och åtgärd vid avvikelse

Ett högt och stabilt värde tyder på att leveranskedjan fungerar med säkerhetskontrollerna på plats. Vid ett värde under målet stoppas releasen tills felsteget har identifierats och åtgärdats. Skapa ett ärende och verifiera korrigeringen med en ny körning.

---

## KPI 2

### Namn

Critical-fynd och utgångna riskundantag

### Syfte och mottagare

Hjälper IT- och säkerhetsansvariga samt ledningen att se om allvarliga sårbarheter eller utgångna riskbeslut kräver hantering.

### Definition och beräkning

Antal öppna Critical-fynd plus antal High/Critical-riskundantag vars slutdatum har passerat.

`Öppna Critical-fynd + utgångna undantag`

### Datakälla och datakvalitet

Trivy-resultat, CycloneDX-SBOM, scannerloggar, Discord-larm och riskundantagsfil. Den senaste dokumenterade skanningen rapporterade 0 Critical och 44 High-paketträffar. Underlaget anger nio tidsbegränsade undantag med slutdatum 20 november 2026. Undantagens aktuella status och det aktuella antalet utgångna är inte verifierade i det tillgängliga underlaget.

[Evidens: säkerhetsrapport, avsnitt 6](../../blue-team-security-report.md#6-incidenter-och-lärdomar)

### Målvärde eller önskad riktning

0 öppna Critical-fynd och 0 utgångna undantag.

### Mätfrekvens

Vid varje imagebygge och minst dagligen via scannerjobbet.

### Tolkning och åtgärd vid avvikelse

Ett värde över 0 kräver triage och en namngiven ansvarig. Blockera eller återställ deployment vid behov. Dokumentera åtgärden eller fatta ett nytt, tidsbegränsat riskbeslut. Redovisa Critical-fynd och utgångna undantag separat tillsammans med summan, så att ledningen ser vad som driver värdet.

---

## KPI 3

### Namn

Testad detektionstäckning

### Syfte och mottagare

Visar för IT- och säkerhetsansvariga samt ledningen om prioriterade säkerhetshändelser faktiskt upptäcks och ger förväntad evidens eller larm.

### Definition och beräkning

Antal prioriterade detektionsfall som testats från händelse till förväntad evidens eller larm, dividerat med fem planerade fall.

`Godkända detektionstester / 5 × 100`

### Datakälla och datakvalitet

GCP Audit Logs, OS Login/sshd-loggar, Headscale-journal, GitHub Actions, Kubernetes-loggar och Discord. Ett av fem fall är tydligt verifierat från början till slut: sårbar image som utlöser scannerlarm, vilket motsvarar 20 %. Underlaget visar inte att de övriga fyra fallen är godkända; det fastställer inte heller i sig att de har misslyckats.

[Evidens: säkerhetsrapport, avsnitt 7](../../blue-team-security-report.md#7-loggning-och-detektion)

### Målvärde eller önskad riktning

Minst 80 % inom nästa förbättringsperiod och 100 % på längre sikt.

### Mätfrekvens

Månadsvis och efter ändringar i loggning eller larm.

### Tolkning och åtgärd vid avvikelse

Ett lågt värde visar att hela detektionskedjan inte är verifierad. Utred om bristen gäller insamling, detektionsregel, notifiering eller ansvar. Skapa ett förbättringsärende och verifiera utfallet när kedjan har åtgärdats.

---

## Samlad ledningsrapportering

De tre KPI:erna täcker leveranskvalitet, känd sårbarhetsrisk och förmågan att upptäcka säkerhetshändelser. Tillsammans visar de om säkerhetskontroller följer med releasen, om allvarliga fynd eller riskundantag kräver beslut och om larmkedjan fungerar i praktiken. De riktar sig till IT- och säkerhetsansvarig samt ledning som behöver prioritera risk, resurser och releasebeslut utan att tolka scanner- eller loggdetaljer.

Den senaste dokumenterade deploymenten passerade samtliga angivna steg, men en körning räcker inte för att visa en stabil andel över tid. Skanningsunderlaget rapporterade noll Critical och 44 High-paketträffar; nio tidsbegränsade undantag hade slutdatum 20 november 2026. Undantagens aktuella status och antalet utgångna måste kontrolleras innan KPI 2 rapporteras som ett fast tal. Detektionstäckningen är 1 av 5 verifierade fall (20 %); de övriga fyra är inte tydligt verifierade i underlaget, vilket inte i sig bevisar att de misslyckats.

Ledningen bör uppmärksamma en fallande deploymentandel, nya Critical-fynd, passerade undantagsdatum eller utebliven förbättring mot 80 % detektionstäckning. Då kan den besluta om release-stopp, åtgärdsägare eller tid för att stärka loggning och larm. KPI:erna visar inte sårbarheternas exploaterbarhet, faktisk incidentrisk eller fullständig loggtäckning; komplettera med risktriage, ett undantagsregister med status och ägare samt testresultat per detektionsfall.

---

## Kontroll före commit

- [x] Jag har definierat tre relevanta KPI:er.
- [x] KPI:erna mäter mer än enbart genomförda aktiviteter.
- [x] Varje KPI har definition, datakälla och mottagare.
- [x] Varje KPI har ett målvärde, gränsvärde eller en önskad riktning.
- [x] Jag har beskrivit hur KPI:erna ska tolkas och följas upp.
- [x] Jag har beskrivit vad en avvikelse bör leda till.
- [x] Min rapportering är begriplig för en icke-teknisk beslutsfattare.
