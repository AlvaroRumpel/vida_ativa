import 'package:equatable/equatable.dart';
import 'package:vida_ativa/core/models/price_tier_model.dart';

sealed class PricingState extends Equatable {
  const PricingState();
}

class PricingInitial extends PricingState {
  const PricingInitial();

  @override
  List<Object?> get props => [];
}

class PricingLoaded extends PricingState {
  final List<PriceTierModel> tiers;

  const PricingLoaded(this.tiers);

  @override
  List<Object?> get props => [tiers];
}

class PricingError extends PricingState {
  final String message;

  const PricingError(this.message);

  @override
  List<Object?> get props => [message];
}
