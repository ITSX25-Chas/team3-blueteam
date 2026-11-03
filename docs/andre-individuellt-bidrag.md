# Mitt individuella bidrag – André Edvardsson

Jag har främst arbetat med åtkomst, nätverk, pipelines, Kubernetes och säkerhetskontroller. Jag har också lagt mycket tid på felsökning när Headscale, DNS eller deploymenten inte fungerade. I infra-repot syns några av mina ändringar i `0e6b150` för OS Login, `d2a91fb` för VPC Flow Logs och `41c066e` för GitHub-runnerns Headscale-regler. Jag arbetade även med de blockerande pipelinekontrollerna i `f8feff5`, `037a16d` och `6e85d55`.

I app-repot jobbade jag med ingress och deployment, signerade container-images med Cosign och SBOM i CycloneDX-format. Jag var även med och gjorde containern säkrare genom att köra den utan root, ta bort onödiga rättigheter och separera sårbarhetsscannern från appens vanliga deploykonto. En stor del av detta finns i PR #24–#28.

Jag kontrollerade ändringarna med tester, Trivy, Cosign, Kubernetes-status och hälsokontroller. Jag arbetade också med säkerhetsrapporten och försökte vara tydlig med skillnaden mellan sådant som bara fanns i koden och sådant som vi faktiskt hade verifierat i drift.

Efter flytten till Comerits GCP-projekt upptäckte jag att nya primary saknade k3s och att Headscale fortfarande skickade trafik till det gamla klustret. Jag jämförde klustercertifikaten, installerade om k3s, ingress och Sigstore-policy, skapade ny kubeconfig och flyttade subnet-routen till nya jumphosten. Därefter körde jag om app-pipelinen och verifierade en grön deployment, `1/1` pod, aktiv NetworkPolicy och HTTP 200. Återställningsskriptet och guiden finns i commit `dab93b8`, driftstatusen i `c5c2003` och den lyckade appkörningen är `41608640621`.

Mitt vanliga arbetssätt var att först försöka förstå problemet, göra en mindre ändring och sedan testa innan jag gick vidare. När något kunde påverka gruppens åtkomst tog jag backup eller såg till att det fanns en väg tillbaka. Git-historiken, pull requests och pipelinekörningarna visar mer detaljerat vilka delar jag har arbetat med.
