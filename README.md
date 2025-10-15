# ROFL Helios

A minimal example of running the [Helios](https://github.com/a16z/helios) Ethereum light client inside a [ROFL (Runtime Off-chain Logic)](https://github.com/oasisprotocol/rofl) container on the Oasis Network.

By running Helios in ROFL:
- Provably running inside Intel TDX with cryptographic attestation
- Ensures privacy of queries and execution
- Delivers trust-minimized access to verified Ethereum state via RPC

## Prerequisites

Before you begin, ensure you have:

1. **Oasis CLI** - Install from [Oasis CLI documentation](https://docs.oasis.io/build/tools/cli/)
2. **Ethereum Execution RPC Provider** - This example uses Infura ([infura.io](https://infura.io)), but you can use any provider (Alchemy, Quicknode, etc.) or your own node (which could also be running inside ROFL)

## Setup Instructions

### 1. Create a ROFL App

Create and register a new ROFL app:

```bash
oasis rofl create --name rofl-helios
```

This will generate an `app_id` and configure your deployment.

### 2. Update rofl.yaml

Edit `rofl.yaml` and update the following fields as needed:

- `deployments.default.admin`: Your CLI wallet name (the admin for this ROFL app)

### 3. Set Up Secrets

Add your Infura API key as a secret using the Oasis CLI (if using Infura):

```bash
echo "your_infura_api_key" | oasis rofl secret set INFURA_API_KEY -
```

### 4. Build and Deploy

You can use the pre-built image `docker.io/ptrusr/rofl-helios:latest` (already configured in `compose.yaml`), or build your own if you made changes to the Dockerfile:

```bash
docker build -t docker.io/your-registry/rofl-helios:latest .
docker push docker.io/your-registry/rofl-helios:latest
```

If you built your own image, update the `image` field in `compose.yaml`.

**Note for Production Deployments**: For production use, the Dockerfile should be made reproducible so that it can be verified off-chain using the `oasis rofl build --verify` command. This allows anyone to verify that the on-chain enclave identity matches the expected build. See the [ROFL build documentation](https://docs.oasis.io/build/tools/cli/rofl#build) for details.

Build the ROFL app bundle:

```bash
oasis rofl build
```

Update the on-chain app configuration (if enclave identities changed):

```bash
oasis rofl update
```

Deploy:

```bash
oasis rofl deploy
```

### 5. Monitor Your Deployment

Check the deployment and get the proxy URL:

```bash
oasis rofl machine show
```

View logs:

```bash
oasis rofl logs
```

## Using the Helios RPC Endpoint

Once deployed, the ROFL proxy will automatically generate a public HTTPS URL for your Helios RPC endpoint. To find your endpoint URL, run:

```bash
oasis rofl machine show
```

Look for the URL in the `Proxy` section (e.g., `https://p1337.m602.test-proxy-b.rofl.app`).

You can then interact with it using standard Ethereum JSON-RPC methods:

```bash
# Example: Get latest block number
curl -X POST https://p1337.YOUR-ROFL-DOMAIN.rofl.app \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

## Configuration Options

### Configuring a Custom Domain

To use your own domain instead of the auto-generated ROFL proxy URL, add the `custom_domain` annotation to your `compose.yaml`:

```yaml
services:
  helios:
    ports:
      - "1337:1337"
    annotations:
      net.oasis.proxy.ports.1337.custom_domain: your-domain.com
```

After updating and deploying, run `oasis rofl machine show` to get the required DNS records (A record and TXT record for ownership verification). Configure these DNS records, and your Helios RPC will be accessible at `https://your-domain.com`.

### Changing Execution RPC Provider

This example uses Infura as the execution layer RPC provider. To use a different provider (Alchemy, Quicknode, your own node, etc.), edit the `Dockerfile` and update the `--execution-rpc` URL in the startup script.

### Changing Ethereum Network

By default, Helios connects to Ethereum mainnet. To change networks, edit the `Dockerfile` and modify the `--network` flag in the startup script:

```dockerfile
# For Sepolia testnet
--network sepolia
```

### Resource Requirements

The default configuration in `rofl.yaml` allocates:
- **Memory**: 512 MB
- **CPUs**: 1
- **Storage**: 512 MB (persistent disk)

Adjust these in the `resources` section of `rofl.yaml` if needed.

## How It Works

1. **Container Build**: The Dockerfile installs Helios and creates a startup script
2. **Startup**: When the container starts, it validates the Infura API key and launches Helios
3. **Helios Operation**: Helios syncs with Ethereum consensus layer and exposes RPC on port 1337
4. **Data Persistence**: Helios data is stored in a persistent volume at `/root/.helios`
5. **ROFL Integration**: The container has access to the ROFL appd socket for attestation and secrets

## Learn More

- [Helios Documentation](https://github.com/a16z/helios)
- [ROFL Documentation](https://docs.oasis.io/build/rofl/)
- [Oasis CLI Documentation](https://docs.oasis.io/build/tools/cli/)
- [Oasis Network](https://oasisprotocol.org/)

## License

This example project is provided as-is for educational purposes.
