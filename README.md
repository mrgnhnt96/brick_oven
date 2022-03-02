<p align="center">
<h1 align="center">Brick Oven</h1>
<h3 align="center">Easily create & format brick templates with the brick_oven cli generator for mason</h3>
</p>

<p align="center">
<a href="https://codecov.io/gh/mrgnhnt96/brick_oven"><img src="https://codecov.io/gh/mrgnhnt96/brick_oven/branch/main/graph/badge.svg?token=NKBRVVE7EG"/></a>
<a href="https://pub.dev/packages/brick_oven"><img src="https://img.shields.io/pub/v/brick_oven.svg" ></a>
<a href="https://github.com/mrgnhnt96/brick_oven"><img src="https://img.shields.io/github/stars/mrgnhnt96/brick_oven.svg?style=flat&logo=github&colorB=deeppink&label=stars" ></a>
<a href="https://pub.dev/packages/very_good_analysis"><img src="https://img.shields.io/badge/style-very_good_analysis-B22C89.svg" ></a>
<a href="https://github.com/tenhobi/effective_dart"><img src="https://img.shields.io/badge/style-effective_dart-40c4ff.svg" ></a>
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-blue.svg" ></a>
</p>

Brick Oven is essentially a "Search & Replace" tool on steroids. It is for cooking (generating) and formatting brick templates for [mason].

# Quick Start

```bash
# 🎯 Activate from https://pub.dev
dart pub global activate brick_oven

# 🔨 Create & configure the `brick_oven.yaml` file

# 🎛 cook your bricks 🧱
brick_oven cook all
```

# Cook'n Bricks! 👨‍🍳

Cooks up a brick template for each configured brick within the `brick_oven.yaml` file.

There are two main commands to cook your bricks:

```bash
# Cooks all bricks
brick_oven cook all

# Cooks a specific brick
brick_oven cook <your_brick>
```

# brick_oven.yaml Configuration

```yaml
bricks:
  <brick_name>:
    source: <path_to_source_files>
    exclude:
      - <path_to_excluded_file_or_dir> # optional
    dirs: <replacement_name> # optional
      <path_to_dir>: <replacement_name> # optional
        name: <replacement_name> # optional
          value: <replacement_name>
          format: <format> #optional
          prefix: <prefix> # optional
          suffix: <suffix> # optional
    files: # optional
      <path_to_file>:
        name: <replacement_name> # optional
          value: <replacement_name>
          format: <format> #optional
          prefix: <prefix> # optional
          suffix: <suffix> # optional
        vars:
          <var_name>: <placeholder_name> # optional (value)
```

## brick_oven.yaml fields

In general, **paths are relative** to the directory of the brick_oven.yaml file

- **bricks**: Bricks that will be "cooked" 👨‍🍳

  - **\<brick_name\>**: The name of the brick. This will be used as the name of the top level directory for this brick template.

  - **source**: The path to the source files, should point to a directory. Supports only local paths.

  - **exclude**: Paths to exclude from the source directory. Can point to files or directories.

  - **dirs**: Directory paths that will be formatted to mustache syntax.

    - **\<path_to_dir\>**: Must point to a _directory_. Will be replaced with the `name` value, if provided.
      - **name**: The name that will replace the directory's current name.
        - **value**: \*\*same as name\*\*
        - **format**: wraps the name with the provided format.
        - **prefix**: Will be prepended to the name (before mustache formatting).
        - **suffix**: Will be appended to the name (after mustache formatting).

  - **files**: A list of file paths that will be formatted (path and/or contents) to mustache syntax.
    - **\<path_to_file\>**: Must point to a _file_. Will be replaced with the `name` value, if provided.
      - **name**: The name that will format the file's current name.
        - **value**: \*\*same as name\*\*
        - **format**: wraps the name with the provided format.
        - **prefix**: Will be prepended to the name (before mustache formatting).
        - **suffix**: Will be appended to the name (after mustache formatting).
      - **vars**: Variables found within the contents of the file to be formatted to mustache syntax.
        - **\<var_name\>**: (**Case sensitive**) The name of the variable. If provided, the variable will be replaced with `placeholder`'s value.
          - **placeholder**: (**Case sensitive**) The name of the placeholder that can be found within the contents of the file. (Assumes `<var_name>` if not provided)
          - **prefix**: Will be prepended to the name (before mustache formatting).
          - **suffix**: Will be appended to the name (after mustache formatting).

**_Note for formats and subdirectory variables_**: When the name is formatted (to snake_case for example), all subdirectories will be converted **to the name of the dir/file**. which may be undesirable. `{{#snakeCase}}{{{path}}}{{/snakeCase}}` with `path='some/path/to/dir'` will result in `some_path_to_dir`.

# Content Configuration

This is where brick_oven really shines! Because it is a "Search & Replace" tool, you're able to format the "placeholders" within the contents of a file however you'd like. This is in the hopes that a random piece of content doesn't get formatted unintentionally.

**_Note for variable names_**: Because brick_oven is a "Search & Replace" tool, it will replace ALL found occurrences. The var `name` is found in `rename, name, something_name`. To avoid this, its recommended to set up your placeholders with a prefix and/or suffix (such as "`_`") and some sort of case formatting (such as UPPERCASE). Example: `_NAME_`.

**_Note for placholder replacements_**: The order of replacing placeholders with their mustache sytax formatted values is: `loops`, `sections`, followed by `vars`. Which means that you can have a looped/sectioned variable (`_NAMES_`) and a general variable (`_NAME_`) without conflict.

## Loops

`var: _FOO_`

| Syntax | Example | Output | Description |
| --- | --- | --- | --- |
| start* | start_FOO_ | {{#\_FOO_}} | The start of a loop |
| end* | end_FOO_ | {{/\_FOO_}} | The end of a loop |
| nstart* | nstart_FOO_ | {{^\_FOO_}} | The start of an **inverted** loop |

**Note**: Loops consume the **entire** contents of the **line**. Make sure that they are on _their own line._\
**Note**: Loops do not get [formatted](#case-formatting). So don't try to format them...

## Sections

| Syntax | Example | Output | Description |
| --- | --- | --- | --- |
| s* | s_FOO_ | {{#\_FOO_}} | Start of a section |
| e* | e_FOO_ | {{/\_FOO_}} | End of a section |
| n* | n_FOO_ | {{^\_FOO_}} | Inverts the section |

## Case Formatting

Case Formatting Syntax is **not** case sensitive. Use this to your advantage! Especially when you have repeated objects are conditionally formatted and the linter is yelling at you saying, "you already have `foo`, you can't have another!" 🙄

| Syntax | Example | Output |  Description |
| --- | --- | --- | --- |
| *snake OR \*snakecase| _FOO_snake OR _FOO_snakecase | {{#snakeCase}}{{\_FOO_}}{{/snakeCase}} | Wraps the variable with mustache syntax of the provided case |

Available Formats

- camel
- constant
- dot
- header
- lower
- pascal
- param
- path
- sentence
- snake
- title
- upper

## Prefixes & Suffixes

`prefix: bar_`\
`suffix: _bar`

| Fix | Syntax | Example | Description |
| --- | --- | --- | --- |
| prefix | (any) | bar__FOO_ | Must be before loops/sections const (ex: `bar_start_FOO_`) |
| suffix | (any) | _FOO__bar | Must be after case format (ex: `_FOO_snake_bar`) |

## Basic Example

```yaml
# brick_oven.yaml

bricks:
  example:
    source: .
    files:
      lib/main:
        vars:
          names: _NAMES_
          name: _NAME_
          emoji: _EMOJI_
          import: _IMPORT_
```

```dart
// lib/main.dart

import '_IMPORT_snake.dart';

void main(){
  // start_NAMES_
  print('Hello _NAME_upper! s_EMOJI_ 😎 e_EMOJI_');
  // end_NAMES_

  // nstart_NAMES_
  print("There's no one to greet! 😭");
  // end_NAMES_
}
```

output:

```dart
// bricks/example/__bricks__/lib/main.dart

import '{{#snakeCase}}{{import}}{{/snakeCase}}.dart';

void main(){
  {{#names}}
  print('Hello {{#upperCase}}{{name}}{{/upperCase}}! {{#emoji}} 😎 {{/emoji}}');
  {{/names}}

  {{^names}}
  print("There's no one to greet! 😭");
  {{/names}}
}
```

[mason]: https://pub.dev/packages/mason
