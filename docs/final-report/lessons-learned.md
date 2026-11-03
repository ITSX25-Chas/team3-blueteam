# Lessons learned – gemensam översikt

Teamets tre gemensamma huvudlärdomar är:

1. **Infrastructure as Code återställer inte automatiskt tjänstedata.** k3s, Headscale-state, routes och kubeconfig behöver egna återställningsrutiner.
2. **En grön pipeline måste kopplas till rätt miljö.** Efter migrationen nåddes först det gamla klustret via en kvarvarande route trots att adressen var korrekt.
3. **Minsta behörighet måste testas praktiskt.** Nekad direktåtkomst räcker inte om samma data kan nås indirekt genom andra tillåtna resurser.

Den professionella sammanfattningen och varje students egen analys finns i respektive [studentmapp](README.md).
