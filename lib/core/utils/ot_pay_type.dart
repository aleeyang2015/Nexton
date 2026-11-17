/// How an overtime piece is paid (the server's `pay_type`).
///
/// Lives in core, not in a feature, because the payslip's OT pieces and the
/// overtime requests both carry it. Pure Dart: domain entities import it.
enum OtPayType {
  /// The pay value is a percent of the hourly pay: 150 is 150 %.
  percent,

  /// The pay value is whole kip per hour: 20000 is 20,000 kip an hour.
  fixedPerHour,

  /// A value the App does not know.
  unknown;

  /// Reads the server's `pay_type`; anything but its two values is
  /// [unknown].
  static OtPayType fromWire(Object? value) => switch (value) {
    'percent' => percent,
    'fixed_per_hour' => fixedPerHour,
    _ => unknown,
  };
}
