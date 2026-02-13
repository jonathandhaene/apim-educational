# Architecture Diagrams

This directory contains architecture diagrams for Azure API Management patterns and configurations.

## Directory Structure

```
diagrams/
├── README.md (this file)
├── sources/              # Editable source files
│   ├── drawio/          # Draw.io (diagrams.net) files
│   └── plantuml/        # PlantUML source files
└── exported/            # Exported PNG/SVG for documentation
    ├── png/
    └── svg/
```

## Diagram Tools

### Draw.io (diagrams.net)

**Recommended for**: Architecture diagrams, network topology, component diagrams

**How to use:**
1. Create diagrams at [https://app.diagrams.net/](https://app.diagrams.net/)
2. Use Azure icon library: More Shapes → Search "Azure"
3. Save source file (.drawio) in `sources/drawio/`
4. Export as PNG (300 DPI) to `exported/png/`
5. Export as SVG to `exported/svg/`

**Best Practices:**
- Use consistent Azure icon style (official Azure icons)
- Include legend for custom symbols
- Use layers for complex diagrams
- Name files descriptively: `apim-vnet-integration.drawio`

**Official Azure Icons:**
- [Azure Architecture Icons](https://learn.microsoft.com/azure/architecture/icons/)
- Download SVG set from Microsoft

### PlantUML

**Recommended for**: Sequence diagrams, component diagrams, deployment diagrams

**How to use:**
1. Write PlantUML source code in `sources/plantuml/`
2. Generate diagrams using PlantUML CLI or online editor
3. Save PNG/SVG to `exported/`

**Installation:**
```bash
# macOS
brew install plantuml

# Ubuntu/Debian
sudo apt-get install plantuml

# Generate diagram
plantuml sources/plantuml/api-request-flow.puml -o ../../exported/png/
```

**Example PlantUML:**
```plantuml
@startuml api-request-flow
!define AzurePuml https://raw.githubusercontent.com/plantuml-stdlib/Azure-PlantUML/release/2-2/dist
!include AzurePuml/AzureCommon.puml
!include AzurePuml/Integration/AzureAPIManagement.puml
!include AzurePuml/Compute/AzureFunction.puml

actor Client
AzureAPIManagement(apim, "API Gateway", "APIM")
AzureFunction(backend, "Backend API", "Function")

Client -> apim : HTTPS Request
apim -> apim : Validate JWT
apim -> apim : Apply Policies
apim -> backend : Forward Request
backend -> apim : Response
apim -> Client : HTTPS Response
@enduml
```

## Diagram Inventory

### Planned Diagrams

Create these diagrams as part of documentation:

**Networking:**
- [ ] `apim-public-deployment.png` - Public APIM with Azure PaaS backends
- [ ] `apim-external-vnet.png` - External VNet integration
- [ ] `apim-internal-vnet.png` - Internal VNet with Application Gateway
- [ ] `apim-private-endpoint.png` - Private Endpoint configuration
- [ ] `apim-multi-region.png` - Multi-region deployment with Traffic Manager

**Integration Patterns:**
- [ ] `apim-frontdoor-integration.png` - Front Door + APIM
- [ ] `apim-ai-gateway.png` - AI Gateway architecture
- [ ] `apim-microservices.png` - APIM as microservices gateway
- [ ] `apim-api-center.png` - API Center integration

**Security:**
- [ ] `apim-authentication-flow.png` - OAuth/JWT authentication flow
- [ ] `apim-mtls.png` - Mutual TLS configuration
- [ ] `apim-security-layers.png` - Defense in depth layers

**Request Flow:**
- [ ] `apim-request-pipeline.png` - Complete request/response pipeline
- [ ] `apim-policy-execution.png` - Policy execution order (global > product > API > operation)

## Naming Conventions

### File Naming

Format: `[component]-[scenario]-[type].[extension]`

Examples:
- `apim-vnet-integration-architecture.drawio`
- `apim-jwt-validation-sequence.puml`
- `apim-multi-region-topology.png`

### Diagram Titles

Include in diagram:
- Title: Clear, descriptive name
- Date: Last updated date
- Version: Version number if applicable
- Description: Brief explanation

## Exporting Guidelines

### PNG Export

**Settings:**
- Resolution: 300 DPI (high quality)
- Background: Transparent or white
- Border: 10-20px padding
- Max width: 1920px (for documentation)

**Purpose**: Embedding in documentation (README, guides)

### SVG Export

**Settings:**
- Include embedded fonts
- Optimize for size
- Keep text as text (not paths) when possible

**Purpose**: High-quality printing, scalable diagrams

## Including Diagrams in Documentation

### Markdown

```markdown
# Architecture

The following diagram shows APIM integrated with VNet:

![APIM VNet Integration](diagrams/exported/png/apim-vnet-integration.png)

*Figure 1: APIM External VNet Integration*
```

### Bicep/Terraform Comments

```bicep
// Architecture: See diagrams/exported/png/apim-multi-region.png
// This configuration deploys APIM across multiple regions
resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  // ...
}
```

## Diagram Templates

### Architecture Diagram Template (Draw.io)

**Standard Components:**
1. **Title Block** (top-right):
   - Diagram name
   - Last updated date
   - Version

2. **Layers**:
   - Layer 0: Background and borders
   - Layer 1: Infrastructure (VNets, subnets)
   - Layer 2: Services (APIM, backends)
   - Layer 3: Data flow (arrows, labels)
   - Layer 4: Notes and legends

3. **Legend** (bottom-left):
   - Icon explanations
   - Line types (data flow, management, etc.)
   - Color coding

4. **Standard Colors**:
   - Azure services: Use official icon colors
   - Data flow: Blue (#0078D4)
   - Management plane: Orange (#F59B00)
   - Security boundaries: Red dashed line

### Sequence Diagram Template (PlantUML)

```plantuml
@startuml sequence-template
!define AzurePuml https://raw.githubusercontent.com/plantuml-stdlib/Azure-PlantUML/release/2-2/dist
!include AzurePuml/AzureCommon.puml

title Sequence Diagram Title
header Last Updated: YYYY-MM-DD

' Define participants
actor User
participant "API Gateway\n(APIM)" as APIM
participant "Backend\nService" as Backend
database "Database" as DB

' Define sequence
User -> APIM : Request
activate APIM

APIM -> APIM : Validate Auth
APIM -> APIM : Apply Policies

APIM -> Backend : Forward Request
activate Backend

Backend -> DB : Query Data
activate DB
DB --> Backend : Results
deactivate DB

Backend --> APIM : Response
deactivate Backend

APIM -> APIM : Transform Response
APIM --> User : Response
deactivate APIM

footer Diagram: sequence-template.puml
@enduml
```

## Maintenance

### Update Process

1. **Source Files**: Always update source files (`.drawio`, `.puml`) first
2. **Export**: Re-export to PNG/SVG after changes
3. **Git**: Commit both source and exported files
4. **Documentation**: Update references in documentation if file names change

### Versioning

- Use Git for version control
- Include version number in diagram if it goes through formal reviews
- Keep old versions in Git history (don't delete)

### Review

- Peer review for accuracy
- Technical validation (does it match actual implementation?)
- Visual consistency (follow style guide)

## Tools and Resources

### Online Editors

- **Draw.io**: [https://app.diagrams.net/](https://app.diagrams.net/)
- **PlantUML Online**: [http://www.plantuml.com/plantuml/](http://www.plantuml.com/plantuml/)

### Local Tools

**Draw.io Desktop:**
```bash
# macOS
brew install --cask drawio

# Windows
winget install drawio
```

**PlantUML:**
```bash
# macOS
brew install plantuml

# Ubuntu
sudo apt-get install plantuml

# Windows
choco install plantuml
```

### VS Code Extensions

- **Draw.io Integration**: `hediet.vscode-drawio`
- **PlantUML**: `jebbs.plantuml`

### Icon Libraries

- [Azure Architecture Icons](https://learn.microsoft.com/azure/architecture/icons/)
- [Azure PlantUML](https://github.com/plantuml-stdlib/Azure-PlantUML)
- [C4 Model](https://c4model.com/) for architecture diagrams

## Contributing

When contributing new diagrams:

1. Check if similar diagram already exists
2. Follow naming conventions
3. Use standard templates
4. Include legend and labels
5. Export in both PNG and SVG
6. Submit source files with PR
7. Update this README inventory

## Questions?

- Open an issue for diagram requests
- Tag with `documentation` label
- Provide description of needed diagram
- Reference documentation section where it will be used

---

**Visual communication** is key to understanding complex architectures. Maintain high-quality, consistent diagrams!
