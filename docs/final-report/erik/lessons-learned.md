# Post-mortem, lessons learned och professionell sammanfattning

**Student:** Erik Alduaifi

**Utbildning:** IT- och cybersäkerhetstekniker, Chas Academy

**Projekt:** Team 3 Blue Team, hösten 2026

**Datum:** 2026-11-13

**Underlag:** Dokumenterad projektstatus till och med 3 november 2026, kompletterad med PR-historik hämtad 11 november 2026

**Klassificering:** TLP:CLEAR – sanerad rapport avsedd för kursinlämning i offentligt GitHub-repository. Råa hemligheter och känsliga loggar ska hanteras separat.

---

## Händelse och avgränsning

Mitt post-mortem gäller ett **simulerat intrångsförsök via giltig men kvarglömd åtkomst** (MITRE ATT&CK T1078.004, Valid Accounts: Cloud Accounts). När utbildare byttes och miljön flyttades till Comerits GCP-projekt fanns en tidigare instruktörs konto fortfarande kvar i OS Login-konfigurationen och hade därmed fortsatt behörighet att logga in på våra servrar. Inget missbruk har observerats. Scenariot är att kontot, eller en angripare som tagit över det, hade kunnat använda åtkomsten.

Påverkad förmåga är SSH-åtkomsten till jumphost och primary. Åtkomsten togs bort först när miljön flyttades till Comerit och konfigurationen ändå behövde göras om. Det var alltså miljöbytet, inte en rutin eller ett larm, som ledde till att den försvann.

**Min roll:** Jag hade byggt OS Login-lösningen med admin-roll på instansnivå och variabeln `os_admin_users`, vilket gjorde att åtkomsten kunde tas bort som en granskningsbar kodändring. Vid miljöbytet kunde åtkomsten därför tas bort i PR #65 genom att uppdatera konfigurationen, utan manuella ändringar på servrarna. I post-mortem har jag analyserat händelsen och kopplat lärdomarna till mina KPI:er.

---

## Lesson learned 1 – Åtkomst tas inte bort av sig själv

### Observation

En tidigare instruktör hade kvar OS Login-behörighet efter att rollen upphört. Åtkomsten togs bort i PR #65 när vi bytte miljö till Comerit, inte när instruktörens roll upphörde.

### Orsak

Den bakomliggande orsaken var processrelaterad. Det fanns ingen rutin för att ta bort åtkomst när en roll upphör och ingen utsedd ägare för behörighetslistan. Tekniken fungerade som den skulle; det saknades ett steg i förändringshanteringen.

### Konsekvens

Under en okänd period hade en person utan behov fortsatt inloggningsmöjlighet till servrarna. Eftersom inloggningen sker med en giltig identitet hade missbruk varit svårt att skilja från normal användning. Att åtkomsten till slut togs bort berodde på miljöbytet, inte på en kontroll. Utan flytten hade den kunnat ligga kvar längre.

### Förbättring

Inför en enkel avvecklingsrutin: när en person slutar eller byter roll skapas en PR samma arbetsdag som tar bort personen ur `os_admin_users` och övriga IAM-bindningar. Systemägaren ansvarar för att rutinen följs.

### Uppföljning

Följ KPI 1 i [`kpi.md`](kpi.md), som visar om antalet konton med åtkomst minskar till dokumenterade behov. Mät dessutom tiden från avslutad roll till applicerad borttagning (mål: högst en arbetsdag). Kontrollera kvartalsvis att varje konto i behörighetslistorna har ett dokumenterat behov.

---

## Lesson learned 2 – Behörigheter breddas gradvis

### Observation

Efter PR #70 har alla fem teammedlemmar administratörsbehörighet (sudo) på servrarna. CI-tjänstekontot har dessutom `roles/compute.admin` på hela projektet, vilket säkerhetsrapporten anger som hög risk (B02).

### Orsak

Behörigheter lades till för att lösa praktiska behov under projektet, men ingen gick tillbaka och bedömde om de fortfarande behövdes. Minsta behörighet tillämpades på *nivå* (instans i stället för projekt) men inte på *antal* konton.

### Konsekvens

Ju fler konton som har sudo eller breda roller, desto fler vägar finns för en angripare som tar över ett konto eller en pipeline. Det kvarglömda instruktörskontot i lärdom 1 hade haft större påverkan om det haft samma breda roll som CI-kontot.

### Förbättring

Dela upp åtkomsten: de flesta får vanlig inloggning (`os_login_users`) och endast namngivna administratörer får sudo. Begränsa CI-kontot till de operationer pipelinen faktiskt behöver.

### Uppföljning

Följ KPI 1 i [`kpi.md`](kpi.md): antal administratörskonton och antal projektomfattande roller. Ett test från otillåten kontext ska nekas samtidigt som normal deployment fungerar.

---

## Lesson learned 3 – Spårbarhet är inte samma sak som upptäckt

### Observation

OS Login gör att varje inloggning är kopplad till en person. Ändå hade ingen kontroll larmat om det kvarglömda kontot faktiskt använts. Teamets detektionsfall "Oväntad SSH-inloggning" är inte verifierat end-to-end. Red Team-loggarna från kursens separata målmiljöer visar samma mönster: angreppen syntes i loggarna men utlöste inget larm.

### Orsak

Projektet prioriterade förebyggande skydd som identitet, nätverksregler och CI-kontroller. Loggning infördes, men inga larmregler, mottagare eller tester kopplades till inloggningshändelser.

### Konsekvens

Organisationen hade kunnat visa i efterhand *vem* som loggat in, men inte reagera medan det pågick. Vid ett verkligt intrång förlänger det tiden som angriparen kan agera oupptäckt.

### Förbättring

Skapa ett larm för SSH-inloggningar från konton utanför en godkänd lista eller vid ovanliga tider, med en namngiven mottagare. Testa larmet med en kontrollerad testinloggning.

### Uppföljning

Ett kontrollerat test ska ge larm hos rätt mottagare inom fem minuter. Testet upprepas efter varje ändring av identitet eller loggning, och resultatet räknas in i teamets detektions-KPI. Mina egna KPI:er mäter förebyggande kontroll, så den här lärdomen följs upp med teamets detektionsmätning i stället.

---

## Professionell sammanfattning

**Vad som simulerades:** En tidigare instruktör hade kvar inloggningsbehörighet till våra servrar efter att rollen upphört. Vi analyserade vad som hade kunnat hända om kontot använts av fel person. Inget missbruk har observerats.

**Resultat och betydelse:** Den identitetsbaserade åtkomsten med OS Login fungerade som avsett. Behörigheten kunde tas bort med en enda granskad kodändring, och vi kan se exakt vem som har åtkomst. Det som brast var processen runt tekniken. Åtkomsten togs bort först när vi bytte miljö, inte när rollen upphörde. Med tiden har dessutom alla i teamet fått administratörsbehörighet, och CI-kontot har bred behörighet i hela projektet. Ingen kontroll hade larmat om kontot faktiskt använts.

**Huvudlärdom:** Att *kunna* styra åtkomst är inte detsamma som att *göra* det regelbundet. Identitet ger spårbarhet i efterhand, men utan rutiner och larm upptäcks missbruk för sent.

**Rekommenderade prioriteringar:**

1. **Nu:** Inför en rutin som tar bort åtkomst inom en arbetsdag när en roll upphör, med systemägaren som ansvarig.
2. **Nästa förbättringsperiod:** Minska antalet administratörer till namngivna behov och begränsa CI-kontots projektomfattande roll.
3. **Löpande:** Inför och testa larm för oväntade SSH-inloggningar.

**Beslut som behövs:** Ledningen behöver utse en ägare för behörighetsgranskningen och godkänna en kvartalsvis granskning. Uppföljningen sker genom KPI 1 i [`kpi.md`](kpi.md) (antal administratörskonton), en mätning av tid till borttagen åtkomst och teamets detektionstest för oväntad SSH-inloggning.

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

**Källor:** [Teamets säkerhetsrapport](../../blue-team-security-report.md) · [Min individuella bidragsredogörelse](../../erik-individuellt-bidrag.md) · [Individuell slutrapport](individual-report.md) · [KPI:er och säkerhetsmätningar](kpi.md)
