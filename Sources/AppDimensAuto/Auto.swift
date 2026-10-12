@_exported import AppDimens

/// Android `DimenAuto` — conditional AUTO builder (`16.autoDp().screen(...)`).
/// Same priority rules as every AppDimens builder; terminal resolution uses the
/// AUTO kernel (linear up to 480 pt, logarithmic beyond).
public typealias DimenAuto = DimenBuilder
