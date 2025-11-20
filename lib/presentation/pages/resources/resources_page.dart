// lib/presentation/pages/resources/resources_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/presentation/blocs/resources/resources_bloc.dart';
import 'package:hivmeet/core/services/localization_service.dart';
import 'package:hivmeet/injection.dart';

class ResourcesPage extends StatelessWidget {
  const ResourcesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          getIt<ResourcesBloc>()..add(LoadResources('default')),
      child: Scaffold(
        appBar: AppBar(
            title: Text(LocalizationService.translate('resources.title'))),
        body: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                  hintText: LocalizationService.translate('search')),
              onChanged: (query) =>
                  context.read<ResourcesBloc>().add(SearchResources(query)),
            ),
            Expanded(
              child: BlocBuilder<ResourcesBloc, ResourcesState>(
                builder: (context, state) {
                  if (state is ResourcesLoading) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (state is ResourcesError) {
                    return Center(child: Text(state.message));
                  }
                  if (state is ResourcesLoaded) {
                    return ListView.builder(
                      itemCount: state.resources.length,
                      itemBuilder: (context, index) {
                        final resource = state.resources[index];
                        return ListTile(
                          title: Text(resource.title),
                          subtitle: Text(resource.category),
                          trailing: IconButton(
                            icon: Icon(Icons.favorite_border),
                            onPressed: () => context
                                .read<ResourcesBloc>()
                                .add(AddFavorite(resource.id)),
                          ),
                          onTap: () {},
                        );
                      },
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
