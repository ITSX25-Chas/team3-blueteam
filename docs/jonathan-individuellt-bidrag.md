# Individuellt bidrag – Jonathan Tsubarah

## Mina bidrag

Mitt arbete i Blue Team-projektet har främst handlat om identitet och behörigheter i GCP, nätverksåtkomst, Headscale och CI/CD.

- Jag satte upp grundstrukturen för repot.
- Jag bytte CI/CD-autentiseringen från en SA-nyckel till Workload Identity Federation och tog sedan bort den långlivade nyckeln (issue #8, #10, #28, PR #1, #20).
- Jag ersatte `roles/editor` för CI/CD-kontot med specifika roller enligt least privilege (issue #14, PR #57).
- Jag kopplade ett eget service account till jumphosten istället för default compute SA (issue #16, PR #35).
- Jag ersatte `team3-allow-traffic` som släppte in all trafik från 0.0.0.0/0 med en begränsad SSH-regel, och lade till IAP-baserad åtkomst (issue #13, #26, #29, PR #23, #25, #30).
- Jag ersatte `*:*` i Headscale-policyn med specifika regler och lade till den fiktiva företagsdelen (issue #46, #48, PR #49).
- Jag tog bort ssh-keys ur jumphostens metadata (issue #51, PR #50).
- Jag skyddade och aktiverade loggning på state-bucketen (issue #12, #59, PR #60).
- Jag utredde och dokumenterade varför Secure Boot inte går att aktivera med labbens image (issue #32, PR #33).
- När jumphosten stoppades av en stockout i europe-north2-c flyttade jag den till europe-north2-b (PR #61). Eftersom Headscale var manuellt installerad försvann den när disken byttes, så jag installerade om Headscale, återskapade användarna, routing och split DNS, och tog fram nya nycklar till teamet och CI.

I Team3-ThaCompany:
- Jag uppgraderade sårbara beroenden (PR #20).
- Jag lade till CronJob för SBOM-scanning med larm till Discord (PR #21).
- Jag fixade så att `view_profile` inte skickar andras internal notes till templaten, med ett test som verifierar det (PR #22).

## Verifiering och lärdomar

Innan varje merge läste jag `terraform plan` för att se vad som faktiskt skulle ändras. Efteråt kontrollerade jag resultatet i GCP, till exempel att det inte fanns några nycklar kvar efter att SA-nyckeln tagits bort. Efter ominstallationen av Headscale verifierade jag med `tailscale status`, `headscale nodes list` och `curl` mot Spectre.

Den största lärdomen var att det som inte är byggt som kod försvinner när infrastrukturen byts ut. Headscale låg utanför Terraform, och det märktes först när jumphosten ersattes.

## Git-historik

Följande commits i infra-repot är registrerade med författaren `jonatsub`:

- [`5623df47`](https://github.com/ITSX25-Chas/team3-blueteam/commit/5623df47) – initial commit
- [`903a6b77`](https://github.com/ITSX25-Chas/team3-blueteam/commit/903a6b77) – Switch CI/CD auth to Workload Identity Federation
- [`fbaa1d33`](https://github.com/ITSX25-Chas/team3-blueteam/commit/fbaa1d33) – Remove long-lived CI/CD service account key
- [`b58d02a5`](https://github.com/ITSX25-Chas/team3-blueteam/commit/b58d02a5) – Add IAP-based SSH access and scoped firewall rules
- [`9c20f45a`](https://github.com/ITSX25-Chas/team3-blueteam/commit/9c20f45a) – Move IAP enablement to bootstrap and unblock deploy pipeline
- [`ddad998d`](https://github.com/ITSX25-Chas/team3-blueteam/commit/ddad998d) – Ersätt team3-allow-traffic med begränsad SSH-regel
- [`6960eb66`](https://github.com/ITSX25-Chas/team3-blueteam/commit/6960eb66) – Dokumentera varför Secure Boot inte kan aktiveras
- [`38c35bfc`](https://github.com/ITSX25-Chas/team3-blueteam/commit/38c35bfc) – fix(jumphost): koppla dedikerat service account istället för default compute SA
- [`a522163d`](https://github.com/ITSX25-Chas/team3-blueteam/commit/a522163d) – Ersätt *:* med specifika regler och lägg till fiktivt företag
- [`b0bb05c3`](https://github.com/ITSX25-Chas/team3-blueteam/commit/b0bb05c3) – Ta bort ssh-keys ur jumphostens metadata
- [`7199de3c`](https://github.com/ITSX25-Chas/team3-blueteam/commit/7199de3c) – fix(iam): ersätt roles/editor med specifika roller för CI/CD-kontot
- [`342b5073`](https://github.com/ITSX25-Chas/team3-blueteam/commit/342b5073) – fix(storage): skydda och logga state-bucketen
- [`75678853`](https://github.com/ITSX25-Chas/team3-blueteam/commit/75678853) – Flytta jumphost till europe-north2-b pga stockout i -c

Ominstallationen av Headscale gjordes direkt på jumphosten och syns därför inte som en commit.
