# Individuell slutrapport – Carl Persson

**Utbildning:** IT- och cybersäkerhetstekniker, Chas Academy  
**Projekt:** Team 3 Blue Team, hösten 2026  
**Underlag:** Dokumenterad projektstatus till och med 3 november 2026  
**Klassificering:** **TLP:CLEAR** – sanerad slutrapport avsedd för kursinlämning i offentligt GitHub-repository. Råa hemligheter och känsliga loggar ska hanteras separat.

## 1. Sammanfattning för ledningen

Team 3 byggde en säkerhetsmiljö i Google Cloud Platform med Terraform, en jumphost för kontrollerad åtkomst, Headscale/Tailscale för privat nätverkskommunikation och en primary-server med Kubernetesdistributionen k3s. Miljön kompletterades med OS Login, IAM, Workload Identity Federation, begränsade brandväggsregler och en leveranskedja med SBOM, imagesignering och sårbarhetsskanning. Mitt individuella arbete låg främst inom GCP-infrastruktur, Headscale-ACL, routing, split DNS och felsökning av nätverksåtkomst. Efter flytten till Comerits projekt verifierade teamet den 3 november en fungerande applikation i det återställda klustret, men migrationen visade också att infrastrukturen inte automatiskt återställde tjänsternas data och identiteter. Den största lärdomen är att **konfiguration, faktisk drift, återställningsbarhet och detektionsförmåga måste mätas var för sig**. Jag rekommenderar först återställningstest för Headscale, därefter verifierade larm för SSH/Headscale och minskning av kvarvarande identitetsrisker. Rapporten redovisar tre KPI:er, tre lärdomar, en evidensbaserad post-mortem och en ATT&CK-baserad prioritering.

## 2. Vad vi byggde och varför

Arkitekturen bestod av en GCP-VPC med jumphost (`10.0.3.2`) och primary (`10.0.3.3`). Headscale hanterade Tailnet-medlemskap och routing; Tailscale-klienter fick kontrollerad åtkomst till interna resurser. OS Login och IAM styrde VM-inloggning, medan Headscale-ACL och brandväggar avgränsade nätverkstrafik. GitHub Actions använde Workload Identity Federation för att nå GCP utan traditionell långlivad molnnyckel. Applikationen levererades till k3s med SBOM, Cosign-signering, policykontroller, Trivy och notifieringar.

Den säkerhetsmässiga poängen var **flera oberoende skyddslager**: en användare ska inte få administratörsrättigheter bara för att den är ansluten till Tailnet, en signerad image ska fortfarande granskas för sårbarheter och en grön pipeline ska verifieras mot rätt kluster. Teamets [säkerhetsrapport](../../blue-team-security-report.md) dokumenterar införda kontroller och deras begränsningar.

## 3. Mina egna bidrag och spårbar evidens

Jag gör inte anspråk på att ensam ha byggt CI/CD, k3s eller applikationens scanner. Mitt spårbara huvudansvar låg i nätverk och infrastruktur.

| Eget bidrag | Vad jag gjorde och varför | Primär evidens |
|---|---|---|
| **Shielded VM** | Arbetade med att aktivera VM-skydd i Terraform. Syftet var att stärka integriteten i VM-miljön. | [Commit `6e00e17a`](https://github.com/ITSX25-Chas/team3-blueteam/commit/6e00e17a) |
| **Primary och säker nätverksåtkomst** | Arbetade med primary-instansen och åtkomstvägar mellan interna resurser. | [Commit `38b7278a`](https://github.com/ITSX25-Chas/team3-blueteam/commit/38b7278a) |
| **Headscale-ACL** | Ändrade policy för studenter, administratörer, utvecklare och anställda för att begränsa åtkomst mellan roller. | [Commit `92af4437`](https://github.com/ITSX25-Chas/team3-blueteam/commit/92af4437), `headscale/policy.hujson` |
| **Spectre-routing och split DNS** | Lade till stöd för rätt nätverksväg och intern namnuppslagning till Spectre. | [Commit `88d73d48`](https://github.com/ITSX25-Chas/team3-blueteam/commit/88d73d48) |
| **Praktisk felsökning** | Undersökte SSH, Tailnet, DNS, GCP-zonflytt, jumphost och intern kontra publik Spectre-åtkomst. | [Min tidigare individuella redogörelse](../../carl-individuellt-bidrag.md), systemkontroller med `ssh`, `tailscale status`, `curl` och DNS |

### 3.1 Åtkomst och segmentering

I Headscale-policyn arbetade jag med principen om **minsta behörighet**: roller ska få åtkomst till de tjänster de behöver, inte automatiskt hela nätet. Det är viktigt att skilja på nätverksmedlemskap, nätverksåtkomst och operativsystemets privilegier. En godkänd Tailnet-anslutning ger inte i sig rätt till SSH eller `sudo`. Min ACL-commit visar policyändringen, men en fullständig positiv och negativ åtkomstmatris för samtliga roller är inte dokumenterad som verifierad. Det är därför ett förbättringsförslag, inte ett påstått färdigt testresultat.

### 3.2 DNS, routing och felsökning

Jag arbetade med att nå Spectre via rätt intern väg och med split DNS. Vid felsökning såg vi att samma hostname kunde ge olika HTTP-resultat beroende på om klienten gick via publik eller intern proxyväg: den publika vägen gav 403 och den interna 200. Efter Headscale-ominstallation hade `base_domain` och split-DNS-inställningar hamnat fel. Konfigurationen säkerhetskopierades, validerades med `headscale configtest` och korrigerades; klientens `accept-dns` måste också kontrolleras. För mig visade detta att ett DNS-fel inte får förväxlas med ett brandväggs- eller applikationsfel.

### 3.3 VM-byte och Headscale-state

När jumphosten flyttades till en annan GCP-zon på grund av resursbrist förändrades SSH-hostkey och Headscale-state/registrering behövde återställas. Jag arbetade med att undersöka anslutningsproblemen. Jag lärde mig att en ändrad hostkey efter ett känt VM-byte kan ha en legitim förklaring, men ändå måste verifieras mot den faktiska infrastrukturen; varningen ska inte bara ignoreras. Jag lärde mig också att Terraform inte automatiskt säkerhetskopierar Headscales databas och serveridentitet.

### 3.4 Shielded VM – säkerhetskontroll kontra tillgänglighet

Projektet fick ett konkret problem när Secure Boot aktiverades med labbens image: GRUB/serieporten visade signaturfel och operativsystemet startade inte, trots att GCP visade `RUNNING`. Teamet stängde av Secure Boot men behöll vTPM och integrity monitoring. [Issue #32](https://github.com/ITSX25-Chas/team3-blueteam/issues/32) dokumenterar problemet. Min Shielded VM-commit är spårbar; jag tillskriver mig inte ensam hela incidentutredningen. Lärdomen är att hårdning måste verifieras genom fungerande boot, inloggning och återställning.

## 4. Resultat: vad teamet verifierade

| Område | Verifierat eller dokumenterat resultat | Begränsning |
|---|---|---|
| **GCP/CI** | Terraform, WIF, blockerande TFLint/Checkov och skyddat huvudflöde; deployment i Comerits projekt lyckades. | Projektomfattande CI-behörigheter och state-bucketens faktiska skydd behöver fortsatt granskning. |
| **Kubernetes** | Efter återställning 3 november: k3s, `1/1 Ready`, NetworkPolicy, Sigstore-policy `enforce`, HTTP 200. | k3s och routerstate är inte helt deklarerade i Terraform. |
| **Applikationshärdning** | Appen kör som UID/GID 10001, utan service-account-token, med `drop ALL`, nekad privilege escalation och RuntimeDefault seccomp. | En non-root-container eliminerar inte alla CVE:er eller indirekta RBAC-vägar. |
| **Sårbarheter** | 0 Critical och 44 High-paketträffar = 9 unika CVE:er i senast dokumenterad ombyggd image. | Undantag till 20 november är riskacceptans, inte patchning; senaste konfigurationens driftsättning var inte bekräftad. |
| **Detektion** | Grönt och märkt rött scanner-/Discord-test verifierat. | Endast 1 av 5 prioriterade end-to-end-detektionstester verifierade. |
| **Migration** | Ny subnet-router, k3s och kubeconfig gav lyckad [appdeployment 41608640621](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621). | Gammal route ledde tidigare till fel kluster; Headscale-state har kvarstående återställningsrisk. |

Detta är **teamets samlade resultat**, inte bevis för att jag personligen utförde varje del. [Säkerhetsrapporten](../../blue-team-security-report.md) skiljer mellan observerad driftstatus, äldre kontroller och konfiguration som bara finns i kod.

## 5. KPI:er – hur säkerhetsarbetet följs upp

De tre mätningarna definieras fullständigt i [kpi.md](kpi.md):

1. **Andel lyckade säkra deploymenter:** mål minst 95 %. En lyckad körning 3 november finns, men den historiska andelen är inte beräknad. Viktigt att även verifiera **rätt kluster**.
2. **Öppna Critical och förfallna riskundantag:** mål 0 + 0. Senast dokumenterades 0 Critical, 44 High-paketträffar och nio unika CVE:er med tidsbegränsad riskacceptans.
3. **Verifierad detektionstäckning:** baslinje 1/5 = 20 %, mål minst 4/5 = 80 % nästa period.

**Min prioritering:** KPI 3 är viktigast eftersom våra verkliga problem med Headscale, SSH och routing visar att tillgänglighet och säkerhetsstatus måste kunna upptäckas. Jag skulle presentera 20 % för en icke-teknisk chef som: *”Vi har verifierat att en av fem prioriterade typer av säkerhetshändelser leder till avsett larm. Fyra tester återstår innan vi kan bedöma den planerade övervakningen.”* Det är mer korrekt än att säga att 80 % av angreppen skulle missas.

## 6. Threat intelligence, MITRE ATT&CK och actionable intelligence

Threat intelligence innebär här att omvandla kända tekniker och dokumenterade kontrollbrister till **prioriterade skydds- och detektionsbeslut**. Vi har **inte** belägg för att en namngiven hotaktör angripit vår miljö. ATT&CK-mappningen är därför en scenariobaserad analys, inte en incidentattribuering.

| Prioritet | Möjligt angriparbeteende | ATT&CK och koppling | Åtgärd, ägare och verifiering |
|---|---|---|---|
| **Hög** | Missbruk av giltigt moln-/CI-konto | [T1078.004 – Valid Accounts: Cloud Accounts](https://attack.mitre.org/techniques/T1078/004/). Bred infra-CI och IAM kan ge större effekt vid kompromettering. | **GCP/CI-ansvarig:** minska projektomfattande roller, verifiera WIF-villkor och larma på ovanliga IAM-ändringar. Testa Audit Log med aktör och notifiering. |
| **Hög** | Indirekt åtkomst via tillåten containeradministration | [T1610 – Deploy Container](https://attack.mitre.org/techniques/T1610/). Scanner-CronJob-rättighet gav tidigare en indirekt secret-väg; den är borttagen, men viss secret-åtkomst kvarstår. | **Kubernetes/CI-ansvarig:** testa negativa RBAC-fall, separera deploy och scanner, övervaka oväntade poddar och jobb. |
| **Hög** | Läsning av autentiseringsmaterial | [T1552.001 – Credentials In Files](https://attack.mitre.org/techniques/T1552/001/). Långlivad kubeconfig/token och Headscale-state är känsliga tillgångar. | **Infra/Kubernetes:** begränsa lagring, åtkomst och livslängd; kontrollera backup och rotationsprocedur. Ingen hemlighet ska läggas i rapport eller logg. |
| **Medel** | Försvagning av säkerhetskontroller | [T1562.001 – Impair Defenses](https://attack.mitre.org/techniques/T1562/001/). Scannerundantag och CI-konfiguration kan ge falsk trygghet om de ändras okontrollerat. | **Scanner/CI-ansvarig:** PR-granska undantag, verifiera SBOM-attestering och gör märkt rött larmtest efter ändring. |
| **Medel** | Kartläggning av interna tjänster efter kompromettering | [T1046 – Network Service Discovery](https://attack.mitre.org/techniques/T1046/). Felaktig egress/NetworkPolicy kan möjliggöra intern upptäckt. | **Nätverk/Kubernetes:** testa tillåtna och nekade nätverksflöden och granska policy vid nya beroenden. |

**Bedömning av tillförlitlighet:** Riskerna grundas i [teamets verifierade säkerhetsrapport](../../blue-team-security-report.md), men ATT&CK-teknikerna är **möjliga beteenden**, inte observerade attacker. Jag prioriterar identitet och indirekta privilegievägar före allmän versionsinformation eftersom de kan påverka flera skyddslager samtidigt. Detektionsförslagen knyts till KPI 3; scanner- och undantagskontrollerna till KPI 2.

### TLP och professionell informationsdelning

Den här **sanerade** sammanställningen märks **TLP:CLEAR**, eftersom den ska ligga i ett offentligt GitHub-repository för kursinlämning och inte innehåller autentiseringsuppgifter eller råa känsliga loggar. TLP styr **vem informationen får delas med**, inte riskens allvar. Fullständiga kubeconfig, privata nycklar, tokens, lösenord och känsliga råloggar ska inte publiceras oavsett TLP. Mer detaljerad intern incident- eller åtkomstinformation måste klassificeras separat före delning. Källa: [FIRST – Traffic Light Protocol](https://www.first.org/tlp/).

## 7. Post-mortem och tre viktigaste lärdomar

Detta avsnitt gäller **dokumenterade drift-/säkerhetshändelser i Blue Team-projektet**, inte ett påstått bekräftat intrång. Utförlig orsaksanalys finns i [lessons-learned.md](lessons-learned.md).

**Lärdom 1: Infrastruktur som kod är inte en komplett återställningsplan.** När jumphosten ersattes försvann Headscale-state och senare saknade ny primary k3s. Orsaken var beständigt tjänstetillstånd utanför fullständig IaC. Konsekvensen blev återställningsarbete och risk för förlorad åtkomst. Nästa gång skulle jag kartlägga state, backup och restore-test före driftstart.

**Lärdom 2: Rätt IP är inte bevis för rätt kluster.** Efter migrationen annonserade gammal subnet-router samma interna nät. Teamet upptäckte skillnaden genom certifikat/fingerprint och korrigerade route och kubeconfig innan deployment godkändes. Jag skulle göra miljöidentitet till obligatoriskt releasekriterium.

**Lärdom 3: Least privilege och larm måste testas i praktiken.** Teamet identifierade en indirekt RBAC-väg via scanner-CronJob och tog bort den. Bara ett av fem prioriterade detektionsfall verifierades. Jag vill komplettera ACL/RBAC med negativa tester och öva larmkedjan end-to-end.

**Incidentresponsens logik:** observera fel eller avvikelse → säkra relevanta loggar och tidsstämplar → avgränsa identitet/nät/tjänst → begränsa skadan utan att förlora reservåtkomst → återställ från känd konfiguration → verifiera faktisk tjänst och säkerhetskontroll → dokumentera rotorsak och uppföljningsärende. Underlaget visar flera sådana felsöknings- och återställningssteg, men **inte** en fullständig uppmätt MTTD/MTTR eller ett bekräftat detektionsutfall från ett separat försvarande lag. Det vore missvisande att hitta på dessa värden.

## 8. Tre prioriterade rekommendationer

| När | Beslut och ansvar | Förväntad effekt | Klart när |
|---|---|---|---|
| **Nu** | **Infrastrukturansvarig:** skydda och säkerhetskopiera Headscale-state, dokumentera nycklar/beroenden och testa återställning till ersättnings-VM. | Minskad risk för bortfall av nätverksåtkomst vid zonflytt eller VM-byte. | Testprotokoll visar fungerande klientregistrering, DNS, ACL, routes och SSH efter återställning. |
| **Nästa steg** | **Detektions-/driftansvarig:** testa fyra kvarvarande larmfall, börja med oberoende Headscale-hälsokontroll och OS Login/sshd-korrelation. | Detektionstäckning från 20 % till minst 80 % och tydligt ansvar vid larm. | Fyra av fem end-to-end-fall har loggevidens, notifiering och mottagare. |
| **Längre sikt** | **GCP/CI/Kubernetes-ansvariga:** begränsa kvarvarande projektroller, secret-åtkomst och långlivade identiteter; automatisera k3s/bootstrap och verifiera rätt målkluster. | Mindre spridningseffekt vid kontokompromettering och säkrare leveranser. | Negativa RBAC-tester, uppdaterad IAM-granskning, kortlivad autentisering och verifierad klusteridentitet i CI. |

Utöver dessa prioriteringar behöver riskundantagen för nio CVE:er granskas **före 20 november 2026**. Rekommendationerna är förslag, inte påståenden att allt redan är infört.

## 9. AI-användning: nytta, risker och professionellt ansvar

Jag använde ChatGPT som stöd vid felsökning av Headscale/Tailscale, SSH, GCP-zonflytt, OS Login, DNS och subnet-routing. AI hjälpte mig att snabbt formulera hypoteser, förstå felmeddelanden och hitta lämpliga kontrollkommandon. Ett konkret exempel var ändrad SSH-hostkey och utebliven Headscale-anslutning efter VM-ersättning: AI kunde beskriva möjliga orsaker, men bara kontroll av den verkliga VM:n, nyckelbytet, `tailscale status`, SSH och Headscale-registreringen kunde avgöra vad som faktiskt hänt.

**När AI är lämpligt:** begreppsförklaring, förslag på diagnostik, jämförelse av möjliga orsaker, strukturering av dokumentation och granskning av tänkta teststeg. **När AI inte är lämpligt som ensam källa:** beslut om IAM/ACL, borttagning av resurser, nyckelrotation, riskacceptans, påståenden om faktisk driftstatus eller klassificering av en incident. Generativa modeller kan ge trovärdiga men felaktiga kommandon, missa miljöspecifika beroenden och föreslå för breda rättigheter.

**Min verifieringsmetod:** (1) förstå förslaget, (2) jämför med aktuell konfiguration och officiell dokumentation, (3) kör den minsta säkra kontrollen, (4) bedöm resultatet och ändra kontrollerat, (5) verifiera efteråt och spara evidens. Jag körde själv kommandon och fattade de tekniska besluten. Jag använde inte AI som bevis för att en anslutning eller säkerhetskontroll fungerade. Jag ska heller inte mata in hemligheter eller osanerade loggar i en AI-tjänst utan uttryckligt godkännande och lämplig informationshantering.

Teamet använde också deterministiska säkerhetsverktyg som TFLint, Checkov, Trivy, Cosign och Kubernetes-kontroller. Dessa har en annan roll än generativ AI: de ger reproducerbara testresultat inom sina avgränsningar, men måste fortfarande tolkas kritiskt. Exempelvis betyder 44 Trivy-träffar inte 44 exploaterbara hål, och ett grönt CI-steg bevisar inte att rätt kluster nåtts. Min tidigare [individuella AI-redogörelse](../../carl-ai-redogorelse.md) beskriver mina egna exempel.

## 10. Min utveckling och LIA

Arbetet gjorde mig säkrare i praktisk Linux-/GCP-felsökning, SSH och identitet, Tailnet, DNS, routing och versionshanterade infrastrukturändringar. Jag fick bättre förståelse för hur ett till synes enkelt nätverksproblem kan bero på förlorad tjänsteidentitet, felaktig route eller ett annat målkluster. Jag lärde mig också att säkerhetsarbete måste kunna **kommuniceras som risk och beslut**, inte bara som kommandon och konfigurationsfiler.

Inför LIA och en framtida roll inom IT- och cybersäkerhet, särskilt säkerhetsdrift/SOC/SIEM, tar jag med mig att korrelera olika evidenskällor, vara tydlig med osäkerhet och prioritera kontroller som går att testa. Mitt mål är att kunna förklara för både tekniker och beslutsfattare **vad vi vet, hur vi vet det, vilken risk som återstår och vad som bör göras härnäst**.

## 11. Källor och egen kvalitetskontroll

- [Teamets Blue Team-säkerhetsrapport](../../blue-team-security-report.md) – arkitektur, verifierade kontroller, risker, incidenter, MITRE och TLP.
- [Mina individuella bidrag](../../carl-individuellt-bidrag.md) – fyra commits och praktiskt felsökningsarbete.
- [Min AI-redogörelse](../../carl-ai-redogorelse.md) – användning och verifiering.
- [KPI-dokument](kpi.md) och [Lessons learned](lessons-learned.md).
- [Issue #32: Secure Boot](https://github.com/ITSX25-Chas/team3-blueteam/issues/32), [återställningsguide](../../restore-primary-k3s.md) och [verifierad appdeployment](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621).

**Avgränsningar:** Jag skiljer mina egna commits från teamresultat. En lyckad körning är inte en historisk KPI-andel; en riskacceptans är inte en patch; konfiguration i Git är inte alltid verifierad drift; ATT&CK-mappning är inte bevis på intrång. Ingen hemlighet eller kubeconfig återges.

**Kontroll före inlämning:** Jag behöver själv läsa och godkänna den slutliga texten, verifiera att länkar fungerar och att de tre filerna är committade/pushade till GitHub. Deadline enligt uppgiften: **15 november 2026 kl. 23.59**.