# Individuellt bidrag – Marcus

## Mina bidrag

Mitt individuella bidrag var främst konfiguration och felsökning kring Headscale/Tailscale.

- Jag lade till en Headscale-policy som gav studentgruppen åtkomst till Spectre på `10.0.0.2:443`.
- Jag korrigerade användarreferenserna i policyn.
- Jag lade till DNS-åtkomst till Headscale på `100.64.0.2:53`.
- Jag testade att återaktivera Secure Boot på jumphosten. Det ledde till uppstartsproblem och inställningen ändrades senare tillbaka; jag beskriver detta som ett test/felsökningsförsök, inte som en kvarstående härdning.
- Efter zonflytten felsökte jag anslutningen från min Mac. Headscale-åtgärden utfördes av en gruppkamrat.

## Git-historik

- `dea72e1` – Add Headscale ACL policy for Spectre
- `a4855ae` – Fix Headscale user references
- `13e3f08` – Allow students to use Headscale DNS
- `27c511e` – Re-enable Secure Boot on jumphost (senare återställt)
- `b485044` – Update Terraform provider lock file
