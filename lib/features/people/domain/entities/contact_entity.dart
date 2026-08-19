class ContactEntity {
  final String id;
  final String fullName;
  final String? nickname;
  final String? profilePicture;
  final bool isFavorite;
  final double totalOwedToUser;
  final double totalUserOwes;
  final String updatedAt;
  final List<dynamic>? debts;

  const ContactEntity({
    required this.id,
    required this.fullName,
    this.nickname,
    this.profilePicture,
    required this.isFavorite,
    required this.totalOwedToUser,
    required this.totalUserOwes,
    required this.updatedAt,
    this.debts,
  });

  String get initials {
    if (fullName.isEmpty) return '?';
    final parts = fullName.split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length >= 2 ? 2 : 1).toUpperCase();
  }
}

class PeopleDataEntity {
  final List<ContactEntity> favorites;
  final List<ContactEntity> frequentlyContacted;
  final List<ContactEntity> allContacts;

  const PeopleDataEntity({
    required this.favorites,
    required this.frequentlyContacted,
    required this.allContacts,
  });
}
