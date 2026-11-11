# KPI:er – gemensam översikt

Team 3 använder följande tre KPI:er som gemensam baslinje. Varje student analyserar och motiverar dem själv i sin egen undermapp.

1. **Andel lyckade säkra deploymenter:** lyckade körningar där tester, SBOM, signering och rollout passerar, dividerat med alla deploymenter. Mål: minst 95 %.
2. **Critical-fynd och utgångna riskundantag:** antal öppna Critical plus utgångna High/Critical-undantag. Mål: 0.
3. **Testad Blue Team-detektionstäckning:** godkända end-to-end-tester dividerat med fem planerade fall i Blue Team-miljön: oväntad SSH-åtkomst, IAM-förändring, Headscale-avbrott, sårbar image och oväntad deployment. Ett scanner-/Discord-larm verifierades hela vägen. Baslinje: 1 av 5, eller 20 %. Mål: minst 80 % nästa period.

Denna gemensamma Blue Team-mätning ska inte blandas ihop med Andrés separata Red Team-KPI. Den bygger på Acme-labbens sex attacksteg, där nuläget var 0 av 6 observerade larm.

Fullständig definition, datakälla, frekvens, målvärde och åtgärd vid avvikelse finns i respektive students [mapp](README.md).
