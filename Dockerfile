# =============================================================================
# mdtexpdf Docker Image
# =============================================================================
# Thin app layer on top of mdtexpdf-base. Rebuilt on every push.
#
# Usage:
#   docker run --rm -v $(pwd):/work logismosis/mdtexpdf convert book.md --read-metadata
#   docker run --rm -v $(pwd):/work logismosis/mdtexpdf convert book.md --read-metadata --epub
# =============================================================================

FROM logismosis/mdtexpdf-base:latest

LABEL description="mdtexpdf - Markdown to PDF/EPUB converter using LaTeX"
LABEL org.opencontainers.image.source="https://github.com/ucli-tools/mdtexpdf"

COPY mdtexpdf.sh /usr/local/bin/mdtexpdf
COPY lib/ /usr/local/share/mdtexpdf/lib/
COPY filters/ /usr/local/share/mdtexpdf/filters/

RUN chmod +x /usr/local/bin/mdtexpdf

ENTRYPOINT ["mdtexpdf"]
CMD ["help"]
