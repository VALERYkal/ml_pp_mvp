// Minimal workflow states for CDR. Add-only; do not wire yet.
enum CdrEtat {
  planifie,   // created/planned
  enCours,    // in progress / en route
  termine,    // completed/closed
  annule,     // canceled
}

extension CdrEtatTransitions on CdrEtat {
  static const _allowed = <CdrEtat, Set<CdrEtat>>{
    CdrEtat.planifie: {CdrEtat.enCours, CdrEtat.annule},
    CdrEtat.enCours:  {CdrEtat.termine, CdrEtat.annule},
    CdrEtat.termine:  <CdrEtat>{},
    CdrEtat.annule:   <CdrEtat>{},
  };

  bool canTransitionTo(CdrEtat to) => _allowed[this]?.contains(to) ?? false;
}
