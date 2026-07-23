#include "account_secret_store.h"

#include <windows.h>
#include <wincred.h>

#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <string>
#include <variant>
#include <vector>

namespace {

constexpr char kChannelName[] = "sh.noscall.account_secrets";
constexpr wchar_t kCredentialPrefix[] = L"sh.noscall.account_secrets/";

std::wstring Utf8ToWide(const std::string& value) {
  if (value.empty()) {
    return std::wstring();
  }
  const int length = MultiByteToWideChar(
      CP_UTF8, 0, value.data(), static_cast<int>(value.size()), nullptr, 0);
  std::wstring result(length, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, value.data(), static_cast<int>(value.size()),
                      result.data(), length);
  return result;
}

std::wstring CredentialTargetForKey(const std::string& key) {
  return std::wstring(kCredentialPrefix) + Utf8ToWide(key);
}

std::string LastErrorMessage(DWORD error) {
  LPWSTR message = nullptr;
  const DWORD length = FormatMessageW(
      FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM |
          FORMAT_MESSAGE_IGNORE_INSERTS,
      nullptr, error, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
      reinterpret_cast<LPWSTR>(&message), 0, nullptr);
  if (length == 0 || message == nullptr) {
    return "Windows credential operation failed.";
  }

  const int utf8_length =
      WideCharToMultiByte(CP_UTF8, 0, message, static_cast<int>(length),
                          nullptr, 0, nullptr, nullptr);
  std::string result(utf8_length, '\0');
  WideCharToMultiByte(CP_UTF8, 0, message, static_cast<int>(length),
                      result.data(), utf8_length, nullptr, nullptr);
  LocalFree(message);
  return result;
}

const flutter::EncodableValue* LookupArgument(
    const flutter::EncodableMap& arguments,
    const char* key) {
  const auto iterator = arguments.find(flutter::EncodableValue(key));
  if (iterator == arguments.end()) {
    return nullptr;
  }
  return &iterator->second;
}

const std::string* StringArgument(
    const flutter::EncodableMap& arguments,
    const char* key) {
  const auto* value = LookupArgument(arguments, key);
  if (value == nullptr) {
    return nullptr;
  }
  return std::get_if<std::string>(value);
}

bool ReadSecret(const std::string& key, std::string* value, DWORD* error) {
  PCREDENTIALW credential = nullptr;
  const std::wstring target = CredentialTargetForKey(key);
  if (!CredReadW(target.c_str(), CRED_TYPE_GENERIC, 0, &credential)) {
    *error = GetLastError();
    return false;
  }

  value->assign(
      reinterpret_cast<const char*>(credential->CredentialBlob),
      reinterpret_cast<const char*>(credential->CredentialBlob) +
          credential->CredentialBlobSize);
  CredFree(credential);
  return true;
}

bool WriteSecret(const std::string& key, const std::string& value,
                 DWORD* error) {
  const std::wstring target = CredentialTargetForKey(key);
  CREDENTIALW credential = {};
  credential.Type = CRED_TYPE_GENERIC;
  credential.TargetName = const_cast<LPWSTR>(target.c_str());
  credential.CredentialBlobSize = static_cast<DWORD>(value.size());
  credential.CredentialBlob = reinterpret_cast<LPBYTE>(
      const_cast<char*>(value.data()));
  credential.Persist = CRED_PERSIST_LOCAL_MACHINE;

  if (!CredWriteW(&credential, 0)) {
    *error = GetLastError();
    return false;
  }
  return true;
}

bool DeleteSecret(const std::string& key, DWORD* error) {
  const std::wstring target = CredentialTargetForKey(key);
  if (!CredDeleteW(target.c_str(), CRED_TYPE_GENERIC, 0)) {
    *error = GetLastError();
    return *error == ERROR_NOT_FOUND;
  }
  return true;
}

}  // namespace

void RegisterAccountSecretStore(flutter::BinaryMessenger* messenger) {
  auto channel = std::make_unique<flutter::MethodChannel<>>(
      messenger, kChannelName,
      &flutter::StandardMethodCodec::GetInstance());

  channel->SetMethodCallHandler(
      [](const flutter::MethodCall<>& call,
         std::unique_ptr<flutter::MethodResult<>> result) {
        const auto* arguments =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (arguments == nullptr) {
          result->Error("invalid_arguments", "Arguments must be a map.");
          return;
        }

        const std::string* key = StringArgument(*arguments, "key");
        if (key == nullptr || key->empty()) {
          result->Error("invalid_key", "Secret key is required.");
          return;
        }

        const std::string& method_name = call.method_name();
        if (method_name == "read") {
          std::string value;
          DWORD error = ERROR_SUCCESS;
          if (!ReadSecret(*key, &value, &error)) {
            if (error == ERROR_NOT_FOUND || error == ERROR_FILE_NOT_FOUND) {
              result->Success(flutter::EncodableValue());
              return;
            }
            result->Error("account_secret_store", LastErrorMessage(error));
            return;
          }
          result->Success(flutter::EncodableValue(value));
          return;
        }

        if (method_name == "write") {
          const std::string* value = StringArgument(*arguments, "value");
          if (value == nullptr) {
            result->Error("invalid_value", "Secret value is required.");
            return;
          }
          DWORD error = ERROR_SUCCESS;
          if (!WriteSecret(*key, *value, &error)) {
            result->Error("account_secret_store", LastErrorMessage(error));
            return;
          }
          result->Success();
          return;
        }

        if (method_name == "delete") {
          DWORD error = ERROR_SUCCESS;
          if (!DeleteSecret(*key, &error)) {
            result->Error("account_secret_store", LastErrorMessage(error));
            return;
          }
          result->Success();
          return;
        }

        result->NotImplemented();
      });

  // Keep the channel alive for the lifetime of the process.
  static std::vector<std::unique_ptr<flutter::MethodChannel<>>> channels;
  channels.push_back(std::move(channel));
}
