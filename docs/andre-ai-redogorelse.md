# Min AI-redogörelse – Andre Edvardsson

Jag har använt AI ganska mycket under Blue Team-projektet, framför allt när jag fastnat eller behövt förstå vad ett felmeddelande betydde. Den hjälpte mig till exempel med Headscale, DNS, OS Login, Kubernetes och våra GitHub Actions. Jag använde den också för att få förslag på Terraform- och Kubernetes-kod och för att göra säkerhetsrapporten lättare att läsa.

Jag märkte tidigt att jag inte kunde lita blint på svaren. Ibland föreslog AI kommandon som inte passade vår miljö, blandade ihop vad som fanns i koden med vad som faktiskt kördes eller gav för stora behörigheter. Därför körde jag inte bara allt den föreslog. Jag läste ändringarna, jämförde med dokumentation och testade i små steg. För att kontrollera resultatet använde jag bland annat pytest, Trivy, Cosign, Checkov, TFLint, `kubectl`, `gcloud` och vanliga hälsokontroller.

Ett konkret exempel var när appen skulle köras som en användare utan root-rättigheter. Innan ändringen tog jag backup på SQLite-databasen och kontrollerade att den nya användaren kunde skriva till den. Efter deployment kontrollerade jag användar-ID, databasanslutning och `/healthz`. När vi ändrade Headscale DNS tog jag först en kopia av konfigurationen och körde `headscale configtest`, eftersom ett fel där hade kunnat stänga ute hela gruppen.

Sårbarhetsscanningen var ett annat exempel. AI kunde föreslå att vi skulle ignorera fynd eller ta bort paket för att få ett grönt resultat. Jag tyckte inte att det räckte. I stället byggde och skannade jag imagen, kontrollerade vilka kodvägar som faktiskt användes och dokumenterade tidsbegränsade undantag för bestämda CVE:er. Nya fynd ska fortfarande ge larm.

För mig var AI mest användbar som bollplank och för att snabbt hitta möjliga lösningar. Den var mindre lämplig för beslut om IAM, hemligheter, riskacceptans eller kommandon som kunde förstöra något. De besluten behövde jag själv förstå och kontrollera. Det viktigaste jag tar med mig är därför att AI kan spara tid, men att resultatet alltid måste verifieras mot kod, tester och den riktiga miljön.

