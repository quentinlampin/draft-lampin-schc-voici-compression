# draft-lampin-schc-voici-compression-00

**SCHC Compression of VOICI Headers** — Internet-Draft for the IETF SCHC Working Group

This document describes how to compress VOICI headers using SCHC rules at a lower stratum, demonstrating that VOICI provides explicit routing metadata that is transparently compressed to minimal on-wire size while preserving standardized dispatch semantics.

## Files

| File | Description |
|---|---|
| `draft-lampin-schc-voici-compression.md` | Source (kramdown-rfc2629) |
| `draft-lampin-schc-voici-compression.pdf` | Rendered PDF |
| `draft-lampin-schc-voici-compression.html` | Rendered HTML |
| `draft-lampin-schc-voici-compression.txt` | Rendered plain text |
| `draft-lampin-schc-voici-compression.xml` | Rendered XML (rfc2629) |

## Building

Requires [`kramdown-rfc`](https://github.com/kramdown-rfc/kramdown-rfc) (kdrfc).

```bash
make          # Generate TXT, HTML, XML and PDF
make txt      # Generate TXT
make html     # Generate HTML
make xml      # Generate XML
make pdf      # Generate PDF (via remote xml2rfc service)
make clean    # Remove generated files
make preview  # Open HTML in browser (macOS)
```

## References

- [RFC 8724](https://www.rfc-editor.org/rfc/rfc8724) — SCHC (SchC) Framework
- [draft-lampin-voici-02](https://datatracker.ietf.org/doc/draft-lampin-voici/) — VOICI: A Link Multiplexer for SCHC

## Author

Quentin Lampin (Orange) — `<quentin.lampin@orange.com>`
