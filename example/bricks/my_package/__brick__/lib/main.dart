// this has been created

part '{{#snakeCase}}SomePrefix{{masonry}}SomeSuffix{{/snakeCase}}.dart';

class {{#pascalCase}}SomePrefix{{masonry}}SomeSuffix{{/pascalCase}} {
  const {{#pascalCase}}SomePrefix{{masonry}}SomeSuffix{{/pascalCase}}({
    required this.name,
    required this.value,
  });

  const {{#pascalCase}}SomePrefix{{masonry}}SomeSuffix{{/pascalCase}}._private()
      : name = '',
        value = '';

  final String name;
  final String value;
  // @list
}
