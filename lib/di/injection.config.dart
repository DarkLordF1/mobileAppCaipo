// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../core/network/network_service.dart' as _i476;
import '../core/utils/logger.dart' as _i503;
import '../presentation/providers/theme_provider.dart' as _i983;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.lazySingleton<_i476.NetworkService>(() => _i476.NetworkService());
    gh.lazySingleton<_i503.LoggerService>(() => _i503.LoggerService());
    gh.singleton<_i983.ThemeProvider>(() => _i983.ThemeProvider(
        gh<_i460.SharedPreferences>(instanceName: 'sharedPreferences')));
    return this;
  }
}
