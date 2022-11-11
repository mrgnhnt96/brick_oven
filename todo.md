# TODO

- [ ] ? Add support for variables in brick.yaml file
  - [ ] ? Allow override of variable properties

- [ ] rename `value` to `change_to` for files & dirs
- [ ] Look into changing the format from {{#format}}NAME{{/format}} to {{NAME.toFormat()}}
- [ ] Make sure line breaks match the original file
- [x] Warn when a variable is not used
- [ ] Change default behavior for escaped variables?
  - [ ] Currently when formatted, the variable is escaped, I don't know if this is the best behavior or if we should introduce an option to NOT escape the variable
- [x] Add support for partials
  - Requirements
    - [x] Should be an array on a brick
    - [x] require unique file names
    - [x] Allow variables
    - [x] Do NOT allow name
    - [x] Get generated to root of project
      - This is because mason does not support partials being generated in a subdirectory
    - [x] Check for duplicate partials
    - [x] Check for unused partials
    - [ ] ~~Check for non existing referenced partials~~
    - [x] variables in files should replace whole line
    - [x] Allow variable (within file) names to be
      - [x] file name
        - [x] with ext
        - [x] without ext
