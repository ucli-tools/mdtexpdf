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

## Setting Up Authorship Verification

### Step 1: Generate a PGP Key (if you don't have one)

```bash
# Generate a new GPG key
gpg --full-generate-key

# Choose RSA and RSA (default)
# Choose 4096 bits for key size
# Set expiration as desired
# Enter your name and email
```

### Step 2: Get Your Key Fingerprint

```bash
# List your keys and get the fingerprint
gpg --list-keys --fingerprint your@email.com

# Output looks like:
# pub   rsa4096 2026-01-01 [SC]
#       4A2B 8C3D E9F1 7A6B 2C4D 9E8F 1A3B 5C7D 8E9F 0A1B
# uid   [ultimate] Your Name <your@email.com>
```

### Step 3: Add to Your Book Metadata

```yaml
---
# ... other metadata ...

# Authorship & Support
author_pubkey: "4A2B 8C3D E9F1 7A6B 2C4D 9E8F 1A3B 5C7D 8E9F 0A1B"
author_pubkey_type: "PGP"
---
```

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

For maximum verification, you can also sign the PDF itself:

### Create a Detached Signature

```bash
# Sign the PDF
gpg --detach-sign --armor book.pdf

# This creates book.pdf.asc
```

### Verify a Signature

Anyone can verify your authorship:

```bash
# First, import the author's public key (from key servers or the book itself)
gpg --keyserver keyserver.ubuntu.com --recv-keys 4A2B8C3DE9F17A6B2C4D9E8F1A3B5C7D8E9F0A1B

# Verify the signature
gpg --verify book.pdf.asc book.pdf
```

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

# Authorship verification
author_pubkey: "4A2B 8C3D E9F1 7A6B 2C4D 9E8F 1A3B 5C7D 8E9F 0A1B"
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

The generated PDF will include an "Authorship & Support" page that looks like:

```
                    Authorship & Support

AUTHORSHIP VERIFICATION

PGP: 4A2B 8C3D E9F1 7A6B 2C4D 9E8F 1A3B 5C7D 8E9F 0A1B

────────────────

SUPPORT THE AUTHOR

Bitcoin: bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
Ethereum: 0x71C7656EC7ab88b098defB751B7401B5f6d8976F
```

## Best Practices

1. **Use your real PGP key** - This is your identity; protect your private key
2. **Publish your public key** - Upload to key servers so others can verify
3. **Keep wallet addresses consistent** - Use the same addresses across your books
4. **Consider a dedicated signing key** - Some authors use a separate key for signing works
5. **Document your verification process** - Help readers understand how to verify

## Verification Workflow for Readers

A reader who wants to verify authorship can:

1. Note the PGP fingerprint from the "Authorship & Support" page
2. Look up the author's public key on key servers
3. If the author signed the PDF, verify the signature
4. If the fingerprints match, authorship is verified

This creates a chain of trust without relying on any centralized authority.
