# Project-local Stata environment

Use Stata 17 or newer and start in the repository root. The package payload is already installed, so normal use does not require internet access.

At the start of every new Stata session:

```stata
cd "/path/to/structured_payment_replication"
do "DoFiles/set_environment.do"
```

Activation is required once per Stata session. `verify.do` is only a diagnostic;
run it after restoring, moving, or changing the bundled environment, not before
every analysis.

```stata
do "environment/stata/verify.do"
```

Only when deliberately refreshing the SSC and GitHub packages:

```stata
do "environment/stata/install.do"
```

Activation redirects `SITE`, `PLUS`, `PERSONAL`, and `OLDPLACE` to this
project, defines the project globals, and selects the bundled graph scheme for
the current session only. It also selects the `mt64` RNG and sets
`sortseed 20260819`; stochastic analyses set their own estimation seeds.

Optional functional check:

```stata
do "environment/stata/smoke_test.do"
```

The installed payload has been tested and is already present under
`environment/stata/ado/plus`; a replicator therefore activates it without
downloading anything. `install.do` refreshes packages installed from SSC and
GitHub. The bundled compatibility copy of `catplot` and the exact
`rforest`/Weka payload must be restored from the replication package if they
are missing. Exact versions and primary-file hashes are recorded in
`packages.tsv`, and `checksums.sha256` covers every bundled ado, help, scheme,
and JAR file. From a terminal at the repository root, verify it with:

```sh
shasum -a 256 -c environment/stata/checksums.sha256
```

Legacy `catplot` 2.0.2 is bundled because the repository uses syntax removed
from the current release. `rforest` 2.0.3 and its exact Weka/RandomForest JARs
are bundled for the supplementary targeting simulation. On recent Java
versions, Weka can print an `InaccessibleObjectException` warning while the
model and prediction still complete; the smoke test explicitly verifies both.
The three GitHub entries are pinned to exact commits. The environment isolates
Stata add-ons only; it does not install Stata itself or the R
interpreter/packages.
