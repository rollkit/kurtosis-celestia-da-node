# Kurtosis Celestia DA Node

This repository contains the Kurtosis package for running a Celestia DA node.

## Quick Start

```sh
kurtosis run . --enclave celestia-da
```

## Persisting Data

Make a persisted data directory:

```sh
mkdir persisted-data
```

Start the DA node:

```sh
kurtosis run . --enclave celestia-da
```

When you are ready to shut down the node, first stop the node:

```sh
kurtosis service stop celestia-da celestia-light-arabica
```

Then run the persist command:

```sh
kurtosis run persist-data.star --enclave celestia-da
kurtosis files download celestia-da persisted-data
```

Then stop all services:

```sh
kurtosis clean -a
```

When you are ready to restart your node, load your persisted data:

```sh
kurtosis run . --enclave celestia-da
```