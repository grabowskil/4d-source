---
paths: ["lua/tests/**"]
---
- GLuaTest: Datei gibt `{ groupName, cases = { { name, func } } }` zurück; optional `beforeEach/afterEach(state)`.
- Matcher: `equal`, `aboutEqual`, `beTrue`, `beFalse`, `beNil`, `beValid`, `succeed`, `err`; Negation `toNot`.
- Gespawnte Entities in `afterEach` entfernen. Tests nicht von Map-Geometrie abhängig machen, wo vermeidbar.
- Ausführen nur einzeln: `/gmod-test lua/tests/myphys/<datei>.lua`.
