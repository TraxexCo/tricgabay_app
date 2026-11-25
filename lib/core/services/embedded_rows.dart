/// The rows of a table embedded in a PostgREST response, as a list.
///
/// PostgREST returns an embedded table as a JSON array when the relationship is
/// one-to-many, but as a single object (or null when there is none) when it is
/// one-to-one or many-to-one, which is the case when the foreign key is also the
/// primary key or is unique. `booking_reviews.booking_id` is its table's primary
/// key, so a booking's review arrives as `{"rating": 5, "review": "..."}` or
/// `null`, never as `[...]`. Reading it with `as List?` threw, and the booking
/// was then dropped from the list without a trace.
///
/// Accepts a list, a single map, or null (no rows). Any other shape is a real
/// contract change, so it throws instead of quietly reading as "no rows".
List<Map<String, dynamic>> embeddedRows(Object? value) {
  if (value == null) return const [];
  if (value is Map) return [Map<String, dynamic>.from(value)];
  if (value is List) {
    return [
      for (final item in value)
        if (item is Map)
          Map<String, dynamic>.from(item)
        else
          throw FormatException(
            'Embedded row is ${item.runtimeType}, expected an object',
          ),
    ];
  }
  throw FormatException(
    'Embedded rows are ${value.runtimeType}, expected a list, an object or null',
  );
}
