<p align="center">
<h1 align="center">Brick Oven</h1>
<h3 align="center">Easily create & format brick templates with the brick_oven cli generator for mason</h3>
</p>

<p align="center">
<a href="https://codecov.io/gh/mrgnhnt96/brick_oven" > 
 <img src="https://codecov.io/gh/mrgnhnt96/brick_oven/branch/master/graph/badge.svg?token=9RR6GYSEUC"/> 
 </a>
<a href="https://pub.dev/packages/brick_oven"><img src="https://img.shields.io/pub/v/brick_oven.svg" ></a>
<a href="https://github.com/mrgnhnt96/brick_oven"><img src="https://img.shields.io/github/stars/mrgnhnt96/brick_oven.svg?style=flat&logo=github&colorB=yellow&label=stars" ></a>
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
brick_oven cook YOUR_BRICK_NAME
```

# brick_oven.yaml Configuration

```yaml
# CONSTANT_CASE == user input

bricks:
  BRICK_NAME:
    source: PATH_TO_SOURCE_DIR
    brick_config: PATH_TO_BRICK.YAML_FILE
    exclude:
      - PATH_TO_DIR_OR_FILE
    dirs:
      PATH_TO_DIR:
        name:
          value: NAME_OF_VARIABLE
          format:
          prefix:
          suffix:
          section: NAME_OF_VARIABLE
          inverted_section: NAME_OF_VARIABLE
          braces: NUMBER_OF_BRACES
        include_if: NAME_OF_VARIABLE
        include_if_not: NAME_OF_VARIABLE
    files:
      PATH_TO_FILE:
        name:
          value: NAME_OF_VARIABLE
          format:
          prefix:
          suffix:
          section: NAME_OF_VARIABLE
          inverted_section: NAME_OF_VARIABLE
          braces: NUMBER_OF_BRACES
        include_if: NAME_OF_VARIABLE
        include_if_not: NAME_OF_VARIABLE
        vars:
          NAME_OF_VARIABLE: PLACEHOLDER
    partials:
      PATH_TO_PARTIAL:
        vars:
          NAME_OF_VARIABLE: PLACEHOLDER
    urls:
      PATH_TO_FILE:
        name:
          value: NAME_OF_VARIABLE
          format:
          prefix:
          suffix:
          section: NAME_OF_VARIABLE
          inverted_section: NAME_OF_VARIABLE
          braces: NUMBER_OF_BRACES
        include_if: NAME_OF_VARIABLE
        include_if_not: NAME_OF_VARIABLE
```

## Fields

**Paths are relative** to the directory of the brick_oven.yaml file

- **BRICK_NAME**: The name of the brick. Will be used as the name of the directory that the brick will be generated in. Generally matches the name provided in the `brick.yaml` file

  - **source**: The local directory to process
  - **exclude**: Excluding a directory/file (from the _source_) prevents brick_oven from processing it and including it in the output.
  - **brick_config**: The path to the `brick.yaml` file. This is an optional value. When provided, brick_oven will compare the configurations between `brick_oven.yaml` and `brick.yaml`. When the two are out of sync, a detailed warning will be displayed in the console to help re-sync

  - **dirs**:
    - **PATH_TO_DIR**: Must point to a _directory_. Will be replaced with the formatted `name` value, if provided
      - **name**:
        - **value**: The name that will replace the directory's current name
        - **format**: Wraps the name with the provided format
        - **braces**: The numbers of braces to wrap the name
          - Should be either 2 or 3
            - 2: `{{name}}` = non-escaped characters
            - 3: `{{{name}}}` = escaped characters
        - **prefix**: Prepends to the name (before mustache formatting)
        - **suffix**: Appends to the name (after mustache formatting)
        - **section**: Wraps the name with a section (lambda). Loops over the variable's (iterable) values when the value is truthy
        - **inverted_section**: Wraps the name with an inverted section (lambda). Loops over the variable's (iterable) values when the value is falsy
      - **include_if**: Wraps the directory with a section. The section will only be included if the provided variable is truthy
      - **include_if_not**: Wraps the directory with an inverted section. The section will only be included if the provided variable is falsy

  - **files**:
    - **PATH_TO_FILE**: Must point to a _file_
      - **name**: When provided, the file's name will be replaced with the `name` configuration
        - **value**: The name that will replace the directory's current name
        - **format**: Wraps the name with the provided format
        - **braces**: The numbers of braces to wrap the name
          - Should be either 2 or 3
            - 2: `{{name}}` = non-escaped characters
            - 3: `{{{name}}}` = escaped characters
        - **prefix**: Prepends to the name (before mustache formatting)
        - **suffix**: Appends to the name (after mustache formatting)
        - **section**: Wraps the name with a section (lambda)
        - **inverted_section**: Wraps the name with an inverted section (lambda)

      - **include_if**: Wraps the directory with a section. The section will only be included if the provided variable is truthy
      - **include_if_not**: Wraps the directory with an inverted section. The section will only be included if the provided variable is falsy

      - **vars**: Variables found within the contents of the file to be formatted to mustache syntax
        - **NAME_OF_VARIABLE**: The name of the variable that will be replace the placeholder. generally matches the variable name provided in the `brick.yaml` file
          - **PLACEHOLDER**: The value that is to be found within the file, (assumes `NAME_OF_VARIABLE` if not provided). This value will be replaced with the `NAME_OF_VARIABLE` value

  - **partials**:
    - **vars**: Variables found within the contents of the file to be formatted to mustache syntax
      - **NAME_OF_VARIABLE**: The name of the variable that will be replace the placeholder. generally matches the variable name provided in the `brick.yaml` file
        - **PLACEHOLDER**: The value that is to be found within the file, (assumes `NAME_OF_VARIABLE` if not provided). This value will be replaced with the `NAME_OF_VARIABLE` value

  - **urls**:
    - **name**:
      - **value**: The name that will replace the directory's current name
      - **format**: Wraps the name with the provided format
      - **braces**: The numbers of braces to wrap the name
        - Should be either 2 or 3
          - 2: `{{name}}` = non-escaped characters
          - 3: `{{{name}}}` = escaped characters
      - **prefix**: Prepends to the name (before mustache formatting)
      - **suffix**: Appends to the name (after mustache formatting)
      - **section**: Wraps the name with a section (lambda)
      - **inverted_section**: Wraps the name with an inverted section (lambda)

    - **include_if**: Wraps the directory with a section. The section will only be included if the provided variable is truthy
    - **include_if_not**: Wraps the directory with an inverted section. The section will only be included if the provided variable is falsy

**_Note for formats and subdirectory variables_**: When the name is formatted (to snake_case for example), all subdirectories will be converted **to the name of the dir/file**. which may be undesirable. `{{#snakeCase}}{{{path}}}{{/snakeCase}}` with `path='some/path/to/dir'` will result in `some_path_to_dir`

# Content Configuration

This is where brick_oven really shines! Because it is a "Search & Replace" tool, you're able to format the "placeholders" within the contents of a file however you'd like.

**Note for output directory**: The default output directory is `bricks`, this value can be manipulated with the `output` argument. The generated content will be placed under `BRICK_NAME/__brick__/`, this value cannot be changed.

**_Note for variable names_**: Because brick_oven is a "Search & Replace" tool, it will replace ALL found occurrences. The var `name` is found in `rename, name, something_name`. To avoid this, its recommended to set up your placeholders with a prefix and/or suffix (such as "`_`") and some sort of case formatting (such as CONSTANT_CASE). Example: `_NAME_`.

**_Note for variable ordering_**: The order of replacing placeholders with their mustache syntax formatted values is: `sections`, `vars`, followed by `partials`. To avoid unintentionally replacing a placeholder with a sub-name (e.g. `NAMES` and `NAME` or `_MY_NAME_` and `_NAME_`), try using multiple placeholders for the same variable, and ordering the variables in the brick_oven.yaml by length (largest to smallest).

## Partials

Partials are a way to reuse a template. brick_oven supports partials nested within folders, however, mason does not [yet](https://github.com/felangel/mason/issues/378). brick_oven handles this by re-locating the partials to the root of the project. This means that all partials _**must have a unique file name.**_

| Syntax | Example | Output |
| --- | --- | --- |
| partials.* | partials.hello_world | {{> hello_world.dart}} |

Accessing partials is by using dot annotation. For example, if you have a partial named `hello_world.dart`, you can access it by using `partials.hello_world` (extension is optional)

## URLs

URLs are empty text files _with no file extension_

## Sections (Lambdas)

| Syntax | Example | Output | Description |
| --- | --- | --- | --- |
| section* | section_FOO_ | {{#\_FOO_}} | The start of a section |
| endSection* | endSection_FOO_ | {{/\_FOO_}} | The end of a section |
| invertSection* | invertSection_FOO_ | {{^\_FOO_}} | The start of an **inverted** section |

**Notes**:

- Sections consume the **entire** line (start to end, only 1 line). This is helpful if you want to comment out a section based on the language's syntax, or add a helpful description after/before the section
- Sections do not get [formatted](#case-formatting). So don't try to format them...
- Sections are **_not_** case sensitive

### Built in Variables

There are some keywords to help get the value at the index when iterating over a list

- **\_INDEX_VALUE_**
- **.** (a single period)

Both have the same output of\
`{{#_FOO_}}{{.}}{{/_FOO_}}`

## Conditional Sections

| Syntax | Example | Output | Description |
| --- | --- | --- | --- |
| *if | _FOO_if | {{#\_FOO_}} | Start of a section |
| *ifNot | _FOO_ifNot | {{^\_FOO_}} | Inverts the section |
| *endIf | _FOO_endIf | {{/\_FOO_}} | End of a section |

**Notes**:

- Conditional sections **_not_** case sensitive

## Case Formatting

[Available formats](https://github.com/felangel/mason/tree/master/packages/mason_cli#built-in-lambdas), Case formatting syntax is **_not_** case sensitive

| Syntax | Example | Output |
| --- | --- | --- |
| *snake, \*snakecase| _FOO_snake, _FOO_snakecase | {{#snakeCase}}{{\_FOO_}}{{/snakeCase}} |
****
