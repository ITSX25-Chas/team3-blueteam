# Individuell AI-redogörelse – Erik Alduaifi

Under Blue Team-projektet använde jag Claude och Claude Code som stöd för att förstå tekniska begrepp, tolka felmeddelanden och ta fram Terraform-ändringar. AI användes som ett hjälpmedel, inte som ensam beslutsfattare.

Mitt huvudsakliga användningsområde var OS Login på jumphosten. AI hjälpte mig att förstå hur OS Login fungerar i GCP, skillnaden mellan rollerna `osLogin` och `osAdminLogin`, och hur behörigheten kan tilldelas på instansnivå med `google_compute_instance_iam_member` i stället för på hela projektet. Jag använde även AI för att förstå skillnaden mellan Headscale/Tailscale, som ger nätverksåtkomst, och OS Login, som styr SSH-identitet och behörighet på VM:en.

Jag använde också AI för att tolka fel från `terraform fmt`, `terraform plan` och CI, samt som bollplank kring hur `terraform.tfvars` bör hanteras. Frågan var om filen skulle ligga i Git eller inte. Att sluta spåra filen minskar risken att verkliga värden hamnar i repot, men CI-flödet behövde den för att kunna köra `terraform plan`. Filen återinfördes därför, och variablerna hanterades senare i deploy-workflowet. Det var ett exempel på att ett generellt råd från AI behövde anpassas efter hur vår pipeline faktiskt fungerade.

Jag följde inte AI:s förslag utan att kontrollera dem. Ändringarna granskades som Git-diff, formaterades med `terraform fmt` och kontrollerades med `terraform plan` i CI innan de mergades. Vid IAM-ändringar var jag särskilt noga med att kontrollera vilken roll som tilldelades och till vilka konton, eftersom ett felaktigt förslag kan ge för bred åtkomst eller låsa ute användare.

Min erfarenhet är att AI var användbart för att snabbt komma in i nya områden som GCP IAM och OS Login och för att få struktur på felsökningen. Samtidigt kan ett välformulerat svar vara fel eller inte passa den egna miljön, så slutliga beslut baserades på Terraform-kontroller, CI-resultat och teamets granskning. Jag ansvarar själv för de ändringar jag committade under projektet.
