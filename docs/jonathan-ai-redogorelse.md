# AI-redogörelse – Jonathan Tsubarah

Jag har använt Claude när jag fastnat. Mest för att förstå felmeddelanden, läsa Terraform och få tips på hur jag kan felsöka. Claude kunde läsa repot men inte pusha, så alla kommandon har jag kört själv. Alla ändringar har gått via PR med två godkännanden.

Jag har inte bara tagit svaren rakt av. Innan något mergades kollade jag terraform plan så jag visste vad som skulle ändras. Efteråt kollade jag i GCP att det blev rätt, t.ex. att det inte fanns några nycklar kvar när SA-nyckeln var borttagen.

AI har haft fel några gånger. När jag skrev till gruppen om Headscale sa AI att några användare var okända, men i Git-historiken såg jag att de kom från vår egen policy. Så nu kollar jag alltid själv innan jag använder det AI säger.

Jag har också sagt nej till förslag. AI ville sätta IAP-rollen på projektnivå. Det hade funkat men vi delar projektet med fem andra lag, så jag körde på begränsad SSH för bara våra resurser istället. Nycklar och lösenord har jag aldrig lagt in i någon prompt.

AI är bra när man ska förstå något nytt eller behöver hjälp att felsöka. Men när det gäller behörigheter eller hur miljön ser ut just nu måste man kolla själv, för AI gissar ibland. Besluten och ändringarna är mina.
