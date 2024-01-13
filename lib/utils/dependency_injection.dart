import 'package:get_it/get_it.dart';

/// The dependency injection container
late GetIt di;

/// sets up the dependency injection container
void setupDi() => di = GetIt.asNewInstance();
