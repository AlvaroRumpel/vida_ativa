import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class BlockedDateModel extends Equatable {
  final String date; // "YYYY-MM-DD" format, also used as document ID
  final String createdBy; // UID of admin who created the block

  const BlockedDateModel({
    required this.date,
    required this.createdBy,
  });

  factory BlockedDateModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return BlockedDateModel(
      date: doc.id, // Document ID IS the date
      createdBy: data['createdBy'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date, // Redundant with doc ID but aids serialization
      'createdBy': createdBy,
    };
  }

  @override
  List<Object?> get props => [date, createdBy];
}
