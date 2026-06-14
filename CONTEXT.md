# Semantic Tools Testbed

This repository is a Delphi tooling testbed. It exists to demonstrate and stress AST parsing and SourceLens-style analysis against code that is intentionally rich enough to surface findings such as long methods, high complexity, and limited test coverage.

## Language

**Testbed**:
A deliberately useful codebase kept around to exercise the tooling in this repository.
_Avoid_: Demo app, toy project, sandbox

**Analysis Target**:
Code in the repository that exists partly to be inspected by the tools, not only to deliver end-user value.
_Avoid_: Sample file, filler code

**Monopoly Engine**:
The reusable Monopoly game logic that serves as one analysis target within the testbed.
_Avoid_: FireMonkey application, demo UI

**SourceLens Finding**:
A quality signal reported by SourceLens, such as a long method, high complexity, or limited test coverage.
_Avoid_: Compiler error, runtime failure, bug

## Example dialogue

**Dev**: Is Monopoly the product we are building here?

**Domain expert**: No. It is an analysis target inside the testbed.

**Dev**: So the FireMonkey application is not the same thing as the Monopoly engine?

**Domain expert**: Right. The FireMonkey application drives the Monopoly engine.

**Dev**: And SourceLens findings are the signals we want this codebase to surface?

**Domain expert**: Exactly. The point is to keep the code useful both as software and as an analysis target.