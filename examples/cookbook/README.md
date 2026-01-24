# Cookbook Example

This example demonstrates how to create a cookbook/recipe book with:

- Recipe format with prep/cook times
- Ingredient lists
- Step-by-step instructions
- Chef's tips in blockquotes
- Tables for variations and reference info
- Clear section organization

## Build

```bash
# PDF
mdtexpdf convert cookbook.md --read-metadata

# EPUB (for kitchen tablets)
mdtexpdf convert cookbook.md --read-metadata --epub
```

## Features Demonstrated

- `format: "book"` - Book format
- `section_numbers: false` - No numbered sections
- Recipe cards with metadata (prep time, cook time, servings)
- Ingredient lists using bullet points
- Numbered instruction steps
- Blockquotes for tips
- Tables for variations and reference data
- Horizontal rules for visual separation
- Simple index

## Recipe Format Template

Use this structure for consistent recipes:

```markdown
## Recipe Name

*Prep: X min | Cook: Y min | Serves: N*

Brief description of the dish.

### Ingredients

- Ingredient 1
- Ingredient 2
- ...

### Instructions

1. First step
2. Second step
3. ...

> **Chef's Tip**: Helpful advice here.
```

## Adding Photos

To add food photography, create an `img/` folder:

```
cookbook/
├── cookbook.md
├── img/
│   ├── french-toast.jpg
│   ├── pasta.jpg
│   └── brownie.jpg
```

Then reference in your markdown:

```markdown
![French Toast](img/french-toast.jpg)
```

## Tips for Cookbook Authors

1. **Be specific**: "Medium heat" is better than "heat"
2. **Include timing**: "Sauté for 3 minutes" not "sauté until done"
3. **Explain why**: Tips help readers understand technique
4. **Use tables**: Great for variations, substitutions, conversions
5. **Test recipes**: Always cook the dish before publishing!
