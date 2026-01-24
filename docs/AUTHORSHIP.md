# Authorship & Support Guide

This guide explains how to use mdtexpdf's Authorship & Support system to create self-contained books that can cryptographically prove authorship and accept donations.

## Philosophy: The Open Source Book

Traditional books rely on publishers and external systems for attribution. An "open source book" is different:

- **Self-contained**: The book itself contains all information needed to verify authorship
- **Cryptographically verifiable**: Uses PGP/GPG signatures that can be verified by anyone
- **Freely shareable**: Pass it along, copy it, share it - authorship remains provable
- **Direct support**: Readers can support the author directly via cryptocurrency

## How It Works

When you include authorship metadata, mdtexpdf creates a dedicated "Authorship & Support" page after the copyright page containing:

1. **Authorship Verification** - Your PGP/GPG public key fingerprint
2. **Support the Author** - Your cryptocurrency wallet addresses

## Key Types: RSA vs Ed25519

### Ed25519 (Recommended)

Ed25519 is the modern standard for cryptographic keys:

- **Smaller keys**: 256-bit (64 hex characters for fingerprint) vs RSA's 4096-bit
- **Faster**: Signing and verification are significantly quicker
- **More secure**: Better resistance to side-channel attacks
- **Modern standard**: Used by SSH, Signal, WireGuard, and most modern systems
- **Same security**: 256-bit Ed25519 ≈ 3000-bit RSA in security strength

### RSA (Legacy)

RSA is still widely supported but considered legacy:

- **Larger keys**: 4096-bit recommended (800+ character public keys)
- **Slower**: More computationally intensive
- **Universal support**: Works with older systems
- **Well-understood**: Decades of cryptanalysis

**Recommendation**: Use Ed25519 unless you need compatibility with very old systems.

## Setting Up Authorship Verification

### Option A: Ed25519 Key (Recommended)

#### Step 1: Generate an Ed25519 GPG Key

```bash
# Generate a new Ed25519 GPG key
gpg --full-generate-key --expert

# When prompted for key type, select:
#   (9) ECC and ECC
# Then select:
#   (1) Curve 25519
# Set expiration as desired (0 = never, or 1y, 2y, etc.)
# Enter your name and email
# Set a strong passphrase
```

Or use the quick method:

```bash
# Quick generation with defaults
gpg --quick-generate-key "Your Name <your@email.com>" ed25519 cert never
```

#### Step 2: Get Your Key Fingerprint

```bash
# List your keys and get the fingerprint
gpg --list-keys --fingerprint your@email.com

# Output looks like:
# pub   ed25519 2026-01-23 [C]
#       AB12 CD34 EF56 7890 1234 5678 90AB CDEF 1234 5678
# uid   [ultimate] Your Name <your@email.com>
```

The fingerprint is the 40-character hex string (with spaces for readability).

#### Step 3: Export Your Public Key

```bash
# Export ASCII-armored public key (for sharing/uploading)
gpg --armor --export your@email.com > publickey.asc

# View it
cat publickey.asc
```

#### Step 4: Upload to Key Servers (Optional but Recommended)

```bash
# Upload to key servers so others can verify
gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID

# Or upload to multiple servers
gpg --keyserver keyserver.ubuntu.com --send-keys YOUR_KEY_ID
gpg --keyserver keys.gnupg.net --send-keys YOUR_KEY_ID
```

### Option B: RSA Key (Legacy)

```bash
# Generate a 4096-bit RSA key
gpg --full-generate-key

# Choose:
#   (1) RSA and RSA
#   4096 bits
# Set expiration and identity as above
```

## Adding to Your Book Metadata

```yaml
---
# ... other metadata ...

# Authorship & Support
author_pubkey: "AB12 CD34 EF56 7890 1234 5678 90AB CDEF 1234 5678"
author_pubkey_type: "PGP"  # Or "GPG" - they're equivalent
---
```

Note: The `author_pubkey_type` field is for display purposes. Both PGP and GPG use the same OpenPGP standard.

## Setting Up Donation Wallets

Add as many cryptocurrency wallets as you want to accept:

```yaml
---
# ... other metadata ...

donation_wallets:
  - type: "Bitcoin"
    address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
  - type: "Ethereum"
    address: "0x71C7656EC7ab88b098defB751B7401B5f6d8976F"
  - type: "Monero"
    address: "48daf1rG3hE1Txapq3SLmL..."
  - type: "Solana"
    address: "DRpbCBMxVnDK7maPGv..."
---
```

## Signing Your Book

For maximum verification, sign your book files with detached signatures. This proves the files haven't been tampered with since you signed them.

### Sign Both PDF and EPUB

```bash
# Sign the PDF (creates book.pdf.asc)
gpg --detach-sign --armor book.pdf

# Sign the EPUB (creates book.epub.asc)
gpg --detach-sign --armor book.epub

# If you have multiple keys, specify which one to use:
gpg --detach-sign --armor --local-user your@email.com book.pdf
gpg --detach-sign --armor --local-user your@email.com book.epub
```

### Export Your Public Key for Distribution

```bash
# Export your public key so readers can verify
gpg --armor --export your@email.com > author_publickey.asc
```

### What to Distribute

Your complete distribution package should include:

```
your_book/
├── book.pdf              # The PDF
├── book.pdf.asc          # PDF signature
├── book.epub             # The EPUB
├── book.epub.asc         # EPUB signature
└── author_publickey.asc  # Your public key for verification
```

Readers need all of these to verify your authorship:
- The book files (PDF/EPUB)
- The corresponding signature files (.asc)
- Your public key (to verify the signatures)

### Verify a Signature

Anyone can verify your authorship:

```bash
# Import the author's public key (from key servers)
gpg --keyserver keys.openpgp.org --recv-keys AB12CD34EF567890123456789OABCDEF12345678

# Or import from a file
gpg --import author_publickey.asc

# Verify the PDF signature
gpg --verify book.pdf.asc book.pdf

# Verify the EPUB signature
gpg --verify book.epub.asc book.epub

# Successful output:
# gpg: Signature made Thu 23 Jan 2026 12:00:00 PM UTC
# gpg: using EDDSA key AB12CD34EF567890123456789OABCDEF12345678
# gpg: Good signature from "Your Name <your@email.com>" [ultimate]
```

### Complete Signing Workflow

Here's the full workflow from key creation to signed distribution:

```bash
# 1. Generate your key (once)
gpg --quick-generate-key "Your Name <your@email.com>" ed25519 cert never

# 2. Get your fingerprint (add to book metadata)
gpg --list-keys --fingerprint your@email.com

# 3. Build your book with mdtexpdf
mdtexpdf convert book.md --read-metadata
mdtexpdf convert book.md --read-metadata --epub

# 4. Sign both formats
gpg --detach-sign --armor book.pdf
gpg --detach-sign --armor book.epub

# 5. Export public key for distribution
gpg --armor --export your@email.com > author_publickey.asc

# 6. Distribute all files together
```

## Pseudonymous Authorship

You can create a key under a pen name for anonymous or pseudonymous publishing. The key doesn't need to contain your real identity - it just needs to be something you control.

### Creating a Pseudonymous Key

```bash
# Create a key with your pen name
gpg --quick-generate-key "Pen Name (Your motto or message) <penname@your.book>" ed25519 cert never

# Example:
gpg --quick-generate-key "A. Nonymous (Truth needs no name) <author@anonymous.pub>" ed25519 cert never
```

The identity string can include:
- **Name**: Your pen name or pseudonym
- **Comment**: A motto, message, or identifier (in parentheses)
- **Email**: A fictional email that identifies the work

### Pseudonymous Workflow

```bash
# 1. Generate pseudonymous key
gpg --quick-generate-key "Pen Name (Your message) <penname@book.title>" ed25519 cert never

# 2. Get fingerprint and add to book metadata
gpg --list-keys --fingerprint penname@book.title

# 3. Build and sign
mdtexpdf convert book.md --read-metadata
mdtexpdf convert book.md --read-metadata --epub
gpg --detach-sign --armor --local-user penname@book.title book.pdf
gpg --detach-sign --armor --local-user penname@book.title book.epub

# 4. Export the pseudonymous public key
gpg --armor --export penname@book.title > author_publickey.asc

# 5. Backup your private key securely
gpg --armor --export-secret-keys penname@book.title > private_key_backup.asc
# Store this backup safely - it's the only proof you're the author!
```

### Proving Authorship Later

At any future time, you can prove you're the author by signing a new message:

```bash
# Sign a dated statement
echo "I am the author of [Book Title]. Today is $(date)." | \
  gpg --sign --armor --local-user penname@book.title
```

Anyone can verify this signature against the public key in your book. This provides cryptographic proof of authorship without revealing your real identity.

## Complete Example

```yaml
---
title: "My Open Source Book"
subtitle: "Freely Shared, Cryptographically Verified"
author: "Your Name"
date: "January 2026"

format: "book"
toc: true
copyright_page: true
publisher: "Self-Published"
copyright_year: 2026

# Authorship verification (Ed25519 fingerprint)
author_pubkey: "AB12 CD34 EF56 7890 1234 5678 90AB CDEF 1234 5678"
author_pubkey_type: "PGP"

# Support the author
donation_wallets:
  - type: "Bitcoin"
    address: "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh"
  - type: "Ethereum"
    address: "0x71C7656EC7ab88b098defB751B7401B5f6d8976F"
---
```

## Output

The generated PDF will include an "Authorship & Support" page:

```
                    Authorship & Support

AUTHORSHIP VERIFICATION

PGP: AB12 CD34 EF56 7890 1234 5678 90AB CDEF 1234 5678

────────────────

SUPPORT THE AUTHOR

Bitcoin: bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
Ethereum: 0x71C7656EC7ab88b098defB751B7401B5f6d8976F
```

## Key Management Best Practices

### Security

1. **Protect your private key** - Never share it; use a strong passphrase
2. **Backup your key** - Store encrypted backups in multiple secure locations
3. **Use a hardware key** (optional) - YubiKey or similar for maximum security

```bash
# Backup your private key (store securely!)
gpg --armor --export-secret-keys your@email.com > private-key-backup.asc
```

### Identity

1. **Use consistent identity** - Same key across all your works
2. **Publish your public key** - Key servers, your website, social profiles
3. **Cross-link identities** - Consider Keybase or similar for identity proofs

### Key Expiration

1. **Set reasonable expiration** - 2-5 years is common
2. **Extend before expiration** - You can extend without generating a new key
3. **Document succession** - What happens if you lose access to your key?

```bash
# Extend key expiration
gpg --edit-key your@email.com
gpg> expire
# Follow prompts to set new expiration
gpg> save
```

## Verification Workflow for Readers

A reader who wants to verify authorship can:

1. Note the PGP fingerprint from the "Authorship & Support" page
2. Look up the author's public key on key servers or the author's website
3. If the author signed the PDF, verify the signature matches
4. If the fingerprints match, authorship is cryptographically verified

This creates a chain of trust without relying on any centralized authority.

## Troubleshooting

### "No public key" error when verifying

```bash
# Import the key first
gpg --keyserver keys.openpgp.org --recv-keys FINGERPRINT
```

### Key not found on key servers

The author may not have uploaded their key. Check:
- Author's website for public key file
- Book's accompanying files for `publickey.asc`
- Contact the author directly

### "Bad signature" error

The file may have been modified after signing. Get a fresh copy from the original source.

## Alternative: Nostr Identity

For authors in the Bitcoin/Nostr ecosystem, you can also use a Nostr npub:

```yaml
author_pubkey: "npub1xyz..."
author_pubkey_type: "Nostr"
```

This links your book to your Nostr identity, verifiable on any Nostr client.
