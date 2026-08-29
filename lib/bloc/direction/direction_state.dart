import 'package:equatable/equatable.dart';

abstract class DirectionState extends Equatable {
  const DirectionState();

  @override
  List<Object?> get props => [];
}

class DirectionInitial extends DirectionState {}

class DirectionLoading extends DirectionState {}

class DirectionLoaded extends DirectionState {
  final Map<String, dynamic> data; // mock route data
  const DirectionLoaded({required this.data});

  @override
  List<Object?> get props => [data];
}

class DirectionError extends DirectionState {
  final String message;
  const DirectionError(this.message);

  @override
  List<Object?> get props => [message];
}
