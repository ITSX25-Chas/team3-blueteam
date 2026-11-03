# Individuellt bidrag – Erik Alduaifi

## Mina bidrag

Mitt arbete i Blue Team-projektet har främst handlat om identitetsbaserad SSH-åtkomst med GCP OS Login och om hur Terraform-variabler och `terraform.tfvars` hanteras i repot.

- Jag aktiverade OS Login på jumphosten genom att lägga till `enable-oslogin = "TRUE"` i instansens metadata. Det innebär att SSH-åtkomst knyts till Google-identitet och IAM i stället för enbart till statiska nycklar i metadata.
- Jag lade till resursen `google_compute_instance_iam_member.jumphost_os_login` som tilldelar rollen `roles/compute.osAdminLogin` på instansnivå till de användare som anges i en variabel. Behörigheten begränsas därmed till jumphosten i stället för hela projektet.
- Jag skapade variabeln `os_admin_users` (med tom lista som standard) så att administratörsåtkomsten styrs via konfiguration och kan granskas i kod.
- Jag rättade formateringen så att ändringen klarade `terraform fmt`.
- Jag arbetade med hanteringen av `terraform.tfvars`: först slutade filen spåras och `.example`-filer lades till, så att verkliga värden inte behöver ligga i Git. Eftersom CI-flödet behövde filen för `terraform plan` återinfördes den, medan `.gitignore` uppdaterades för framtida lokala filer. Det visar en avvägning mellan att hålla konfiguration utanför Git och att pipelinen ska fungera; variablerna tillhandahölls senare i deploy-workflowet (PR #58).
- Jag mergade PR #62 (blockerande CI-kontroller och begränsad WIF) och PR #65 (borttagen åtkomst för tidigare instruktör).

## Verifiering och lärdomar

Ändringarna kontrollerades med `terraform fmt -check` och `terraform validate` i PR-kontrollerna innan de mergades, och deployflödet körde sedan `terraform plan` före apply. OS Login byggdes sedan vidare av teamet, bland annat med dokumentation i `docs/os-login.md` och OS Login på primary (PR #54).

Arbetet gav mig bättre förståelse för skillnaden mellan nätverksåtkomst (Headscale/Tailscale) och SSH-identitet (OS Login), hur IAM-roller kan avgränsas till en enskild resurs, och varför konfigurationsfiler med verkliga värden behöver hanteras medvetet i förhållande till CI.

## Git-historik

Följande commits i infra-repot är registrerade med författaren `erikalduaifi-jpg`:

- [`4d1344e`](https://github.com/ITSX25-Chas/team3-blueteam/commit/4d1344e) – Lägg till OS Login IAM-resurs och aktivera enable-oslogin på jumphost
- [`fe86490`](https://github.com/ITSX25-Chas/team3-blueteam/commit/fe86490) – Fix terraform fmt
- [`cc0aa6b`](https://github.com/ITSX25-Chas/team3-blueteam/commit/cc0aa6b) – Add os_admin_users variable and set value in tfvars
- [`d65ce87`](https://github.com/ITSX25-Chas/team3-blueteam/commit/d65ce87) – Sluta spåra terraform.tfvars, lägg till exempel-filer
- [`1424bda`](https://github.com/ITSX25-Chas/team3-blueteam/commit/1424bda) – Behåll terraform.tfvars i git för CI, uppdatera .gitignore för framtiden
- [`0db5e0e`](https://github.com/ITSX25-Chas/team3-blueteam/commit/0db5e0e) – Merge av PR #62
- [`4f735b5`](https://github.com/ITSX25-Chas/team3-blueteam/commit/4f735b5) – Merge av PR #65
