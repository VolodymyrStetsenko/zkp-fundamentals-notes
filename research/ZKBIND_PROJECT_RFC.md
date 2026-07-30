# ZKBind — Cross-Layer Security Analysis for Zero-Knowledge Integrations

**Status:** Project RFC  
**Author:** Volodymyr Stetsenko  
**Date:** 2026-07-30  
**Target repository:** `VolodymyrStetsenko/zkbind`

## 1. Project decision

ZKBind will be an open-source security analyzer for the application boundary around zero-knowledge proofs.

Most existing tools focus on circuit-level properties such as underconstrained signals, overconstrained circuits, witness-generation inconsistencies, or finite-field mistakes. These checks are necessary, but a mathematically valid proof can still be unsafe when an application fails to bind it to the correct user, action, contract, chain, state root, verification key, nonce, or nullifier.

ZKBind will analyze this cross-layer boundary:

```text
Circuit or zkVM guest
        ↓
Public inputs / public values
        ↓
Generated verifier and verification key
        ↓
Solidity integration
        ↓
Protocol state and business action
```

The project will initially support Circom/SnarkJS Groth16 integrations with Solidity and Foundry. Noir and zkVM support will be added after the first stable release.

## 2. Core problem

A proof verifier answers a narrow question: whether a proof is valid for a particular statement and verification key. It does not automatically guarantee that the surrounding application checks the intended context.

Common integration failures include:

- a proof can be replayed on another chain;
- a proof can be replayed against another contract or action;
- a proof is not bound to the intended user or recipient;
- a nullifier is generated but not stored or scoped correctly;
- a Merkle root is accepted without checking that it is current or authorized;
- public outputs are verified but ignored by the application;
- public inputs are supplied in the wrong order;
- the application accepts a mutable or replaceable verifier;
- a verification key or program identifier is not pinned;
- an off-chain value is trusted without a commitment inside the proof;
- a front-runner can copy a valid proof and receive the protected action;
- an upgrade changes verifier semantics without invalidating old proofs.

These are semantic and integration failures. Circuit-only analysis cannot reliably detect them.

## 3. Product vision

ZKBind should become the security equivalent of a proof-integration linter, data-flow analyzer, and test generator.

A developer or auditor should be able to run:

```bash
zkbind scan .
```

and receive:

- a proof-binding graph;
- detected verifier call sites;
- a map of every public input to its application source and use;
- security findings with evidence;
- JSON and SARIF output for CI;
- suggested remediations;
- optional Foundry regression-test templates.

## 4. Initial security rules

The first release will target high-value rules that can be supported with defensible static evidence.

### Domain binding

- `ZKB001`: proof is not bound to `block.chainid` or another explicit chain domain;
- `ZKB002`: proof is not bound to `address(this)` or an application domain identifier;
- `ZKB003`: proof is reusable across different protected actions;
- `ZKB004`: proof is not bound to the intended sender, subject, or recipient.

### Replay and nullifiers

- `ZKB101`: no replay protection is applied after successful verification;
- `ZKB102`: nullifier is checked but never persisted;
- `ZKB103`: nullifier scope does not include the relevant action or domain;
- `ZKB104`: state is updated before proof verification or without atomic replay protection.

### State commitments

- `ZKB201`: Merkle root or state commitment is accepted without an allowlist, registry, or freshness check;
- `ZKB202`: verified public state is not the state used by the protected action;
- `ZKB203`: an externally supplied root can be selected by the prover without authorization.

### Verifier and key integrity

- `ZKB301`: verifier address is mutable without a protected governance boundary;
- `ZKB302`: verification key, circuit identifier, or program image is not pinned;
- `ZKB303`: proxy upgrade can silently change proof semantics;
- `ZKB304`: public-input count or ordering differs between circuit metadata and Solidity integration.

### Consumption of proven values

- `ZKB401`: a verified public value is ignored;
- `ZKB402`: an application-critical value is used but not proven;
- `ZKB403`: public inputs are truncated, cast, packed, or decoded inconsistently;
- `ZKB404`: the protected action uses uncommitted off-chain data.

## 5. MVP architecture

```text
zkbind/
├── crates/
│   ├── zkbind-cli/          # CLI entry point
│   ├── zkbind-core/         # shared models and rule engine
│   ├── zkbind-circom/       # Circom/SnarkJS metadata adapter
│   ├── zkbind-solidity/     # Solidity AST and data-flow adapter
│   ├── zkbind-graph/        # proof-binding graph construction
│   └── zkbind-report/       # terminal, JSON, SARIF, Markdown
├── rules/                   # documented rule specifications
├── fixtures/
│   ├── vulnerable/          # intentionally vulnerable integrations
│   └── secure/              # corrected counterparts
├── foundry/                 # generated and handwritten PoC tests
├── benchmarks/              # reproducible evaluation corpus
├── docs/
│   ├── architecture.md
│   ├── threat-model.md
│   ├── rule-authoring.md
│   └── methodology.md
└── .github/workflows/       # build, tests, lint, benchmark smoke test
```

## 6. Technical approach

### Circom adapter

The adapter will collect:

- declared public inputs and outputs;
- signal names and indices from `.sym` artifacts;
- public-signal count and ordering;
- R1CS and verification-key metadata hashes;
- generated verifier ABI information.

The first version will not attempt to replace circuit soundness tools. It will consume their output when available and focus on the application boundary.

### Solidity adapter

The Solidity layer will use compiler AST data and established analysis libraries where their licenses permit reuse. It will identify:

- verifier instances and verifier call sites;
- construction of public-input arrays;
- sources such as `msg.sender`, `block.chainid`, `address(this)`, storage roots, nonces, and calldata;
- uses of verified values after verification;
- replay-protection state changes;
- upgradeability and verifier mutability;
- control-flow ordering around verification and state mutation.

### Proof-binding graph

The graph will represent:

```text
application value → encoding → public-signal slot → verifier call → protected action
```

A finding must reference the relevant graph nodes and source locations. The tool should avoid presenting unsupported guesses as confirmed vulnerabilities.

### Foundry test generation

For selected findings, ZKBind will create test skeletons for:

- same-proof replay;
- cross-user proof theft;
- cross-action replay;
- stale or attacker-selected root use;
- verifier replacement;
- public-input permutation.

Generated tests will be clearly marked as templates requiring project-specific validation.

## 7. Technology choices

- **Rust** for the core CLI, graph model, parsers, performance, and distributable binaries;
- **Solidity compiler AST and Slither-compatible data** for contract analysis;
- **Foundry** for reproducible integration and regression tests;
- **Python only for research scripts and dataset preparation**, not as the production core;
- **SARIF** for GitHub code-scanning integration;
- **Graphviz/Mermaid export** for visual proof-binding maps.

## 8. Validation strategy

ZKBind will be validated against three datasets:

1. purpose-built vulnerable/secure integration pairs;
2. public audit findings and disclosures that permit reproducible use;
3. real open-source ZK applications evaluated at pinned commits.

Every benchmark case must include:

- source and license metadata;
- vulnerability description;
- expected rule result;
- vulnerable and fixed behavior where available;
- a deterministic test or analysis assertion.

Metrics will include precision, recall on the supported rule set, runtime, installation success, and analysis success on complete repositories.

## 9. Relationship to existing tools

ZKBind will integrate with, not imitate, circuit-focused tools such as Circomspect, CIVER, Picus, Ecne, ConsCS, ZKAP, NAVe, and zkFuzz.

Potential future workflow:

```text
Circuit analyzers + ZKBind cross-layer analysis + Foundry tests
                         ↓
               unified security report
```

Open-source code will only be reused when its license allows it, with attribution and preservation of license notices. Concepts described in papers may be independently implemented, but code will not be copied blindly.

## 10. Roadmap

### Milestone 0 — Research and specification

- publish threat model;
- define the proof-binding graph schema;
- document the first 12–16 rules;
- build ten vulnerable/secure fixture pairs;
- define report confidence levels.

### Milestone 1 — Circom + Solidity MVP

- detect SnarkJS Groth16 verifier integrations;
- extract public-signal ordering;
- map public-signal construction in Solidity;
- implement replay, nullifier, domain, root, and verifier-integrity rules;
- export terminal, JSON, Markdown, and SARIF reports.

### Milestone 2 — Foundry validation

- generate test templates for supported findings;
- ship a reusable test harness;
- add CI benchmark gates;
- publish the first independent integration-security report.

### Milestone 3 — Noir support

- parse Noir ABI and ACIR-facing metadata;
- support UltraHonk verifier integrations;
- add Noir-specific fixtures and benchmark cases.

### Milestone 4 — zkVM support

- analyze program-image or verification-key binding;
- map journals/public values to Solidity consumption;
- add SP1, RISC Zero, or OpenVM adapters based on ecosystem demand and stable APIs.

## 11. Non-goals for the first release

ZKBind v0.1 will not claim to:

- prove circuit soundness;
- verify the cryptographic security of a proving system;
- replace a manual security review;
- support every ZK DSL or verifier;
- automatically exploit live deployments;
- label every missing context value as a vulnerability without application evidence.

## 12. Success criteria

The first public release is successful when it can:

- install with one documented command;
- analyze at least five complete Circom/Solidity repositories;
- identify at least ten distinct cross-layer vulnerability patterns;
- produce low-noise findings with source-level evidence;
- generate a proof-binding graph and SARIF report;
- run in GitHub Actions;
- demonstrate at least one accepted upstream issue, fix, or integration improvement.

## 13. Research basis

The project direction is based on the current gap identified by ZK security practitioners and recent research: existing tools concentrate heavily on Circom constraint correctness, lose substantial effectiveness on full projects, and leave semantic and integration vulnerabilities weakly supported.

Primary starting references:

- ZKP Security Tools and Verification: Coverage, Effectiveness, Adoption, and Challenges (2026)
- SoK: What Don’t We Know? Understanding Security Vulnerabilities in SNARKs
- Practical Security Analysis of Zero-Knowledge Proof Circuits
- Circom and SnarkJS documentation
- Solidity compiler AST documentation
- Foundry documentation

## 14. Immediate next work

The next commit in the standalone repository should contain:

1. the threat model;
2. the proof-binding graph JSON schema;
3. four minimal vulnerable/secure fixtures;
4. a Rust workspace and CLI skeleton;
5. CI for formatting, linting, and unit tests.
