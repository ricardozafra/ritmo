enum Pillar { morning, day, night }

/// Projeção mínima da conclusão ordinária dos três pilares.
final class PillarStatus {
  const PillarStatus({
    required this.morningCompleted,
    required this.dayCompleted,
    required this.nightCompleted,
  });

  final bool morningCompleted;
  final bool dayCompleted;
  final bool nightCompleted;

  Set<Pillar> get incompletePillars => {
    if (!morningCompleted) Pillar.morning,
    if (!dayCompleted) Pillar.day,
    if (!nightCompleted) Pillar.night,
  };
}

/// Projeção da única dispensa ativa relevante para o selo.
final class PillarWaiver {
  const PillarWaiver({required this.pillar});

  final Pillar pillar;
}

/// RF-02.2, RF-02.3, RF-02.7 e RF-02.8.
bool sealEligible(PillarStatus status, PillarWaiver? activeWaiver) {
  final incomplete = status.incompletePillars;
  if (incomplete.isEmpty) return true;
  if (incomplete.length > 1) return false;
  return activeWaiver?.pillar == incomplete.single;
}

Set<Pillar> uncoveredIncompletePillars(
  PillarStatus status,
  PillarWaiver? activeWaiver,
) => status.incompletePillars
    .where((pillar) => pillar != activeWaiver?.pillar)
    .toSet();
