# Makefile for IETF draft generation using kramdown-rfc and xml2rfc

# Variables
DRAFT_NAME = draft-lampin-schc-voici-compression
MARKDOWN_FILE = $(DRAFT_NAME).md
XML_FILE = $(DRAFT_NAME).xml
TXT_FILE = $(DRAFT_NAME).txt
HTML_FILE = $(DRAFT_NAME).html
PDF_FILE = $(DRAFT_NAME).pdf

# Default target
all: txt html xml pdf

# Individual targets
txt: $(TXT_FILE)
html: $(HTML_FILE)
xml: $(XML_FILE)
pdf: $(PDF_FILE)

# Build rules
$(TXT_FILE): $(MARKDOWN_FILE)
	@echo "Generating TXT file..."
	kdrfc --txt $(MARKDOWN_FILE)

$(HTML_FILE): $(MARKDOWN_FILE)
	@echo "Generating HTML file..."
	kdrfc --html $(MARKDOWN_FILE)

$(XML_FILE): $(MARKDOWN_FILE)
	@echo "Generating XML file..."
	kdrfc --xml $(MARKDOWN_FILE)

$(PDF_FILE): $(MARKDOWN_FILE)
	@echo "Generating PDF file using remote service..."
	kdrfc --pdf --remote $(MARKDOWN_FILE)

# Clean generated files
clean:
	rm -f $(TXT_FILE) $(HTML_FILE) $(XML_FILE) $(PDF_FILE)

# Check if required tools are installed
check-tools:
	@echo "Checking required tools..."
	@which kdrfc > /dev/null || (echo "ERROR: kdrfc not found. Install kramdown-rfc" && false)
	@which xml2rfc > /dev/null || (echo "ERROR: xml2rfc not found. Install xml2rfc" && false)
	@echo "All required tools are available."

# Validate the draft
validate: $(XML_FILE)
	@echo "Validating XML file..."
	xml2rfc --validate $(XML_FILE)

# Preview in browser (macOS specific)
preview: $(HTML_FILE)
	open $(HTML_FILE)

# Help target
help:
	@echo "Available targets:"
	@echo "  all       - Generate TXT, HTML, and XML files (default)"
	@echo "  complete  - Generate all formats including PDF"
	@echo "  txt       - Generate TXT file only"
	@echo "  html      - Generate HTML file only"
	@echo "  xml       - Generate XML file only"
	@echo "  pdf       - Generate PDF file only"
	@echo "  clean     - Remove all generated files"
	@echo "  check-tools - Check if required tools are installed"
	@echo "  validate  - Validate the XML file"
	@echo "  preview   - Open HTML file in browser (macOS)"
	@echo "  help      - Show this help message"

.PHONY: all complete txt html xml pdf clean check-tools validate preview help
