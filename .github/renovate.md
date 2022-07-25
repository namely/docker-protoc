# Renovate Configuration

## What is Renovate?

[Renovate](https://www.mend.io/free-developer-tools/renovate/) is an open-source dependency manager.
The `Renovate` Github app is configured to automatically open PRs in an attempt to update configured dependencies of different kinds.
The configuration is managed in [renovate.json5](./renovate.json5).

## How does Renovate work?

`Renovate` is able to automatically identify dependencies of different kinds in different files and start opening PRs once a basic configuration file is found in the repo and the app is enabled. `Renovate` has a lot of different configuration options beyond the supported dependencies which are well documented [here](https://docs.renovatebot.com/).

However, in cases such as this repo where the dependencies are managed in proprietary files, additional configuration is required.

## How is Renovate used in this repo?

In this repo, we have a variety of dependencies pinned to specific versions, primarly to create reproducible, testable builds.\
Most of these dependencies are installed in the built docker images and are referenced in [Dockerfile](../Dockerfile). However, their versions are set separately in [variables.sh](../variables.sh), which means most PRs opened by `Renovate` will attempt to update this file.
Because it is a proprietary file, we leverage `Renovate`'s support of using Regular Expressions to find & replace dependencies versions.

The different sources used to find dependencies include `npm`, `Go`, and `Github Releases`.

### Dependencies PR grouping

One of great features of `Renovate` is the ability to group dependency updates into mutual PRs according to different criteria to avoid spamming the repo with too many PRs (1 PR per dependency).

In this repo, we have several groups configured according to specific dependencies and/or dependency types:

*   Major/Minor (main) gRPC updates - these dependencies' updates will be opened in one PR. Merging PRs for this dependency group will be followed by releasing new major version in this repo.

*   All other minor/patch dependency updates - Usually as long as the tests pass for this PR we should be able to merge & release a new patch version in this repo.

*   Go gRPC Gateway module - This dependency is singled out since we cannot update it yet due to a breaking change. Once we do update it, we can move this dependency to the same group as the other non gRPC dependencies.

## How to keep maintaining Renovate in this repo?

If and when adding a new dependency, we should pin its version in `variables.sh` (if applicable), configure it
in `Renovate`'s configuration file and ensure it is grouped correctly.
