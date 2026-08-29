import 'package:equatable/equatable.dart';

abstract class DirectionEvent extends Equatable {
  const DirectionEvent();

  @override
  List<Object?> get props => [];
}

class FetchDirections extends DirectionEvent {
  final String origin;
  final String destination;

  const FetchDirections({required this.origin, required this.destination});

  @override
  List<Object?> get props => [origin, destination];
}
