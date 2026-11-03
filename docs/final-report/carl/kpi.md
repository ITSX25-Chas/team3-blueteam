# KPI:er och säkerhetsmätningar

**Student:** Carl Persson
**Projekt:** Team 3 Blue Team

## KPI 1 – Andel lyckade säkra deploymenter

| Fält | Innehåll |
|---|---|
| Syfte | Visa om leveranskedjan både fungerar och genomför säkerhetskontrollerna. |
| Definition | Antal deploymenter på `main` där tester, imagebygge, SBOM, Cosign-signering, anslutning och Kubernetes-rollout lyckas, dividerat med totalt antal deploymenter på `main`. |
| Formel | `lyckade säkra deploymenter / alla deploymenter × 100` |
| Datakälla | GitHub Actions i `Team3-ThaCompany`. |
| Frekvens | Veckovis och efter större ändringar. |
| Nuläge | Senaste verifierade körningen `41608640621` klarade samtliga steg. Längre historik behöver räknas innan en stabil baslinje anges. |
| Mål | Minst 95 %, och 100 % av lyckade deploymenter ska ha passerat samtliga säkerhetssteg. |
| Åtgärd vid avvikelse | Stoppa release, identifiera felsteget, skapa issue och verifiera korrigeringen med en ny körning. |
| Evidens | [Lyckad deployment](https://github.com/ITSX25-Chas/Team3-ThaCompany/actions/runs/41608640621). |

**Egen motivering:** _Beskriv kort varför denna KPI är viktig ur ditt perspektiv._

## KPI 2 – Critical-fynd och utgångna riskundantag

| Fält | Innehåll |
|---|---|
| Syfte | Förhindra att allvarliga eller inte längre godkända sårbarheter ignoreras. |
| Definition | Antalet öppna Critical-fynd plus antalet High/Critical-undantag vars slutdatum har passerat. |
| Formel | `öppna Critical + utgångna undantag` |
| Datakälla | Trivy-resultat, CycloneDX-SBOM, scannerloggar, Discord-larm och riskundantagsfil. |
| Frekvens | Vid varje imagebygge och minst dagligen via scannerjobbet. |
| Nuläge | Senaste dokumenterade skanning: 0 Critical, 44 High-paketträffar och nio tidsbegränsade undantag till 20 november 2026. |
| Mål | 0 öppna Critical och 0 utgångna undantag. |
| Åtgärd vid avvikelse | Blockera eller återställ deployment, triagera fyndet, utse ansvarig och dokumentera åtgärd eller ny riskacceptans. |
| Evidens | [Säkerhetsrapport, avsnitt 6](../../blue-team-security-report.md#6-incidenter-och-lärdomar). |

**Egen motivering:** _Förklara skillnaden mellan riskacceptans och att en sårbarhet är åtgärdad._

## KPI 3 – Testad detektionstäckning

| Fält | Innehåll |
|---|---|
| Syfte | Mäta om viktiga händelser faktiskt kan upptäckas, inte bara om loggning finns konfigurerad. |
| Definition | Antal prioriterade detektionsfall som testats end-to-end och gett förväntad evidens/larm, dividerat med fem planerade fall. |
| Formel | `godkända detektionstester / 5 × 100` |
| Datakälla | GCP Audit Logs, OS Login/sshd-loggar, Headscale-journal, GitHub Actions, Kubernetes-loggar och Discord. |
| Frekvens | Månadsvis och efter ändringar i loggning eller larm. |
| Baslinje | 1 av 5 fall är tydligt verifierat end-to-end: sårbar image/scannerlarm = 20 %. |
| Mål | Minst 80 % inom nästa förbättringsperiod och 100 % på längre sikt. |
| Åtgärd vid avvikelse | Avgör om insamling, regel, notifiering eller ansvar saknas; skapa förbättringsärende och kör om testet. |
| Evidens | [Säkerhetsrapport, avsnitt 7](../../blue-team-security-report.md#7-loggning-och-detektion). |

**Egen motivering:** _Välj vilket av de återstående detektionsfallen som bör testas först och förklara varför._

## Egen slutsats

_Förklara vilken KPI du skulle visa först för en teknisk chef respektive ledningsgrupp._
