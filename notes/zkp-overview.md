# Notes: What is a Zero‑Knowledge Proof?

A **zero‑knowledge proof (ZKP)** is a cryptographic protocol that allows one party (the *prover*) to convince another party (the *verifier*) that a statement is true without revealing any information beyond the validity of the statement itself.  Zero‑knowledge protocols are foundational to privacy‑preserving systems in blockchain and beyond.

## Key properties

- **Completeness** – If the statement is true, an honest prover can convince the verifier.
- **Soundness** – If the statement is false, no cheating prover can convince the verifier with more than negligible probability.
- **Zero‑knowledge** – The proof reveals nothing other than the truth of the statement.

## Ali Baba cave metaphor

The classic analogy describes a circular cave with two entrances and a magic door blocking one path. A prover wants to convince the verifier they know the secret word to open the door without revealing the word. By randomly choosing entrances and demonstrating the ability to exit through requested paths, the prover convinces the verifier with high probability without disclosing the secret【895355980139095†L123-L126】.

## Interactive vs non‑interactive proofs

In *interactive* proofs, the prover and verifier communicate back and forth. In *non‑interactive* proofs (e.g. SNARKs), interaction is removed by using cryptographic primitives (Fiat–Shamir heuristic) to produce a single succinct proof【895355980139095†L119-L126】.
