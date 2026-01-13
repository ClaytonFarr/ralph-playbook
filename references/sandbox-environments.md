<!-- cSpell:disable -->

# Sandbox Environments for AI Agent Workflows

_Security model:_ The sandbox (Docker/E2B) provides the security boundary. Inside the sandbox, Claude runs with full permissions because the container itself is isolated.

_Security philosophy:_

> "It's not if it gets popped, it's when it gets popped. And what is the blast radius?"

Run on dedicated VMs or local Docker sandboxes. Restrict network connectivity, provide only necessary credentials, and ensure no access to private data beyond what the task requires.

---

## Options

### Sprites (Fly.io)

- Persistent Linux environments that survive between executions indefinitely
- Firecracker VM isolation with up to 8 vCPUs and 8GB RAM
- Fast checkpoint/restore (~300ms create, <1s restore)
- Auto-sleep after 30 seconds of inactivity
- Unique HTTPS URL per Sprite for webhooks, APIs, public access
- Layer 3 network policies for egress control (whitelist domains or use default LLM-friendly list)
- CLI, REST API, JavaScript SDK, Go SDK (Python and Elixir coming soon)
- Pre-installed tools: Claude Code, Codex CLI, Gemini CLI, Python 3.13, Node.js 22.20
- $30 free credits to start (~500 Sprites worth)

_Philosophy:_ Fly.io argues that "ephemeral sandboxes are obsolete" and that AI agents need persistent computers, not disposable containers. Sprites treat sandboxes as "actual computers" where data, packages, and services persist across executions on ext4 NVMe storage—no need to rebuild environments repeatedly. As they put it: "Claude doesn't want a stateless container."

_Unique Features:_

- _Stateful persistence_: Files, packages, databases survive between runs indefinitely
- _Transactional snapshots_: Copy-on-write checkpoints capture entire disk state; stores last 5 checkpoints
- _Idle cost optimization_: Auto-sleep when inactive (30s timeout), resume on request (<1s wake)
- _Cold start_: Creation in 1-2 seconds, restore under 1 second
- _Claude integration_: Pre-installed skills teach Claude how to use Sprites (port forwarding, etc.)
- _Storage billing_: Pay only for blocks written, not allocated space; TRIM-friendly
- _No time limits_: Unlike ephemeral sandboxes (typically 15-minute limits), Sprites support long-running workloads

_Pricing:_

| Resource | Cost             | Minimum             |
| -------- | ---------------- | ------------------- |
| CPU      | $0.07/CPU-hour   | 6.25% utilization/s |
| Memory   | $0.04375/GB-hour | 250MB per second    |
| Storage  | $0.00068/GB-hour | Actual blocks only  |

- Free trial: $30 in credits (~500 Sprites)
- Plan: $20/month includes monthly credits; overages at published rates
- Example costs: 4-hour coding session ~$0.46, web app with 30 active hours ~$4/month

_Specs:_

| Spec         | Value                                                          |
| ------------ | -------------------------------------------------------------- |
| Isolation    | Firecracker microVM (hardware-isolated)                        |
| Resources    | Up to 8 vCPUs, 8GB RAM per execution (fixed, not configurable) |
| Storage      | 100GB initial ext4 partition on NVMe, auto-scaling capacity    |
| Cold Start   | <1 second restore, 1-2 seconds creation                        |
| Timeout      | None (persistent); auto-sleeps after 30 seconds inactivity     |
| Active Limit | 10 simultaneous active Sprites on base plan; unlimited cold    |
| Network      | Port 8080 proxied for HTTP services; isolated networks         |

_Limitations:_

- Resource caps (8 vCPU, 8GB RAM, 100GB storage) not configurable yet
- 30-second idle timeout not configurable
- Region selection not available (auto-assigned based on geographic location)
- Maximum 10 active sprites on base plan (unlimited cold/inactive sprites allowed)
- Best for personal/organizational tools; not designed for million-user scale apps

_Links:_

- Official: https://sprites.dev/
- Documentation: https://docs.sprites.dev/
- Fly.io Blog: https://fly.io/blog/code-and-let-live/
- JavaScript SDK: https://github.com/superfly/sprites-js
- Go SDK: https://github.com/superfly/sprites-go
- Elixir SDK: https://github.com/superfly/sprites-ex
- Community: https://community.fly.io/c/sprites/

---

### E2B

- Purpose-built for AI agents and LLM workflows
- Pre-built template `anthropic-claude-code` ships with Claude Code CLI ready
- Single-line SDK calls in Python or JavaScript (v1.5.1+)
- Full filesystem + git for progress.txt, prd.json, and repo operations
- 24-hour session limits on Pro plan (1 hour on Hobby)
- Native access to 200+ MCP tools via Docker partnership (GitHub, Notion, Stripe, etc.)
- Configurable compute: 1-8 vCPU, 512MB-8GB RAM

_Philosophy:_ E2B believes AI agents need transient, immutable workloads with hardware-level kernel isolation. Each sandbox runs in its own Firecracker microVM, providing the same isolation as AWS Lambda. The focus is on developer experience—one SDK call to create a sandbox.

_Unique Features:_

- _Fastest cold start_: ~150-200ms via Firecracker microVMs
- _Pre-built Claude template_: Zero-setup Claude Code integration
- _Docker MCP Partnership_: Native access to 200+ MCP tools from Docker's catalog
- _Pause/Resume (Beta)_: Save full VM state including memory (~4s per 1GB to pause, ~1s to resume, state persists up to 30 days)
- _Network controls_: `allowInternetAccess` toggle, `network.allowOut`/`network.denyOut` for granular CIDR/domain filtering
- _Domain filtering_: Works for HTTP (port 80) and TLS (port 443) via SNI inspection

_Pricing:_

| Plan       | Monthly Fee | Session Limit | Notes                       |
| ---------- | ----------- | ------------- | --------------------------- |
| Hobby      | $0          | 1 hour        | + $100 one-time credit      |
| Pro        | $150        | 24 hours      | + usage costs               |
| Enterprise | Custom      | Custom        | SSO, SLA, dedicated support |

_Usage Rates (per second):_

| Resource | Rate           |
| -------- | -------------- |
| 2 vCPU   | $0.000028/s    |
| Memory   | $0.0000045/GiB |

_Specs:_

| Spec          | Value                                  |
| ------------- | -------------------------------------- |
| Isolation     | Firecracker microVM                    |
| Cold Start    | ~150-200ms                             |
| Timeout       | 1 hour (Hobby), 24 hours (Pro)         |
| Compute       | 1-8 vCPU, 512MB-8GB RAM (configurable) |
| Filesystem    | Full Linux with git support            |
| Pre-installed | Node.js, curl, ripgrep, Claude Code    |

_Limitations:_

- No native sandbox clone/fork functionality
- No bulk file reading API
- Domain filtering limited to HTTP/HTTPS ports (UDP/QUIC not supported)
- Self-hosted version lacks built-in network policies
- Occasional 502 timeout errors on long operations
- Sandbox "not found" errors near timeout boundaries

_Links:_

- Official: https://e2b.dev/
- Documentation: https://e2b.dev/docs
- Pricing: https://e2b.dev/pricing
- Python Guide: https://e2b.dev/blog/python-guide-run-claude-code-in-an-e2b-sandbox
- JavaScript Guide: https://e2b.dev/blog/javascript-guide-run-claude-code-in-an-e2b-sandbox
- Claude Code Template: https://e2b.dev/docs/code-interpreter/claude-code
- MCP Server: https://github.com/e2b-dev/mcp-server
- GitHub: https://github.com/e2b-dev/E2B

---

### exe.dev

Persistent VM platform created by David Crawshaw (former Tailscale CTO) and Josh Bleecher Snyder (former Braintree Director of Engineering). Launched December 2025 in developer preview.

_Key Features:_

- ~2 second VM creation
- Persistent disk storage (not ephemeral)
- SSH-native interface (`ssh exe.dev`)
- Automatic TLS and custom domains
- Built-in authentication ("Login with exe")
- Shelley AI agent included (web-based, mobile-friendly)
- No SDK required - pure SSH-based interaction

_Philosophy:_ exe.dev takes an explicitly anti-serverless, persistent disk approach. Their core thesis: "Persistent, private, fast-starting VMs with no marginal cost per-VM." Unlike ephemeral sandboxes, exe.dev treats VMs as actual computers with persistent state, similar to Fly.io's Sprites but with an SSH-first design philosophy.

_Unique Features:_

- _SSH-native_: No SDK needed, just `ssh exe.dev` to access
- _Persistent disk_: Data survives indefinitely, not ephemeral
- _Shelley AI agent_: Built-in web-based AI assistant that reads CLAUDE.md and AGENTS.md
- _Mobile-friendly_: Shelley works on mobile devices
- _Custom domains_: Automatic TLS with custom domain support
- _Zero marginal cost_: No per-VM overhead once running

_Pricing:_

| Plan       | Monthly | VMs | CPU        | RAM        | Disk  | Bandwidth |
| ---------- | ------- | --- | ---------- | ---------- | ----- | --------- |
| Individual | $20     | 25  | 2 (shared) | 8GB shared | 25 GB | 100 GB    |

_Specs:_

| Spec       | Value                                  |
| ---------- | -------------------------------------- |
| Isolation  | Full VMs (Cloud Hypervisor, KVM-based) |
| Cold Start | ~2 seconds                             |
| Timeout    | None (persistent)                      |
| vCPU       | 2 shared                               |
| RAM        | 8 GB shared                            |
| Disk       | 25 GB persistent                       |
| Interface  | SSH (`ssh exe.dev`)                    |
| AI Agent   | Shelley (built-in)                     |

_Limitations:_

- Developer preview (launched December 2025) - ecosystem still maturing
- Shared resources on Individual plan (2 vCPU, 8GB RAM shared across VMs)
- Smaller VM allocation compared to E2B/Sprites (25 VMs vs unlimited)
- Less documentation and community resources than established platforms
- No official SDK - relies on SSH interface

_Links:_

- Official: https://exe.dev/
- Blog: https://blog.exe.dev/
- Documentation: https://exe.dev/docs
- Shelley AI Agent: https://github.com/boldsoftware/shelley

---

### Modal

Modal Sandboxes are the Modal primitive for safely running untrusted code from LLMs, users, or third-party sources. Built on Modal's serverless container fabric with gVisor isolation.

_Key Features:_

- Pure Python SDK for defining sandboxes with one line of code (also JS/Go SDKs)
- Execute arbitrary commands with `sandbox.exec()` and stream output
- Autoscale from zero to 10,000+ concurrent sandboxes
- Dynamic image definition at runtime from model output
- Built-in tunneling for HTTP/WebSocket connections to sandbox servers
- Granular egress policies via CIDR allowlists
- Named sandboxes for persistent reference and pooling
- Production-proven: Lovable and Quora run millions of code executions daily

_Philosophy:_ Modal treats sandboxes as secure, ephemeral compute units that inherit its serverless fabric. The focus is on Python-first AI/ML workloads with aggressive cost optimization through scale-to-zero, trading cold start latency for resource efficiency.

_Unique Features:_

- _Sandbox Connect Tokens_: Authenticated HTTP/WebSocket access with unspoofable `X-Verified-User-Data` headers for access control
- _Memory Snapshots_: Capture container memory state to reduce cold starts to <3s even with large dependencies like PyTorch
- _Idle Timeout_: Auto-terminate sandboxes after configurable inactivity period
- _Filesystem Snapshots_: Preserve state across sandbox instances for 24+ hour workflows
- _No pre-provisioning_: Sandboxes created on-demand without capacity planning

_Pricing (as of late 2025, after 65% price reduction):_

| Plan       | Monthly Fee | Credits Included | Seats | Container Limits                |
| ---------- | ----------- | ---------------- | ----- | ------------------------------- |
| Starter    | $0          | $30/month        | 3     | 100 containers, 10 GPU          |
| Team       | $250        | $100/month       | ∞     | 1,000 containers, 50 GPU        |
| Enterprise | Custom      | Volume discounts | ∞     | Custom limits, HIPAA, SSO, etc. |

_Compute Rates (per second):_

| Resource              | Rate             | Notes                        |
| --------------------- | ---------------- | ---------------------------- |
| Sandbox/Notebook CPU  | $0.00003942/core | Per physical core (= 2 vCPU) |
| Standard Function CPU | $0.0000131/core  | Per physical core            |
| Memory                | $0.00000222/GiB  | Pay for actual usage         |
| GPU (A10G)            | $0.000306/s      | ~$1.10/hr                    |
| GPU (A100 40GB)       | $0.000583/s      | ~$2.10/hr                    |
| GPU (H100)            | $0.001097/s      | ~$3.95/hr                    |

_Special Credits:_ Startups up to $25k, Academics up to $10k free compute

_Specs:_

| Spec               | Value                                         |
| ------------------ | --------------------------------------------- |
| Isolation          | gVisor (Google's container runtime)           |
| Cold Start         | ~1s container boot, 2-5s typical with imports |
| With Snapshots     | <3s even with large dependencies              |
| Default Timeout    | 5 minutes                                     |
| Max Timeout        | 24 hours (use snapshots for longer)           |
| Idle Timeout       | Configurable auto-termination                 |
| Filesystem         | Ephemeral (use Volumes for persistence)       |
| Network Default    | Secure-by-default, no incoming connections    |
| Egress Control     | `block_network=True` or `cidr_allowlist`      |
| Concurrent Scaling | 10,000+ sandboxes                             |

_Volumes (Persistent Storage):_

- High-performance distributed filesystem (up to 2.5 GB/s bandwidth)
- Volumes v2 (beta): No file count limit, 1 TiB max file size, HIPAA-compliant deletion
- Explicit `commit()` required to persist changes
- Last-write-wins for concurrent modifications to same file
- Best for model weights, checkpoints, and datasets

_Limitations:_

- Cold start penalties when containers spin down (2-5s typical)
- No on-premises deployment option
- Sandboxes cannot access other Modal workspace resources by default
- Single-language focus (Python-optimized, less suited for multi-language untrusted code)
- Volumes require explicit reload to see changes from other containers
- Less suited for persistent, long-lived environments vs microVM solutions

_Modal vs E2B for AI Agents:_

| Aspect           | Modal                           | E2B                            |
| ---------------- | ------------------------------- | ------------------------------ |
| Isolation        | gVisor containers               | Firecracker microVMs           |
| Cold Start       | 2-5s typical, <3s with snapshot | ~150ms                         |
| Session Duration | Up to 24h (stateless)           | Up to 24h (Pro), persistent    |
| Self-Hosting     | No (managed only)               | Experimental                   |
| Multi-Language   | Python-focused                  | Python, JS, Ruby, C++          |
| Network Control  | Granular egress policies        | Allow/deny lists               |
| Best For         | Python ML/AI, batch workloads   | Multi-language agent sandboxes |

_Links:_

- Sandbox Product: https://modal.com/use-cases/sandboxes
- Sandbox Docs: https://modal.com/docs/guide/sandboxes
- Sandbox Networking: https://modal.com/docs/guide/sandbox-networking
- API Reference: https://modal.com/docs/reference/modal.Sandbox
- Safe Code Execution Example: https://modal.com/docs/examples/safe_code_execution
- Coding Agent Example: https://modal.com/docs/examples/agent
- Pricing: https://modal.com/pricing
- Cold Start Guide: https://modal.com/docs/guide/cold-start
- Volumes: https://modal.com/docs/guide/volumes
- Security: https://modal.com/docs/guide/security

---

### Cloudflare Sandboxes

- Open Beta (announced June 2025), still experimental
- Edge-native (330+ global locations)
- Pay for active CPU only (not provisioned resources)
- Best if already in Cloudflare ecosystem
- R2 bucket mounting via FUSE enables data persistence (added November 2025)
- Git operations support (added August 2025)
- Rich output: charts, tables, HTML, JSON, images

_Philosophy:_ Cloudflare takes a security-first approach using a "bindings" model where code has zero network access by default and can only access external APIs through explicitly defined bindings. This eliminates entire classes of security vulnerabilities by making capabilities explicitly opt-in.

_Unique Features:_

- _Edge-native execution_: Run sandboxes in 330+ global locations
- _Bindings model_: Zero network access by default; explicit opt-in for external APIs
- _R2 FUSE mounting_: S3-compatible storage mounting for persistence (R2, S3, GCS, Backblaze B2, MinIO)
- _Preview URLs_: Public URLs for exposing services from sandboxes
- _`keepAlive: true`_: Option for indefinite runtime

_Pricing (as of November 2025):_

| Resource       | Cost             | Included (Workers Paid) |
| -------------- | ---------------- | ----------------------- |
| Base Plan      | $5/month         | -                       |
| CPU            | $0.000020/vCPU-s | 375 vCPU-minutes        |
| Memory         | $0.0000025/GiB-s | 25 GiB-hours            |
| Disk           | $0.00000007/GB-s | 200 GB-hours            |
| Network Egress | $0.025-$0.05/GB  | Varies by region        |

_Instance Types (added October 2025):_

| Type       | vCPU | Memory  | Disk  |
| ---------- | ---- | ------- | ----- |
| lite       | 1/16 | 256 MiB | 2 GB  |
| basic      | 1/4  | 1 GiB   | 4 GB  |
| standard-1 | 1    | 3 GiB   | 5 GB  |
| standard-2 | 2    | 6 GiB   | 10 GB |
| standard-4 | 4    | 12 GiB  | 20 GB |

_Specs:_

| Spec           | Value                                   |
| -------------- | --------------------------------------- |
| Isolation      | Container                               |
| Cold Start     | 1-5 seconds                             |
| Edge Locations | 330+ global                             |
| Storage        | Ephemeral; persistent via R2 FUSE mount |
| Network        | Bindings model (zero access by default) |
| Max Memory     | 400 GiB concurrent (account limit)      |
| Max CPU        | 100 vCPU concurrent (account limit)     |
| Max Disk       | 2 TB concurrent                         |
| Image Storage  | 50 GB per account                       |

_Limitations:_

- Cold starts 1-5 seconds (slower than Workers' milliseconds)
- Binary network controls without bindings
- Bucket mounting only works with `wrangler deploy`, not `wrangler dev`
- SDK/container version must match
- Sandbox ID case sensitivity issues with preview URLs
- Still in open beta; ecosystem maturing

_Links:_

- Official: https://sandbox.cloudflare.com/
- SDK Documentation: https://developers.cloudflare.com/sandbox/
- Containers Pricing: https://developers.cloudflare.com/containers/pricing/
- Container Limits: https://developers.cloudflare.com/containers/platform-details/limits/
- Persistent Storage Tutorial: https://developers.cloudflare.com/sandbox/tutorials/persistent-storage/
- GitHub SDK: https://github.com/cloudflare/sandbox-sdk

---

## Comparison Table

| Feature          | Sprites             | E2B                 | Modal                | Cloudflare         | exe.dev               |
| ---------------- | ------------------- | ------------------- | -------------------- | ------------------ | --------------------- |
| Setup            | Easy                | Very Easy           | Easy                 | Easy               | Very Easy (SSH)       |
| Free Tier        | $30 credit          | $100 credit         | $30/month            | $5/mo Workers Paid | None ($20/mo)         |
| Isolation        | Firecracker microVM | Firecracker microVM | gVisor container     | Container          | Full VM (KVM)         |
| Cold Start       | <1 second           | ~150ms              | 2-5s (or <3s w/snap) | 1-5 seconds        | ~2 seconds            |
| Max Timeout      | None (persistent)   | 24 hours (Pro)      | 24 hours             | Configurable       | None (persistent)     |
| Claude CLI       | Pre-installed       | Prebuilt template   | Manual               | Manual             | Via Shelley agent     |
| Git Support      | Yes                 | Yes                 | Yes                  | Yes                | Yes                   |
| Persistent Files | Yes (permanent)     | 24 hours            | Via Volumes          | Via R2 FUSE mount  | Yes (permanent)       |
| Checkpoints      | Yes (~300ms)        | Pause/Resume (Beta) | Memory Snapshots     | No                 | No                    |
| Network Controls | Layer 3 policies    | Allow/deny lists    | CIDR allowlists      | Bindings model     | -                     |
| Edge Locations   | Fly.io regions      | -                   | -                    | 330+ global        | -                     |
| Max Concurrent   | 10 active (base)    | Plan-based          | 10,000+              | Plan-based         | 25 VMs (Individual)   |
| Self-Hosting     | Fly.io only         | Experimental        | No                   | No                 | No                    |
| MCP Tools        | -                   | 200+ (Docker)       | -                    | -                  | -                     |
| Best For         | Long-running agents | AI agent loops      | Python ML workloads  | Edge apps          | SSH-native persistent |

---

## Other Options

### Daytona

Founded by the creators of Codeanywhere (2009), pivoted in February 2025 from development environments to AI code execution infrastructure. 35,000+ GitHub stars (AGPL-3.0 license).

_Key Features:_

- Sub-90ms sandbox creation (container-based, faster than E2B's ~150ms microVM)
- Python SDK (`daytona_sdk` on PyPI) and TypeScript SDK
- Official LangChain integration (`langchain-daytona-data-analysis`)
- MCP Server support for Claude/Anthropic integrations
- OCI/Docker image compatibility
- Built-in Git and LSP support
- GPU support for ML workloads (enterprise tier)
- Unlimited persistence (sandboxes can live forever via object storage archiving)
- Virtual desktops (Linux, Windows, macOS with programmatic control)

_Philosophy:_ Daytona believes AI will automate the majority of programming tasks. Their agent-agnostic architecture enables parallel sandboxed environments for testing solutions simultaneously without affecting the developer's primary workspace.

_Unique Features:_

- _Fastest cold start_: ~90ms (container-based, faster than E2B's microVM)
- _LangChain integration_: Official `langchain-daytona-data-analysis` package
- _MCP Server_: Native Claude/Anthropic integration support
- _Virtual desktops_: Linux, Windows, macOS with programmatic control
- _Unlimited persistence_: Sandboxes can live forever via object storage archiving

_Pricing:_

| Item            | Cost                                          |
| --------------- | --------------------------------------------- |
| Free Credits    | $200 (requires credit card)                   |
| Startup Program | Up to $50k in credits                         |
| Small Sandbox   | ~$0.067/hour (1 vCPU, 1 GiB RAM)              |
| Billing         | Pay-per-second; stopped/archived minimal cost |

_Specs:_

| Spec       | Default     | Maximum              |
| ---------- | ----------- | -------------------- |
| vCPU       | 1           | 4 (contact for more) |
| RAM        | 1 GB        | 8 GB                 |
| Disk       | 3 GiB       | 10 GB                |
| Auto-stop  | 15 min idle | Disabled             |
| Cold start | ~90ms       | -                    |
| Isolation  | Docker/OCI  | Kata/Sysbox optional |

_Network Egress Tiers:_

- Tier 1 & 2: Restricted network access
- Tier 3 & 4: Full internet with custom CIDR rules
- All tiers whitelist essential services (NPM, PyPI, GitHub, Anthropic/OpenAI APIs, etc.)

_Limitations:_

- Container isolation by default (not microVM like E2B)
- Cannot snapshot running sandboxes
- Long-session stability still maturing
- Young ecosystem compared to E2B
- Requires credit card for free credits

_Daytona vs E2B:_

| Aspect           | Daytona            | E2B                 |
| ---------------- | ------------------ | ------------------- |
| Isolation        | Docker containers  | Firecracker microVM |
| Cold start       | ~90ms              | ~150ms              |
| Free credits     | $200 (CC required) | $100 (no CC)        |
| Max session      | Unlimited          | 24 hours (Pro)      |
| GitHub stars     | 35k+               | 10k+                |
| Network controls | Tier-based         | Allow/deny lists    |

_Links:_

- Official: https://www.daytona.io/
- Documentation: https://www.daytona.io/docs/en/
- GitHub: https://github.com/daytonaio/daytona
- Python SDK: https://pypi.org/project/daytona_sdk/
- Network Limits: https://www.daytona.io/docs/en/network-limits/
- Sandbox Management: https://www.daytona.io/docs/en/sandbox-management/
- LangChain Integration: https://docs.langchain.com/oss/python/integrations/tools/daytona_data_analysis
- MCP Servers Guide: https://www.daytona.io/dotfiles/production-ready-mcp-servers-at-scale-with-claude-daytona

---

### Google Cloud Run

Google Cloud's serverless container platform with strong security isolation, designed for production workloads at scale.

_Key Features:_

- Two-layer sandbox isolation (hardware + kernel)
- Automatic scaling (including scale-to-zero)
- Pay-per-second billing (100ms granularity)
- NVIDIA L4 GPU support for AI inference (24 GB VRAM)
- Direct VPC egress with firewall controls
- Cloud Storage and NFS volume mounts for persistence
- Request timeout up to 60 minutes (services), 7 days (jobs)
- Up to 1000 concurrent requests per instance
- Built-in HTTPS, IAM, Secret Manager integration
- Source-based deployment (no Dockerfile required)

_Philosophy:_ Google's approach treats Cloud Run as the "easy button" for serverless containers. Unlike dedicated AI sandbox providers, Cloud Run is a general-purpose platform that happens to work well for AI agents. The security model provides defense-in-depth through gVisor (1st gen) or Linux microVMs (2nd gen), with seccomp filtering in both. For AI-specific workloads, Google offers Agent Engine (fully managed) and GKE Agent Sandbox (Kubernetes-native) as alternatives.

_Unique Features:_

- _Dual execution environments_: 1st gen (gVisor-based, smaller attack surface) or 2nd gen (Linux microVM, more compatibility)
- _GPU scale-to-zero_: L4 GPUs spin down when idle, eliminating GPU idle costs
- _Startup CPU Boost_: Temporarily increases CPU during cold start (up to 50% faster startups for Java)
- _VPC Flow Logs_: Full visibility into network traffic for compliance
- _Network tags_: Granular firewall rules via VPC network tags on revisions
- _Volume mounts_: Cloud Storage FUSE or NFS (Cloud Filestore) for persistent data

_Pricing (Tier 1 regions, e.g., us-central1):_

| Resource | On-Demand             | Free Tier (Monthly)                  |
| -------- | --------------------- | ------------------------------------ |
| CPU      | $0.000024/vCPU-second | 180,000 vCPU-seconds (~50 hrs)       |
| Memory   | $0.0000025/GiB-second | 360,000 GiB-seconds (~100 hrs @ 1GB) |
| Requests | $0.40/million         | 2 million                            |
| GPU (L4) | ~$0.67/hour           | None                                 |

- Always-on billing is ~30% cheaper than on-demand
- Tier 2 regions (Asia, South America) are ~40% more expensive
- GPU requires minimum 4 vCPU + 16 GiB memory
- New customers: $300 free credits for 90 days

_Specs:_

| Spec            | Value                                                                  |
| --------------- | ---------------------------------------------------------------------- |
| Isolation       | Two-layer: hardware (x86 virtualization) + kernel (gVisor/microVM)     |
| Cold Start      | 2-5 seconds typical; sub-second with Startup CPU Boost + min instances |
| Max Timeout     | 60 minutes (services), 168 hours/7 days (jobs)                         |
| Max Memory      | 32 GiB                                                                 |
| Max CPU         | 8 vCPU (or 4 vCPU with GPU)                                            |
| Max Concurrency | 1000 requests/instance (default 80)                                    |
| Max Instances   | 1000 (configurable)                                                    |
| GPU             | NVIDIA L4 (24 GB VRAM), 1 per instance, <5s startup                    |
| Storage         | Ephemeral; use Cloud Storage or NFS mounts for persistence             |

_Network/Egress Controls:_

- Direct VPC egress without Serverless VPC Access connector
- Network tags on service revisions for firewall rules
- VPC Service Controls for data exfiltration prevention
- Organization policies to enforce VPC-only egress
- Cloud NAT supported for outbound IP control
- VPC Flow Logs for traffic visibility

_Limitations:_

- No persistent local disk (must use Cloud Storage or NFS volume mounts)
- Cold start latency higher than E2B/Sprites (2-5s vs <1s) without pre-warming
- Setup complexity: Requires GCP project, billing, IAM configuration
- VPC complexity: Network egress controls require VPC setup
- Job connection breaks: Jobs >1 hour may experience connection breaks during maintenance
- GPU regions limited: L4 GPUs only available in select regions
- No pre-built AI agent template (unlike E2B)
- Memory/session management must be built manually

_Google Cloud AI Agent Options Comparison:_

| Criteria               | Cloud Run                    | Agent Engine     | GKE Agent Sandbox       |
| ---------------------- | ---------------------------- | ---------------- | ----------------------- |
| Setup Complexity       | Medium                       | Low              | High                    |
| Infrastructure Control | Medium                       | Low              | High                    |
| Memory/Session Mgmt    | Manual                       | Built-in         | Manual                  |
| Isolation              | gVisor/microVM               | Built-in sandbox | gVisor + Kata           |
| Cold Start             | 2-5s (sub-second w/pre-warm) | Sub-second       | Sub-second (warm pools) |
| Best For               | Flexible serverless          | Fastest to prod  | Enterprise scale        |

_SDK/API Options:_

- Python: `pip install google-cloud-run`
- Node.js: `npm install @google-cloud/run`
- Go, Java, .NET, Ruby, PHP, Rust client libraries available
- REST API and gcloud CLI
- Terraform provider for IaC

_Links:_

- Documentation: https://cloud.google.com/run/docs
- AI Agents Guide: https://cloud.google.com/run/docs/ai-agents
- Pricing: https://cloud.google.com/run/pricing
- Security Design: https://cloud.google.com/run/docs/securing/security
- Quotas & Limits: https://cloud.google.com/run/quotas
- GPU Support: https://cloud.google.com/run/docs/configuring/services/gpu
- VPC Egress: https://cloud.google.com/run/docs/configuring/vpc-direct-vpc
- Volume Mounts: https://cloud.google.com/run/docs/configuring/services/cloud-storage-volume-mounts
- Python SDK: https://pypi.org/project/google-cloud-run/
- Quickstarts: https://cloud.google.com/run/docs/quickstarts

---

### Replit

Full development environment with built-in LLM agent (Agent 3).

_Key Features:_

- Agent 3 can run autonomously for up to 200 minutes without supervision
- Self-testing loop: executes code, identifies errors, fixes, and reruns until tests pass
- Proprietary testing system claimed to be 3x faster and 10x more cost-effective than Computer Use models
- Can build other agents and automations from natural language descriptions
- Built on 10+ years of infrastructure investment (custom file system, VM orchestration)

_Philosophy:_ Replit positions as an "agent-first" platform focused on eliminating "accidental complexity" (per CEO Amjad Masad). Target audience: anyone who wants to build software, not just engineers. The goal is to make Agent the primary interface for software creation.

_Unique Features:_

- _Agent 3 autonomy_: Up to 200 minutes of autonomous execution
- _Self-testing loop_: Automatic error detection and fixing
- _Agent building_: Can create other agents from natural language
- _Full IDE integration_: Complete development environment, not just sandbox
- _MCP support_: Integration guide available

_Pricing:_

| Plan       | Monthly  | Agent Access        | Compute           | Storage |
| ---------- | -------- | ------------------- | ----------------- | ------- |
| Starter    | Free     | Limited (daily cap) | 1 vCPU, 2 GiB RAM | 2 GiB   |
| Core       | $25      | Full Agent 3        | 4 vCPU, 8 GiB RAM | 50 GiB  |
| Teams      | $40/user | Full Agent 3 + RBAC | 4 vCPU, 8 GiB RAM | 50 GiB  |
| Enterprise | Custom   | Full + SSO/SAML     | Custom            | Custom  |

- Core plan includes $25/month in AI credits
- Teams plan includes $40/month in credits + 50 viewer seats
- Annual billing: ~20% discount

_Specs:_

| Spec       | Starter      | Core/Teams    |
| ---------- | ------------ | ------------- |
| vCPU       | 1            | 4             |
| RAM        | 2 GiB        | 8 GiB         |
| Storage    | 2 GiB        | 50 GiB        |
| Agent Time | Daily limits | Up to 200 min |

_Limitations:_

- **No public API for programmatic Agent access** — designed exclusively for in-browser interactive use, not for CI/CD pipelines or external autonomous agent orchestration
- Agent frequently gets stuck in loops on simple tasks
- Over-autonomy risk (can override user intent)
- External API authentication problems reported
- Unpredictable credit consumption ($100-300/month reported overages)
- Over 60% of developers report agent stalls/errors regularly (per surveys)
- Notable July 2025 incident where Agent deleted a production database

_Links:_

- Official: https://replit.com/
- Pricing: https://replit.com/pricing
- Agent 3 Announcement: https://blog.replit.com/introducing-agent-3-our-most-autonomous-agent-yet
- 2025 Year in Review: https://blog.replit.com/2025-replit-in-review
- AI Billing Docs: https://docs.replit.com/billing/ai-billing
- MCP Integration Guide: https://docs.replit.com/tutorials/mcp-in-3
- Fast Mode Docs: https://docs.replit.com/replitai/fast-mode

---

## Local Docker Options

### Docker Official Sandboxes

_Quick Start:_

```bash
docker sandbox run claude                  # Basic
docker sandbox run -w ~/my-project claude  # Custom workspace
docker sandbox run claude "your task"      # With prompt
docker sandbox run claude -c               # Continue last session
```

_Key Details:_

- Credentials stored in persistent volume `docker-claude-sandbox-data`
- `--dangerously-skip-permissions` enabled by default
- Base image includes: Node.js, Python 3, Go, Git, Docker CLI, GitHub CLI, ripgrep, jq
- Container persists in background; re-running reuses same container
- Non-root user with sudo access

_Links:_ https://docs.docker.com/ai/sandboxes/claude-code/

---

## Comparison: E2B vs Docker Local

| Aspect            | E2B (Cloud)         | Docker Local           |
| ----------------- | ------------------- | ---------------------- |
| Setup             | SDK call            | `docker sandbox run`   |
| Isolation         | Firecracker microVM | Container              |
| Cost              | ~$0.05/hr           | Free (your hardware)   |
| Max Duration      | 24 hours            | Unlimited              |
| Network           | Full internet       | Full internet          |
| State Persistence | Session-based       | Volume-based           |
| Multi-tenant Safe | Yes                 | No (local only)        |
| Best For          | Production, CI/CD   | Local dev, prototyping |

---

## Recommendation for This Project

### For Production/Multi-tenant: Use E2B

1. Pre-built Claude Code template = zero setup friction
2. 24-hour sessions handle long-running autonomous agents
3. Full filesystem for progress.txt, prd.json, git repos
4. Proven in production (Lovable, Quora use it)
5. True isolation (Firecracker microVM)
6. 200+ MCP tools via Docker partnership

### For Long-Running Persistent Agents: Use Sprites

1. No session time limits (persistent environments)
2. Transactional snapshots for version control of entire OS
3. Auto-sleep when idle reduces costs
4. Pre-installed Claude Code and AI CLI tools
5. Best for agents that need to maintain state across days/weeks

### For Local Development: Use Docker Sandboxes

1. _Quick prototyping_: `docker sandbox run claude`
2. _With git automation_: `claude-sandbox` (TextCortex)
3. _Minimal setup_: Uses persistent credentials volume
4. Free - runs on your own hardware
5. Unlimited session duration
