import 'package:cloud_firestore/cloud_firestore.dart';

/// Small helpers for reading Firestore data safely. A missing or wrongly
/// typed field never crashes the app; it falls back to a default.

DateTime? readDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

/// Server timestamps are briefly null while a write is still being sent,
/// so "now" is the sensible stand-in.
DateTime readDateOrNow(dynamic value) => readDate(value) ?? DateTime.now();

Timestamp? writeDate(DateTime? value) =>
    value == null ? null : Timestamp.fromDate(value);

String readString(dynamic value, [String fallback = '']) =>
    value is String ? value : fallback;

String? readOptionalString(dynamic value) =>
    value is String && value.trim().isNotEmpty ? value : null;

num readNum(dynamic value, [num fallback = 0]) => value is num ? value : fallback;

int readInt(dynamic value, [int fallback = 0]) =>
    value is num ? value.toInt() : fallback;

bool readBool(dynamic value, [bool fallback = false]) =>
    value is bool ? value : fallback;

List<String> readStringList(dynamic value) =>
    value is List ? value.whereType<String>().toList() : <String>[];
