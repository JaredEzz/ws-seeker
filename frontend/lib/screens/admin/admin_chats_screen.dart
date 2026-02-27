import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/all_chats/all_chats_bloc.dart';
import '../../repositories/order_repository.dart';
import '../../widgets/navigation/admin_shell.dart';
import '../chats/all_chats_screen.dart';

class AdminChatsScreen extends StatelessWidget {
  const AdminChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AllChatsBloc(
        orderRepository: context.read<OrderRepository>(),
      )..add(const AllChatsFetchRequested()),
      child: const AdminShell(
        selectedIndex: 4,
        child: AllChatsContent(),
      ),
    );
  }
}
