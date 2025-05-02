---
title: "LaTeX Math in Markdown"
author: "UCLI Tools"
date: "May 02, 2025"
output:
  pdf_document:
    template: template.tex
---

<!-- # LaTeX Math in Markdown -->

This document demonstrates how to use LaTeX math equations in Markdown.

## Inline Math Equations

You can include inline equations like this: $E = mc^2$ or \(F = ma\) within your text.

## Display Math Equations

For standalone equations, use double dollar signs:

$$\int_{a}^{b} f(x) \, dx = F(b) - F(a)$$

Or use the equation environment:

\begin{equation}
\frac{d}{dx} \left( \int_{a}^{x} f(t) \, dt \right) = f(x)
\end{equation}

## Matrix Example

$$
\begin{pmatrix}
a & b \\
c & d
\end{pmatrix}
\begin{pmatrix}
x \\
y
\end{pmatrix}
=
\begin{pmatrix}
ax + by \\
cx + dy
\end{pmatrix}
$$

## Aligned Equations

\begin{align}
a &= b + c \\
&= d + e + f \\
&= g + h
\end{align}

## Fractions and Summations

$$\sum_{i=1}^{n} \frac{1}{i^2} = \frac{\pi^2}{6}$$

## Chemical Equations

If you have the mhchem package included:

$$\ce{H2O + CO2 -> H2CO3}$$

## Greek Letters

Alpha: $\alpha$, Beta: $\beta$, Gamma: $\gamma$, Delta: $\delta$, Epsilon: $\epsilon$

## Theorem Environment

\begin{theorem}
For a right triangle with sides $a$, $b$ and hypotenuse $c$:
$$a^2 + b^2 = c^2$$
\end{theorem}

## Proof Environment

\begin{proof}
This is a proof of the Pythagorean theorem.
\end{proof}

# Regular Markdown Features

- Bullet points
- Work normally

1. Numbered lists
2. Also work

**Bold text** and *italic text* are supported.

> Blockquotes work as expected.

Tables work too:

| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| Cell 1   | Cell 2   | Cell 3   |
| Cell 4   | Cell 5   | Cell 6   |

Code blocks are supported:

```python
def hello_world():
    print("Hello, world!")
```
