part '{{#snakeCase}}some_prefix_{{{masonry}}}_some_suffix{{/snakeCase}}.dart';

class {{#pascalCase}}some_prefix_{{{masonry}}}_some_suffix{{/pascalCase}} {
  const {{#pascalCase}}some_prefix_{{{masonry}}}_some_suffix{{/pascalCase}}({
    required this.name,
    required this.value,
  });

  const {{#pascalCase}}some_prefix_{{{masonry}}}_some_suffix{{/pascalCase}}._private()
      : name = '',
        value = '';

  final String name;
  final String value;
}
