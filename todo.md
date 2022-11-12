# TODO

<!-- ?? -->
- [ ] Add support for variables in brick.yaml file
  - [ ] Allow override of variable properties
- [ ] Configure provide match pattern for sections, variables, and partials

- [ ] look up transpiler vs generator

- [ ] Change default behavior for escaped variables?
  - Currently when formatted, the variable is escaped, I don't know if this is the best behavior or if we should introduce an option to NOT escape the variable

## BUGS

- [ ] Make sure line breaks match the original file
- [ ] write test for if variable is wrapped in {}
  - check logger for warning

## FEATURES

- [ ] Possible unconverted variables within files
  - [ ] get all variables and check in files with all variables
- [ ] Add flag to sync or not
- [ ] add mixpanel analytics

<!-- FUTURE -->
- [ ] Look into changing the format from {{#format}}NAME{{/format}} to {{NAME.toFormat()}}
