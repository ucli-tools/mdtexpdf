---
title: "Section Numbering Test Document"
author: "Test Author"
date: "Today's Date"
output:
  pdf_document:
    template: template.tex
---

# Introduction

This document tests the section numbering feature of mdtexpdf. When converted with the default settings, sections should be numbered (1, 1.1, 1.1.1, etc.). When converted with the `--no-numbers` option, section numbers should be disabled.

## Purpose of This Test

This subsection demonstrates level 2 headings, which should be numbered as 1.1, 1.2, etc. when numbering is enabled.

### Detailed Information

This is a level 3 heading, which should be numbered as 1.1.1 when numbering is enabled.

## Expected Results

When converted with default settings:
- This section should be numbered as 1.2
- The "Purpose" section should be numbered as 1.1
- The "Detailed Information" section should be numbered as 1.1.1

# Second Main Section

This demonstrates another top-level section, which should be numbered as 2 when numbering is enabled.

## Subsection in Second Main Section

This subsection should be numbered as 2.1 when numbering is enabled.

### Sub-subsection

This should be numbered as 2.1.1 when numbering is enabled.

## Another Subsection

This should be numbered as 2.2 when numbering is enabled.

# Conclusion

The conclusion section should be numbered as 3 when numbering is enabled.

## Summary

The summary subsection should be numbered as 3.1 when numbering is enabled.