/// The backend (Django DateField) expects/returns 'YYYY-MM-DD' - used only
/// for API request/response bodies, never for anything shown on screen.
String toApiDateString(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

/// 'DD-MM-YYYY' - used for every date shown to the user.
String toDisplayDateString(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year.toString().padLeft(4, '0')}';
}

/// Converts an ISO 'YYYY-MM-DD' string (as returned by the API) straight to
/// 'DD-MM-YYYY' for display, without a DateTime round-trip at call sites.
String isoToDisplayDateString(String isoDate) {
  return toDisplayDateString(DateTime.parse(isoDate));
}
