---
title: "Test Long Equations"
author: "mdtexpdf QA"
---

# Long equation wrapping test

This test verifies that the `long_equation_filter.lua` activates for multi-assignment display math, avoids splitting at commas inside `\left...\right` or `\begin...\end`, and formats the output using `dmath*` with `aligned` lines.

$$
\left[ \sigma_x, \sigma_y \right] = 2 i \, \sigma_z,\quad
U = \begin{pmatrix} \alpha & \beta \\ \gamma & \delta \end{pmatrix} \circ \begin{pmatrix} a & b \\ c & d \end{pmatrix},\quad
\mathbf{v}_1 = \left( v_{11}, v_{12}, v_{13} \right),\quad
\mathbf{v}_2 = \left( v_{21}, v_{22}, v_{23} \right),\quad
\mathbf{M} = \left( \begin{array}{ccc} m_{11} & m_{12} & m_{13} \\ m_{21} & m_{22} & m_{23} \\ m_{31} & m_{32} & m_{33} \end{array} \right)
$$

Additional long single-line equation to test length trigger:

$$
\underbrace{\left( a_1 + a_2 + a_3 + a_4 + a_5 + a_6 + a_7 + a_8 + a_9 + a_{10} + a_{11} + a_{12} + a_{13} + a_{14} + a_{15} + a_{16} + a_{17} + a_{18} + a_{19} + a_{20} \right)}_{\text{a very long sum intended to exceed the length threshold}} = \underbrace{\left( b_1 + b_2 + b_3 + b_4 + b_5 + b_6 + b_7 + b_8 + b_9 + b_{10} + b_{11} + b_{12} + b_{13} + b_{14} + b_{15} + b_{16} + b_{17} + b_{18} + b_{19} + b_{20} \right)}_{\text{another very long sum}}
$$
