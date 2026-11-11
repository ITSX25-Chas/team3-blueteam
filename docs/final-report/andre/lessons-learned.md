# Lessons learned och professionell sammanfattning

**Student:** André Edvardsson  
**Projekt:** Team 3, kurs 6 – avancerad IT-säkerhet

## Lärdom 1 – Infrastruktur som kod omfattar inte automatiskt driftstillstånd

- **Händelse:** Efter flytten till Comerits GCP-projekt fanns VM-resurserna, men nya primary saknade k3s. Samtidigt pekade en gammal Headscale-route fortfarande mot det tidigare klustret.
- **Orsak:** Terraform beskrev huvudsakligen molnresurserna. k3s-installation, Headscale-state, routes, kubeconfig och vissa säkerhetskomponenter hade manuella beroenden.
- **Konsekvens:** En lyckad Terraform-körning kunde misstolkas som att hela tjänsten var återställd. Det ökade återställningstiden och risken att deploya till fel kluster.
- **Vad som fungerade:** Vi jämförde certifikat och faktiskt klustertillstånd, installerade om k3s, ingress och Sigstore-policy, roterade kubeconfig och flyttade subnet-routen. Därefter verifierades pod `1/1`, NetworkPolicy och HTTP 200.
- **Förbättring:** Versionsstyr hela återställningskedjan, säkerhetskopiera nödvändigt state och genomför regelbundna återställningstester med tydliga acceptanskriterier.
- **Uppföljning:** Mät återställningstid och andel komponenter som kan återskapas från dokumenterad kod utan manuella specialsteg.

**Min reflektion:** Nästa gång skulle jag tidigt skapa en lista över allt beständigt tillstånd och inte anta att det som saknas i Terraform är oviktigt. Jag skulle också testa återställningen innan ett miljöbyte blir skarpt.

## Lärdom 2 – En grön pipeline måste verifieras mot rätt mål och verklig effekt

- **Händelse:** Appens pipeline kunde nå adressen `10.0.3.3`, men trafiken gick först till det gamla klustret genom en kvarvarande route.
- **Orsak:** Gammal och ny miljö använde samma interna adress, medan routing, certifikat och kubeconfig inte byttes samtidigt.
- **Konsekvens:** Ett grönt resultat hade kunnat ge falsk trygghet. Pipeline-status visade att kommandona lyckades, inte automatiskt att rätt miljö förändrades.
- **Vad som fungerade:** TLS-kontrollen stoppade ett försök när certifikatet inte matchade. Efter route- och kubeconfigbytet passerade deployment `41608640621` och körningen verifierades direkt i nya klustret.
- **Förbättring:** Varje deployment ska verifiera projekt, klusteridentitet, image-digest, rollout och tjänstehälsa. Kritiska miljöbyten behöver en checklista och en tydlig rollbackväg.
- **Uppföljning:** Följ KPI:n för säkra deploymenter och kräv att 100 % av lyckade körningar innehåller identitets- och hälsokontroll.

**Min reflektion:** Den starkaste evidensen är en kedja av bevis: rätt projekt och certifikat, rätt image-digest i deploymenten, körande pod och ett lyckat funktionstest. Ett enskilt grönt jobb räcker inte.

## Lärdom 3 – Roller, ansvar och dokumentation är säkerhetskontroller

- **Händelse:** Under projektet förändrades utbildare, molnmiljö, GitHub-organisation, instruktioner och deadlines. För vissa delar var det otydligt vem som ägde kursmaterial, labbmiljö, tekniska beslut och uppföljning. Post-mortem-loggarna blev tillgängliga först senare.
- **Orsak:** Roller, ansvar, ändringshantering och acceptanskriterier var inte alltid samlade och versionshanterade på ett ställe.
- **Konsekvens:** Teamet lade mycket tid på tolkning och felsökning. Uppgifter riskerade att missas, göras dubbelt eller hamna hos ett fåtal personer. Det gjorde även individuell spårbarhet svårare.
- **Vad som fungerade:** Git-historik, issues, pull requests, rapporter och återställningsguider gav ändå spårbarhet. När loggarna kom kunde attackstegen tidslinjeläggas och post-mortem uppdateras med faktisk evidens.
- **Förbättring:** Använd en enkel RACI för projektägare, systemägare, incidentledare, teknisk utförare, kommunikationsansvarig och dokumentationsansvarig. Förändringar ska ha ägare, datum, konsekvensbedömning och tydlig kommunikationskanal.
- **Uppföljning:** Efter varje incident eller större förändring hålls ett post-mortem utan skuldfokus. Varje åtgärd får ansvarig, deadline och mätpunkt. Öppna åtgärder följs upp tills de är verifierade.

**Min reflektion:** Tydliga roller är särskilt viktiga i incidenthantering. Alla behöver göra sin del och dokumentera vad som gjordes, när och med vilket resultat. Uppföljningen ska både lyfta det som fungerade och det som behöver förbättras.

## Professionell sammanfattning

Team 3 byggde en sammanhängande säkerhetslösning med Terraform, OS Login, begränsade nätverksregler, Workload Identity Federation, k3s, NetworkPolicy, non-root-container, signerade images, SBOM och återkommande sårbarhetsskanning. Den återställda miljön i Comerit verifierades genom en lyckad pipeline, körande applikation och praktiska säkerhetskontroller.

Projektets största kvarstående risker är manuella beroenden i återställningen, långlivad Kubernetes-autentisering, nio tidsbegränsade sårbarhetsundantag och otillräckligt testad larmförmåga. Red Team-loggarna kom från en separat Acme-målmiljö, men gav en viktig generell lärdom: fyra av sex attacksteg var fullt synliga och två delvis synliga, samtidigt som inget observerat larm utlöstes. Loggning utan regler, notifiering och ansvar ger inte tillräcklig incidentförmåga.

Jag rekommenderar följande prioritering:

1. **Nu:** Ompröva de nio CVE-undantagen före 20 november och säkerställ ansvarig för varje beslut.
2. **Nästa förbättringsperiod:** Automatisera och öva återställning av k3s, routing, policy och kubeconfig.
3. **Löpande:** Inför kontrollerade detektionstester med central loggning, tydliga larmregler, ansvarig mottagare och mätbar MTTD.

För ledningen är huvudbudskapet att många tekniska skydd nu finns på plats, men att säkerheten behöver förvaltas. Riskundantag, återställning och larmförmåga måste följas upp som återkommande processer och inte betraktas som engångsuppgifter.
