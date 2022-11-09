# TODO

- [ ] ? Add support for variables in brick.yaml file
  - [ ] ? Allow override of variable properties

- [ ] rename `value` to `change_to` for files & dirs
- [ ] Look into changing the format from {{#format}}NAME{{/format}} to {{NAME.toFormat()}}
- [ ] Make sure line breaks match the original file
- [ ] Warn when a variable is not used
- [ ] Change default behavior for escaped variables?
  - [ ] Currently when formatted, the variable is escaped, I don't know if this is the best behavior or if we should introduce an option to NOT escape the variable
- [ ] Add support for partials
  - Requirements
    - [ ] Should be an array on a brick
    - [ ] Allow variables
    - [ ] Do NOT allow name
    - [ ] Get generated to root of project
      - This is because mason does not support partials being generated in a subdirectory
    - [ ] Check for duplicate partials
    - [ ] Check for unused partials
    - [ ] Check for non existing referenced partials
    - [ ] variables in files should replace whole line
    - [ ] Allow variable names to be
      - [ ] file name
        - [ ] with ext
        - [ ] without ext
