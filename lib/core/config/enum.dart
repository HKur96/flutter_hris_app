enum Role {
  owner,
  admin,
  employee;

  static Role fromValue(String value) {
    switch (value.toLowerCase()) {
      case 'owner':
        return owner;
      case 'admin':
        return admin;
      default:
        return employee;
    }
  }

  String get display {
    switch (this) {
      case owner:
        return 'Owner';
      case admin:
        return 'Admin';
      default:
        return 'Employee';
    }
  }
}
