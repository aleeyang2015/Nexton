/// Where a filed time-correction request stands in its approval.
enum TimeCorrectionStatus {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),

  /// Withdrawn by the employee (`PUT …/correction-requests/:id/cancel`).
  cancelled('cancelled');

  const TimeCorrectionStatus(this.wireValue);

  /// The literal the API uses for this status.
  final String wireValue;
}
