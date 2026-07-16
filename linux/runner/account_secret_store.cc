#include "account_secret_store.h"

#include <libsecret/secret.h>

#include <cstring>

namespace {

constexpr char kChannelName[] = "sh.noscall.account_secrets";
constexpr char kSchemaName[] = "sh.noscall.account_secrets";
constexpr char kKeyAttribute[] = "key";
constexpr char kSecretLabel[] = "Noscall account secret";

const SecretSchema kSecretSchema = {
    kSchemaName,
    SECRET_SCHEMA_NONE,
    {
        {kKeyAttribute, SECRET_SCHEMA_ATTRIBUTE_STRING},
        {nullptr, SECRET_SCHEMA_ATTRIBUTE_STRING},
    },
};

FlMethodResponse* InvalidArgumentsResponse() {
  return FL_METHOD_RESPONSE(fl_method_error_response_new(
      "invalid_arguments", "Arguments must be a map.", nullptr));
}

FlMethodResponse* InvalidKeyResponse() {
  return FL_METHOD_RESPONSE(fl_method_error_response_new(
      "invalid_key", "Secret key is required.", nullptr));
}

FlMethodResponse* InvalidValueResponse() {
  return FL_METHOD_RESPONSE(fl_method_error_response_new(
      "invalid_value", "Secret value is required.", nullptr));
}

FlMethodResponse* SecretStoreErrorResponse(GError* error) {
  const char* message =
      error != nullptr ? error->message : "Secret Service operation failed.";
  return FL_METHOD_RESPONSE(fl_method_error_response_new(
      "account_secret_store", message, nullptr));
}

FlValue* LookupStringArgument(FlValue* arguments, const char* key) {
  if (arguments == nullptr || fl_value_get_type(arguments) != FL_VALUE_TYPE_MAP) {
    return nullptr;
  }

  FlValue* value = fl_value_lookup_string(arguments, key);
  if (value == nullptr || fl_value_get_type(value) != FL_VALUE_TYPE_STRING) {
    return nullptr;
  }
  return value;
}

FlMethodResponse* ReadSecret(FlValue* arguments) {
  FlValue* key_value = LookupStringArgument(arguments, "key");
  if (key_value == nullptr) {
    return InvalidKeyResponse();
  }

  const char* key = fl_value_get_string(key_value);
  if (key == nullptr || strlen(key) == 0) {
    return InvalidKeyResponse();
  }

  g_autoptr(GError) error = nullptr;
  g_autofree char* secret = secret_password_lookup_sync(
      &kSecretSchema, nullptr, &error, kKeyAttribute, key, nullptr);
  if (error != nullptr) {
    return SecretStoreErrorResponse(error);
  }

  g_autoptr(FlValue) result =
      secret == nullptr ? fl_value_new_null() : fl_value_new_string(secret);
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

FlMethodResponse* WriteSecret(FlValue* arguments) {
  FlValue* key_value = LookupStringArgument(arguments, "key");
  if (key_value == nullptr) {
    return InvalidKeyResponse();
  }

  FlValue* value_value = LookupStringArgument(arguments, "value");
  if (value_value == nullptr) {
    return InvalidValueResponse();
  }

  const char* key = fl_value_get_string(key_value);
  const char* value = fl_value_get_string(value_value);
  if (key == nullptr || strlen(key) == 0) {
    return InvalidKeyResponse();
  }

  g_autoptr(GError) error = nullptr;
  gboolean stored = secret_password_store_sync(
      &kSecretSchema, SECRET_COLLECTION_DEFAULT, kSecretLabel, value, nullptr,
      &error, kKeyAttribute, key, nullptr);
  if (!stored) {
    return SecretStoreErrorResponse(error);
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

FlMethodResponse* DeleteSecret(FlValue* arguments) {
  FlValue* key_value = LookupStringArgument(arguments, "key");
  if (key_value == nullptr) {
    return InvalidKeyResponse();
  }

  const char* key = fl_value_get_string(key_value);
  if (key == nullptr || strlen(key) == 0) {
    return InvalidKeyResponse();
  }

  g_autoptr(GError) error = nullptr;
  secret_password_clear_sync(
      &kSecretSchema, nullptr, &error, kKeyAttribute, key, nullptr);
  if (error != nullptr) {
    return SecretStoreErrorResponse(error);
  }

  return FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
}

void MethodCallCallback(FlMethodChannel* /* channel */,
                        FlMethodCall* method_call,
                        gpointer /* user_data */) {
  FlValue* arguments = fl_method_call_get_args(method_call);
  const char* method = fl_method_call_get_name(method_call);

  g_autoptr(FlMethodResponse) response = nullptr;
  if (arguments == nullptr || fl_value_get_type(arguments) != FL_VALUE_TYPE_MAP) {
    response = InvalidArgumentsResponse();
  } else if (strcmp(method, "read") == 0) {
    response = ReadSecret(arguments);
  } else if (strcmp(method, "write") == 0) {
    response = WriteSecret(arguments);
  } else if (strcmp(method, "delete") == 0) {
    response = DeleteSecret(arguments);
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  if (!fl_method_call_respond(method_call, response, &error)) {
    g_warning("Failed to send account secret store response: %s",
              error->message);
  }
}

}  // namespace

void account_secret_store_register_with_registrar(FlPluginRegistrar* registrar) {
  static FlMethodChannel* channel = nullptr;
  if (registrar == nullptr || channel != nullptr) {
    return;
  }

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  channel = fl_method_channel_new(fl_plugin_registrar_get_messenger(registrar),
                                  kChannelName, FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, MethodCallCallback,
                                            nullptr, nullptr);
}
