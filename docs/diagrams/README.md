# Architecture Diagrams

This directory contains architecture diagrams for Azure API Management patterns and configurations.

## Available Diagrams

The following diagrams are sourced from [Azure-Samples/Apim-Samples](https://github.com/Azure-Samples/Apim-Samples) (MIT License, © 2025 Microsoft) and illustrate common APIM deployment architectures.

| File | Description | Used In |
|------|-------------|---------|
| [Simple API Management Architecture.svg](Simple%20API%20Management%20Architecture.svg) | Basic APIM with public endpoint, backend services, and Azure Monitor telemetry | `labs/lab-01-beginner`, `docs/networking.md` |
| [API Management and Container Apps Architecture.svg](API%20Management%20and%20Container%20Apps%20Architecture.svg) | APIM with Azure Container Apps backends and Azure Monitor | `labs/lab-03-advanced`, `docs/networking.md` |
| [Azure Front Door API Management and Container Apps Architecture.svg](Azure%20Front%20Door%20API%20Management%20and%20Container%20Apps%20Architecture.svg) | Azure Front Door (with private link) → APIM → Container Apps | `docs/front-door.md` |
| [Azure Application Gateway API Management and Container Apps Architecture.svg](Azure%20Application%20Gateway%20API%20Management%20and%20Container%20Apps%20Architecture.svg) | Application Gateway (with Private Endpoint) → APIM Standard V2 → Container Apps | `docs/networking.md` |
| [Azure Application Gateway API Management and Container Apps Architecture VNet.svg](Azure%20Application%20Gateway%20API%20Management%20and%20Container%20Apps%20Architecture%20VNet.svg) | Application Gateway → VNet-injected APIM (Internal mode) → Container Apps | `docs/networking.md` |
| [Infrastructure-Sample-Compatibility.svg](Infrastructure-Sample-Compatibility.svg) | Compatibility matrix between infrastructures and samples (from Apim-Samples repo) | Reference |

## Attribution

These diagrams were created with the [Azure Draw.io MCP Server](https://github.com/simonkurtz-MSFT/drawio-mcp-server) and are used here under the [MIT License](https://github.com/Azure-Samples/Apim-Samples/blob/main/LICENSE) from the [Azure-Samples/Apim-Samples](https://github.com/Azure-Samples/Apim-Samples) repository.

## Adding New Diagrams

### Tools

- **Draw.io**: [https://app.diagrams.net/](https://app.diagrams.net/) — use the Azure icon library (More Shapes → Search "Azure")
- **Draw.io Desktop**: `brew install --cask drawio` (macOS) / `winget install drawio` (Windows)
- **Official Azure Icons**: [Azure Architecture Icons](https://learn.microsoft.com/azure/architecture/icons/)

### Best Practices

- Use official Azure Architecture Icons for consistency
- Export as SVG for scalability in documentation
- Use descriptive filenames: `apim-[scenario]-architecture.svg`
- Add alt text when referencing in Markdown

### Referencing Diagrams

From `docs/` files:
```markdown
<img src="diagrams/filename.svg" alt="Description of diagram" width="800" />
```

From `labs/lab-XX-*/` files:
```markdown
<img src="../../docs/diagrams/filename.svg" alt="Description of diagram" width="800" />
```
