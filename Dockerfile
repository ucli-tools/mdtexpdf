# =============================================================================
# mdtexpdf Docker Image
# =============================================================================
# This image contains all dependencies needed to run mdtexpdf:
# - Pandoc (document conversion)
# - TexLive (LaTeX for PDF generation)
# - ImageMagick (cover generation for EPUB)
# - Fonts (DejaVu, Noto CJK)
#
# Usage:
#   docker run --rm -v $(pwd):/work uclitools/mdtexpdf convert book.md --read-metadata
#   docker run --rm -v $(pwd):/work uclitools/mdtexpdf convert book.md --read-metadata --epub
#
# =============================================================================

FROM ubuntu:24.04

LABEL maintainer="ucli-tools"
LABEL description="mdtexpdf - Markdown to PDF/EPUB converter using LaTeX"
LABEL org.opencontainers.image.source="https://github.com/ucli-tools/mdtexpdf"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    # Pandoc
    pandoc \
    # LaTeX (full for maximum compatibility)
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-fonts-extra \
    texlive-science \
    texlive-xetex \
    texlive-luatex \
    # ImageMagick for cover generation
    imagemagick \
    # Fonts
    fonts-dejavu \
    fonts-noto-cjk \
    # Utilities
    bash \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /work

# Copy mdtexpdf files
COPY mdtexpdf.sh /usr/local/bin/mdtexpdf
COPY lib/ /usr/local/share/mdtexpdf/lib/
COPY filters/ /usr/local/share/mdtexpdf/filters/

# Make executable
RUN chmod +x /usr/local/bin/mdtexpdf

# Set the entrypoint
ENTRYPOINT ["mdtexpdf"]

# Default command shows help
CMD ["help"]
