# AI-redogörelse – Blue Team


Jag använde ChatGPT/Codex som stöd under Blue Team-arbetet, främst för att förstå felmeddelanden, planera felsökning och tolka skillnaden mellan problem med Headscale, DNS, Tailscale och SSH. AI föreslog diagnostiska kommandon och förklarade möjliga betydelser av resultaten. Jag använde också AI som bollplank kring Terraform- och säkerhetskonfiguration.

AI utförde inte den praktiska felsökningen åt mig. Jag körde kommandona själv och granskade resultaten mot projektets konfiguration, Git-historik och teamets säkerhetsrapport. Mina DNS-tester visade exempelvis att vanliga domäner gick att slå upp medan Headscale-domänen inte gjorde det. Det pekade på ett problem med domänuppslag eller Headscale-tjänsten, men bevisade inte ensamt var felet låg. En gruppkamrat arbetade med att åtgärda Headscale.

Vid SSH-problemet tog jag bort den gamla värdnyckeln ur `known_hosts`, varefter anslutningen fungerade. Det löste konflikten med den sparade nyckeln, men att ta bort posten verifierar inte ensamt att den nya servern är rätt server. Fingeravtrycket bör jämföras med en betrodd källa innan den nya nyckeln accepteras.

Jag använde AI som stöd för hypoteser och felsökningssteg, inte som ensam källa eller som bevis på att en åtgärd var säker och korrekt. Jag ansvarar själv för de ändringar jag committade och för att kontrollera deras effekt. AI-förslag kan vara felaktiga eller ofullständiga, så jag granskade dem mot projektet eller kontrollerade resultatet själv.
