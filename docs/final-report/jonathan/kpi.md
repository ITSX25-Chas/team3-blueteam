# KPI:er och säkerhetsmätningar

**Student:** Jonathan Tsubarah
**Projekt:** Team 3 Blue Team

## Syfte och kursmål

Här beskriver jag tre KPI:er som kan användas för att följa upp säkerhetsläget och om säkerhetsarbetet faktiskt gör skillnad.

- **Kursmål 4:** beskriva hur säkerhetsmätningar, KPI:er och compliance-rapportering används för att kommunicera säkerhetsstatus till ledningsnivå.
- **Kursmål 10:** producera säkerhetsmätningar och KPI-rapportering anpassad för en icke-teknisk beslutsfattare.

Jag har utgått från teamets tre gemensamma KPI:er men kopplat dom till det jag själv har jobbat med, mest scannern och behörigheterna för CI. Jag har inte gjort några nya tester för den här delen.

---

## KPI 1

### Namn

Andel lyckade säkra deploymenter

### Syfte och mottagare

Den visar IT-chefen om vi kan släppa nya versioner av appen utan att någon säkerhetskontroll hoppas över.

### Definition och beräkning

En deployment räknas som lyckad om alla steg går igenom: tester, imagebygge, SBOM, signering med Cosign, anslutning och utrullning i Kubernetes. Om den har gått mot fel kluster räknas den inte.

`lyckade säkra deploymenter på main / alla deploymentförsök på main × 100`

### Datakälla och datakvalitet

GitHub Actions i `Team3-ThaCompany`. Den senaste körningen jag kollat, [41608640621](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621), gick igenom alla steg. Jag har inte räknat igenom hela historiken så det finns ingen riktig startpunkt än. En grön körning betyder inte heller att den gick mot rätt miljö. Efter flytten till Comerit gick pipelinen först mot det gamla klustret på grund av en gammal route.

### Målvärde eller önskad riktning

Minst 95 %. Man får inte ta bort säkerhetssteg för att få upp siffran.

### Mätfrekvens

En gång i veckan och efter större ändringar eller när miljön byts.

### Tolkning och åtgärd vid avvikelse

Är värdet högt och stabilt fungerar leveranskedjan med kontrollerna på. Går det under 95 % ska releasen stoppas tills man vet vilket steg som fallerar. Då skapar man en issue, fixar felet och kör om.

---

## KPI 2

### Namn

Critical-fynd och utgångna riskundantag

### Syfte och mottagare

Den visar ledningen om det finns allvarliga sårbarheter eller riskbeslut som gått ut som ingen har tagit hand om.

### Definition och beräkning

Antal öppna Critical-fynd plus antal High/Critical-undantag där slutdatumet har passerat. Jag redovisar också båda siffrorna var för sig så man ser vad det är som ger värdet.

`öppna Critical + utgångna undantag`

### Datakälla och datakvalitet

Trivy-skanningen i scannerjobbet som jag lade till i [app-PR #21](https://github.com/ITSX25-Chas/Team3-ThaCompany/pull/21), som larmar till Discord. Plus SBOM och undantagsfilen. Senaste skanningen den 3 november gav 0 Critical och 44 High-träffar, men det är bara 9 olika CVE:er. Nio undantag gäller till 20 november 2026 ([säkerhetsrapport, avsnitt 6](../../blue-team-security-report.md#6-incidenter-och-lärdomar)). Scannern hittar bara kända sårbarheter i paketen, och jag har inte kollat hur undantagen ser ut efter 3 november.

### Målvärde eller önskad riktning

0 öppna Critical och 0 utgångna undantag.

### Mätfrekvens

Vid varje imagebygge och varje dag via scannerjobbet.

### Tolkning och åtgärd vid avvikelse

Att det är 0 Critical betyder inte att appen är säker. Ett undantag betyder att vi har accepterat risken en tid, inte att den är fixad. Innan 20 november måste någon bestämma för varje undantag om man ska uppdatera, ta ett nytt beslut med slutdatum eller blockera. När jag uppgraderade sårbara beroenden i [app-PR #20](https://github.com/ITSX25-Chas/Team3-ThaCompany/pull/20) försvann fynden på riktigt, och det är det man vill i första hand.

---

## KPI 3

### Namn

Testad detektionstäckning

### Syfte och mottagare

Den visar CISO och ledning om vi faktiskt märker när något viktigt händer, inte bara att det finns loggar.

### Definition och beräkning

Vi har fem fall som är prioriterade: oväntad SSH-inloggning, ändrad molnbehörighet, Headscale-avbrott, sårbar image och oväntad deployment. Ett fall är godkänt när det är testat hela vägen från händelse till att larmet når någon.

`godkända detektionstester / 5 × 100`

### Datakälla och datakvalitet

GCP Audit Logs, OS Login/sshd-loggar, Headscale-journal, GitHub Actions, Kubernetes-loggar och Discord. Just nu är det 1 av 5, alltså 20 %. Fallet som är testat är sårbar image med larm i Discord, och det bygger på scannern från PR #21. De andra fyra är inte testade. Det betyder inte att dom inte fungerar, bara att vi inte vet ([säkerhetsrapport, avsnitt 7](../../blue-team-security-report.md#7-loggning-och-detektion)).

### Målvärde eller önskad riktning

Minst 80 % nästa period och 100 % på längre sikt.

### Mätfrekvens

En gång i månaden och efter ändringar i loggning eller larm.

### Tolkning och åtgärd vid avvikelse

Är värdet lågt kan vi inte säga att ett angrepp skulle upptäckas. Då får man kolla om det är loggar, regel, notifiering eller mottagare som saknas, skapa ett ärende och testa igen. Jag skulle testa ändrad molnbehörighet först. När jag tog bort Editor-rollen i [PR #57](https://github.com/ITSX25-Chas/team3-blueteam/pull/57) blev `roles/compute.admin` kvar på hela projektet för CI-kontot (risk B02). Om någon missbrukar det kontot är det något vi vill se direkt.

---

## Samlad ledningsrapportering

Jag valde dom här tre för att dom tillsammans visar om vi kan leverera säkert, om vi har kända risker som ingen hanterar och om vi märker när något händer.

Det man ska hålla koll på nu är att alla nio undantag går ut 20 november och att bara en av fem larmkedjor är testad. Deploymenterna fungerar, men vi har inte räknat på hur ofta över tid.

KPI:erna kan hjälpa ledningen att bestämma tre saker. Vem som ansvarar för undantagen innan 20 november, att det ska finnas tid för att testa dom fyra larmfallen som återstår, och att en deployment bara räknas som lyckad om man kollat att den gick mot rätt miljö.

Det KPI:erna inte visar är hur lätt en sårbarhet går att utnyttja, hur många som har breda behörigheter eller om någon ändrar direkt i molnkonsolen. För det behövs en behörighetsgranskning och en lista över undantagen med vem som äger dom och vilken status dom har.

---

## Kontroll före commit

- [x] Jag har definierat tre relevanta KPI:er.
- [x] KPI:erna mäter mer än enbart genomförda aktiviteter.
- [x] Varje KPI har definition, datakälla och mottagare.
- [x] Varje KPI har ett målvärde, gränsvärde eller en önskad riktning.
- [x] Jag har beskrivit hur KPI:erna ska tolkas och följas upp.
- [x] Jag har beskrivit vad en avvikelse bör leda till.
- [x] Min rapportering är begriplig för en icke-teknisk beslutsfattare.
- [x] Jag har beskrivit KPI:ernas begränsningar.
