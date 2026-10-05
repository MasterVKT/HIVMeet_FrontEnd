import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hivmeet/injection.dart';
import 'package:hivmeet/presentation/blocs/interaction_history/interaction_history_bloc.dart';
import 'package:hivmeet/presentation/pages/interaction_history/interaction_history_list_page.dart';

class MyLikesPage extends StatelessWidget {
  const MyLikesPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt<InteractionHistoryBloc>(),
        child: const InteractionHistoryListPage(isLike: true),
      );
}
