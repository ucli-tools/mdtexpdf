# LaTeX Math Syntax in Markdown for mdtexpdf

This guide provides an overview of how to use LaTeX mathematical notation within your Markdown files when using the `mdtexpdf.sh` script. The script leverages Pandoc and a LaTeX backend, so standard LaTeX math syntax is generally supported.

## Understanding Equation Numbering

How your equations are numbered in the final PDF depends on the LaTeX environment you use in your Markdown source.

### 1. Unnumbered Display Equations

For standalone equations that you do **not** want to be numbered, use double dollar signs `$$ ... $$`.

**Markdown Example:**
```latex
$$
\int_{a}^{b} f(x) \, dx = F(b) - F(a)
$$
```
This will render as a centered equation without a number. The `mdtexpdf` script also supports matrices using this syntax:
```latex
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
```

### 2. Numbered Single Equations

To display a single equation that receives an automatic number, use the `\begin{equation} ... \end{equation}` environment.

**Markdown Example:**
```latex
\begin{equation}
\frac{d}{dx} \left( \int_{a}^{x} f(t) \, dt \right) = f(x) \label{eq:ftc}
\end{equation}
```
This equation will be numbered (e.g., (1)).
*   **Labeling**: Notice the `\label{eq:ftc}`. You can use this label to refer to the equation elsewhere in your document using Pandoc's cross-referencing syntax, like `@eq:ftc`.

### 3. Numbered Aligned Equations (Multiple Lines)

For a sequence of equations that should be aligned (e.g., at the `=` sign), and where **each line gets its own number**, use the `\begin{align} ... \end{align}` environment.

**Markdown Example:**
```latex
\begin{align}
a &= b + c \label{eq:align_line1} \\
&= d + e + f \label{eq:align_line2} \\
&= g + h \label{eq:align_line3}
\end{align}
```
This will produce three aligned equations, each with its own number (e.g., (2), (3), (4)).

#### Suppressing Numbers in `align`

If you want to prevent a specific line within an `align` environment from being numbered, add `\nonumber` or `\notag` before the line break `\\`.

**Markdown Example:**
```latex
\begin{align}
x &= y + z \\
&= w + v \nonumber \\
&= u
\end{align}
```
In this case, the second line (`= w + v`) will not have a number.

#### Single Number for Multiple Aligned Lines

If you have multiple aligned lines but want them to share a *single* centered number, you can use the `split` environment (from `amsmath`) *inside* an `equation` environment.

**Markdown Example:**
```latex
\begin{equation} \label{eq:split_example}
\begin{split}
H(X, Y) &= -\sum_{x \in X} \sum_{y \in Y} p(x, y) \log_2 p(x, y) \\
&= H(X) + H(Y|X)
\end{split}
\end{equation}
```
This entire block will get one equation number.

### 4. Explicitly Unnumbered Environments (Starred Versions)

Most `amsmath` environments, like `equation` and `align`, have "starred" versions that are explicitly unnumbered.

**Markdown Examples:**
```latex
\begin{equation*}
\sin^2\theta + \cos^2\theta = 1 
\end{equation*}

\begin{align*}
E &= mc^2 \\
F &= ma
\end{align*}
```
None of these equations will be numbered.

## Inline Math

For mathematical expressions that appear within a line of text, use single dollar signs `$ ... $` or backslashes with parentheses `\( ... \)`.

**Markdown Example:**
```markdown
The famous equation is $E = mc^2$. Another way to write it is \(E = mc^2\).
Greek letters like $\alpha$, $\beta$, and $\gamma$ are also written inline.
```

## Other Supported Environments

The `mdtexpdf` template includes several common LaTeX packages, enabling additional environments:

*   **Matrices**: As shown above, `\begin{pmatrix} ... \end{pmatrix}` (and other matrix types like `bmatrix`, `vmatrix`) can be used within `$$...$$` or other math environments.
*   **Theorems and Proofs**: The `amsthm` package is included.
    ```latex
    \begin{theorem} \label{thm:pythagoras}
    For a right triangle with sides $a$, $b$ and hypotenuse $c$:
    $$a^2 + b^2 = c^2$$
    \end{theorem}

    \begin{proof}
    This is a proof of the Pythagorean theorem. (See @thm:pythagoras).
    \end{proof}
    ```
*   **Chemical Equations**: The `mhchem` package allows for easy typesetting of chemical formulas.
    ```latex
    $$\ce{H2O + CO2 -> H2CO3}$$
    ```

## Best Practices for LaTeX Math in Markdown

1.  **Clarity**: Keep your LaTeX math source readable in the Markdown file. Add comments in your Markdown if the LaTeX is complex (though these comments won't appear in the PDF).
2.  **Choose Correct Environments**:
    *   Use `$$...$$` or starred environments (`equation*`, `align*`) for display math that doesn't need referencing.
    *   Use `equation` for single, important, numbered equations.
    *   Use `align` for multi-line derivations where each step might be important or referenced. Use `split` within `equation` for multi-line equations that should share a single number.
3.  **Labeling and Referencing**:
    *   Use `\label{type:descriptor}` for any numbered item you want to reference (e.g., `\label{eq:energy_mass}`, `\label{thm:main_result}`).
    *   Pandoc allows cross-referencing using the syntax `@type:descriptor` (e.g., `As shown in @eq:energy_mass...`). This works for equations, theorems, figures, sections, etc.
4.  **Package Awareness**:
    *   The `mdtexpdf` script includes `amsmath`, `amssymb`, `amsthm`, and `mhchem` by default, covering most common math and scientific typesetting needs.
    *   If you need functionality from a LaTeX package not included in the default `template.tex` generated by `mdtexpdf`, you might need to customize your local `template.tex` file and ensure the package is part of your LaTeX distribution.
5.  **Test Your Output**: Always compile your Markdown to PDF to check that your LaTeX math is rendered as expected. Complex LaTeX can sometimes have subtle errors that only appear in the final output.
6.  **Pandoc's Math Processing**: Be aware that Pandoc parses your Markdown and then converts it to LaTeX. For simple math, it usually does a direct translation. For more complex structures, it relies on these explicit LaTeX environments. Using standard LaTeX environments directly in your Markdown (as shown above) gives you the most control.

This guide should help you effectively use LaTeX math within your Markdown documents processed by `mdtexpdf`.