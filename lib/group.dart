class Group {
  final int id;
  final String name;
  final String? profilePicture;
  final List<String> members;

  Group({
    required this.id,
    required this.name,
    this.profilePicture,
    required this.members,
  });
}
