# Individuellt bidrag – Carl Persson

## Mina bidrag

Mitt arbete i Blue Team-projektet har främst handlat om GCP-infrastruktur, nätverksåtkomst, Headscale/Tailscale och felsökning.

- Jag aktiverade Shielded VM och arbetade med att aktivera primary-instansen och konfigurera säker nätverksåtkomst.
- Jag gjorde ändringar i Headscale-ACL:er för studenter, administratörer, utvecklare och anställda.
- Jag lade till routing till Spectre och stöd för split DNS.
- Jag felsökte kommunikation mellan jumphost, primary och klienter, bland annat med SSH, Tailscale, DNS-kontroller och `curl`.
- I samband med att jumphosten behövde flyttas till en annan GCP-zon undersökte jag anslutningsproblem med Headscale och SSH.
- Jag undersökte skillnaden mellan publik och intern åtkomst till Spectre för att avgränsa DNS- och routningsproblem.

## Verifiering och lärdomar

Jag använde bland annat `tailscale status`, `ssh`, `curl` och kontroller av nätverkskonfiguration för att felsöka och verifiera anslutningar. Arbetet gav mig bättre förståelse för hur GCP, identitetshantering, DNS, routing och VPN hänger ihop, och varför ändringar i infrastrukturen behöver följas upp med praktiska tester.

## Git-historik

Följande commits i infra-repot är registrerade med författaren `carlp040`:

- [`92af4437`](https://github.com/ITSX25-Chas/team3-blueteam/commit/92af4437) – Modify ACLs for students, admins, developers, and employees
- [`88d73d48`](https://github.com/ITSX25-Chas/team3-blueteam/commit/88d73d48) – Add Spectre routing and split DNS support
- [`38b7278a`](https://github.com/ITSX25-Chas/team3-blueteam/commit/38b7278a) – Enable primary instance and secure network access
- [`6e00e17a`](https://github.com/ITSX25-Chas/team3-blueteam/commit/6e00e17a) – Enable Shielded VM

Felsökningen ovan beskriver även praktiskt arbete som inte nödvändigtvis motsvarar en separat commit.
