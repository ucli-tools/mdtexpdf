# LaTeX Math in Markdown

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

# Code Examples in Different Programming Languages

## Python
Python is known for its simplicity and readability. Below is a basic "Hello, World!" example:

```python
print("Hello, World!")
```

JavaScript is a versatile language used for web development. Here's a function example:

## JavaScript
```javascript
function greet() {
  console.log("Hello, World!");
}
greet();
```

Java's object-oriented approach is fundamental in enterprise environments. A simple Java program:

## Java
```java
public class HelloWorld {
  public static void main(String[] args) {
    System.out.println("Hello, World!");
  }
}
```

C++ offers high performance and is used in system programming. A basic C++ example:

## C++
```cpp
#include <iostream>
int main() {
  std::cout << "Hello, World!" << std::endl;
  return 0;
}
```

Ruby emphasizes simplicity and productivity. A Ruby script looks like this:

## Ruby
```ruby
puts "Hello, World!"
```

Go (Golang) is designed for efficient concurrency. Here's a simple Go program:

## Go
```go
package main
import "fmt"
func main() {
  fmt.Println("Hello, World!")
}
```

PHP is widely used for server-side web development. A basic PHP script:

## PHP
```php
<?php
echo "Hello, World!";
?>
```

Swift is Apple's language for iOS/macOS development. A Swift example:

## Swift
```swift
print("Hello, World!")
```

Kotlin is a modern language for Android development, interoperable with Java. Example:

## Kotlin
```kotlin
fun main() {
  println("Hello, World!")
}
```

Rust focuses on memory safety without sacrificing performance. A Rust example:

## Rust
```rust
fn main() {
  println!("Hello, World!");
}
```
