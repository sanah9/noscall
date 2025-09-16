
class Auth {
  late String challenge;

  Auth.deserialize(input) {
    assert(input.length == 2);
    challenge = input[1];
  }
}