import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/realtime/realtime_event.dart';
import 'package:hivmeet/core/realtime/realtime_event_bus.dart';
import 'package:hivmeet/domain/entities/resource.dart';
import 'package:hivmeet/domain/usecases/resources/add_to_favorites.dart';
import 'package:hivmeet/domain/usecases/resources/get_resources.dart';
import 'package:hivmeet/presentation/blocs/resources/resources_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockGetResources extends Mock implements GetResources {}

class MockAddToFavorites extends Mock implements AddToFavorites {}

void main() {
  late MockGetResources getResources;
  late MockAddToFavorites addToFavorites;
  late RealtimeEventBus realtimeBus;
  late ResourcesBloc bloc;

  setUpAll(() {
    registerFallbackValue(GetResourcesParams.initial());
  });

  setUp(() {
    getResources = MockGetResources();
    addToFavorites = MockAddToFavorites();
    realtimeBus = RealtimeEventBus();
    when(() => getResources(any()))
        .thenAnswer((_) async => const Right(<Resource>[]));
    bloc = ResourcesBloc(
      getResources: getResources,
      addToFavorites: addToFavorites,
      realtimeBus: realtimeBus,
    );
  });

  tearDown(() async {
    await bloc.close();
    realtimeBus.dispose();
  });

  test('a confirmed subscription reloads the visible resource catalogue',
      () async {
    bloc.add(const LoadResources('care'));
    await Future<void>.delayed(const Duration(milliseconds: 50));

    realtimeBus.publish(const RealtimeEvent(
      type: RealtimeEventType.subscriptionChanged,
      source: RealtimeSource.local,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 80));

    verify(
      () => getResources(
        const GetResourcesParams(categoryId: 'care'),
      ),
    ).called(2);
  });
}
