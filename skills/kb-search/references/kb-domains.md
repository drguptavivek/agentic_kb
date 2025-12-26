# Knowledge Base Domains

This document provides an overview of the available knowledge domains in agentic_kb.

## Available Domains

### Android
Mobile development and Android-specific knowledge.

**Common topics:**
- Android app development
- Mobile UI/UX patterns
- Android tooling and SDKs

### Document Automation
Automation workflows for document processing, generation, and transformation.

**Common topics:**
- Pandoc workflows and templates
- PDF processing and manipulation
- Document format conversion
- LaTeX and markdown processing
- Automated report generation

### ODK Central
Open Data Kit Central server administration and data collection workflows.

**Common topics:**
- ODK Central setup and configuration
- Form design and deployment
- Data collection workflows
- API integration and automation

### Search
Information retrieval, search systems, and agent retrieval workflows.

**Common topics:**
- Search algorithms and strategies
- Vector search vs full-text search
- Agent retrieval workflows
- Typesense and FAISS usage
- Search optimization

### Security
Security best practices, authentication, and secure coding patterns.

**Common topics:**
- Authentication and authorization
- Secure coding practices
- Security policies and compliance
- Vulnerability assessment

## Finding Content Within Domains

Use the `--filter` flag with Typesense to search within specific domains:

```bash
# Search only in Document Automation domain
uv run --with typesense python agentic_kb/scripts/search_typesense.py "pandoc" \
  --filter "domain:Document Automation"

# Search only in Search domain
uv run --with typesense python agentic_kb/scripts/search_typesense.py "retrieval" \
  --filter "domain:Search"
```

## Document Types

KB documents are categorized by type in frontmatter:

- **howto** - Step-by-step guides and procedures
- **reference** - Reference documentation and specifications
- **checklist** - Checklists for specific tasks
- **policy** - Policies and standards
- **note** - General notes and observations

Filter by type:

```bash
uv run --with typesense python agentic_kb/scripts/search_typesense.py "search" \
  --filter "type:howto"
```

## Document Status

Documents have status tags:

- **approved** - Reviewed and approved for use
- **draft** - Work in progress
- **deprecated** - No longer recommended

Filter by status:

```bash
uv run --with typesense python agentic_kb/scripts/search_typesense.py "workflow" \
  --filter "status:approved"
```
