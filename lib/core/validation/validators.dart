class Validators {
  static String? requiredText(String? value, {String field = 'Campo'}) {
    if (value == null || value.trim().isEmpty) {
      return '$field es obligatorio';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredText(value, field: 'Correo');
    if (requiredError != null) return requiredError;

    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!regex.hasMatch(value!.trim())) {
      return 'Ingresa un correo valido';
    }
    return null;
  }

  static String? dni(String? value) {
    final requiredError = requiredText(value, field: 'DNI');
    if (requiredError != null) return requiredError;

    if (!RegExp(r'^\d{8}$').hasMatch(value!.trim())) {
      return 'El DNI debe tener 8 digitos';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = requiredText(value, field: 'Contrasena');
    if (requiredError != null) return requiredError;

    if (value!.length < 4) {
      return 'Minimo 4 caracteres';
    }
    return null;
  }

  static String? amount(String? value) {
    final requiredError = requiredText(value, field: 'Monto');
    if (requiredError != null) return requiredError;

    final amount = double.tryParse(value!.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      return 'Ingresa un monto mayor a cero';
    }
    return null;
  }

  static String? phone(String? value) {
    final requiredError = requiredText(value, field: 'Telefono');
    if (requiredError != null) return requiredError;

    if (!RegExp(r'^\d{9}$').hasMatch(value!.trim())) {
      return 'El telefono debe tener 9 digitos';
    }
    return null;
  }
}
