# Individuell AI-redogörelse – Carl Persson

Under Blue Team-projektet använde jag främst ChatGPT som stöd för felsökning, problemlösning och för att förstå olika tekniska delar av miljön. AI hjälpte mig att tolka felmeddelanden, få förslag på kommandon och förstå hur olika tjänster hängde ihop.

Jag använde bland annat AI vid felsökning av Headscale/Tailscale, SSH, DNS och nätverkskommunikation i GCP. Ett konkret exempel var när jumphosten behövde flyttas till en annan zon på grund av resursbrist. Efter flytten uppstod problem med anslutningen till Headscale och SSH-varningar om ändrade host keys. AI hjälpte mig att förstå möjliga orsaker och vilka kontroller som kunde användas för att undersöka problemen.

Jag använde även AI för att förstå subnet routing, OS Login och hur åtkomsten till Spectre fungerade. Vid felsökningen använde jag bland annat `tailscale status`, `ssh` och `curl` för att kontrollera anslutningar och jämföra resultaten med AI:s förklaringar.

AI användes också som bollplank för nätverks- och säkerhetskonfiguration, bland annat vid arbete med Headscale-ACL:er, routing och split DNS. Det var användbart för att förstå hur ändringar kunde påverka kommunikationen mellan olika delar av miljön.

Jag följde inte AI:s förslag utan att kontrollera dem. Kommandon kördes av mig själv och resultaten jämfördes med den faktiska miljön. AI kunde föreslå möjliga orsaker till ett problem, men det innebar inte automatiskt att förklaringen var korrekt. Särskilt vid nätverksproblem kunde samma symptom bero på flera olika saker.

Min erfarenhet är att AI framför allt var användbart för att snabbare förstå nya begrepp och få en tydligare struktur i felsökningen. Samtidigt lärde jag mig vikten av att inte lita blint på svaren, utan att själv undersöka, testa och verifiera innan jag gjorde ändringar. Jag ansvarade själv för de tekniska beslut och ändringar jag genomförde under projektet.
