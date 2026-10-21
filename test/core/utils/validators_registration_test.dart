// Garde de non-régression du contrat d'inscription (téléphone / nom).
//
// Le backend accepte 8 à 15 chiffres avec un "+" optionnel et refuse les
// numéros plus courts. Le validateur client doit rester aligné pour éviter
// qu'une saisie validée par le formulaire produise un 400 côté serveur.
import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/core/util/validators.dart';

void main() {
  group('Validators.isValidPhoneNumber', () {
    test('accepte les formats local et international', () {
      expect(Validators.isValidPhoneNumber('+2250707070707'), isTrue);
      expect(Validators.isValidPhoneNumber('0102030405'), isTrue);
      expect(Validators.isValidPhoneNumber('+33612345678'), isTrue);
      expect(Validators.isValidPhoneNumber('01020304'), isTrue);
    });

    test('refuse les numéros hors bornes 8-15 chiffres', () {
      expect(Validators.isValidPhoneNumber('0102030'), isFalse);
      expect(Validators.isValidPhoneNumber('1234567890123456'), isFalse);
      expect(Validators.isValidPhoneNumber('+'), isFalse);
      expect(Validators.isValidPhoneNumber(''), isFalse);
    });
  });

  group('Validators.isValidDisplayName', () {
    test("accepte les noms avec apostrophe ou esperluette", () {
      expect(Validators.isValidDisplayName("N'Guessan"), isTrue);
      expect(Validators.isValidDisplayName('Konan & Fils'), isTrue);
    });

    test('refuse un nom trop court ou trop long', () {
      expect(Validators.isValidDisplayName('Jo'), isFalse);
      expect(Validators.isValidDisplayName(''.padLeft(31, 'a')), isFalse);
    });
  });
}
