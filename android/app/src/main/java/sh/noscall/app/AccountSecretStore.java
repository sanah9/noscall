package sh.noscall.app;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Build;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Base64;

import java.nio.charset.StandardCharsets;
import java.security.KeyStore;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.GCMParameterSpec;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public final class AccountSecretStore {
    private static final String CHANNEL = "sh.noscall.account_secrets";
    private static final String ANDROID_KEYSTORE = "AndroidKeyStore";
    private static final String KEY_ALIAS = "noscall_account_secret_key";
    private static final String PREFS_NAME = "noscall_account_secrets";
    private static final String CIPHER_TRANSFORMATION = "AES/GCM/NoPadding";
    private static final int GCM_TAG_LENGTH_BITS = 128;

    private AccountSecretStore() {
    }

    public static void register(Context context, FlutterEngine flutterEngine) {
        SharedPreferences preferences =
                context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        new MethodChannel(
                flutterEngine.getDartExecutor().getBinaryMessenger(),
                CHANNEL
        ).setMethodCallHandler((call, result) -> {
            String key = call.argument("key");
            if (key == null || key.isEmpty()) {
                result.error("invalid_key", "Secret key is required.", null);
                return;
            }

            try {
                switch (call.method) {
                    case "read":
                        result.success(read(preferences, key));
                        break;
                    case "write":
                        String value = call.argument("value");
                        if (value == null) {
                            result.error("invalid_value", "Secret value is required.", null);
                            return;
                        }
                        write(preferences, key, value);
                        result.success(null);
                        break;
                    case "delete":
                        preferences.edit().remove(key).apply();
                        result.success(null);
                        break;
                    default:
                        result.notImplemented();
                        break;
                }
            } catch (Exception e) {
                result.error("account_secret_store", e.getMessage(), null);
            }
        });
    }

    private static String read(SharedPreferences preferences, String key) throws Exception {
        String storedValue = preferences.getString(key, null);
        if (storedValue == null || storedValue.isEmpty()) {
            return null;
        }

        String[] parts = storedValue.split(":", 2);
        if (parts.length != 2) {
            return null;
        }

        byte[] iv = Base64.decode(parts[0], Base64.NO_WRAP);
        byte[] cipherText = Base64.decode(parts[1], Base64.NO_WRAP);
        Cipher cipher = Cipher.getInstance(CIPHER_TRANSFORMATION);
        cipher.init(
                Cipher.DECRYPT_MODE,
                getOrCreateSecretKey(),
                new GCMParameterSpec(GCM_TAG_LENGTH_BITS, iv)
        );
        byte[] plainText = cipher.doFinal(cipherText);
        return new String(plainText, StandardCharsets.UTF_8);
    }

    private static void write(
            SharedPreferences preferences,
            String key,
            String value
    ) throws Exception {
        Cipher cipher = Cipher.getInstance(CIPHER_TRANSFORMATION);
        cipher.init(Cipher.ENCRYPT_MODE, getOrCreateSecretKey());
        byte[] cipherText = cipher.doFinal(value.getBytes(StandardCharsets.UTF_8));
        String storedValue =
                Base64.encodeToString(cipher.getIV(), Base64.NO_WRAP)
                        + ":"
                        + Base64.encodeToString(cipherText, Base64.NO_WRAP);
        preferences.edit().putString(key, storedValue).apply();
    }

    private static SecretKey getOrCreateSecretKey() throws Exception {
        KeyStore keyStore = KeyStore.getInstance(ANDROID_KEYSTORE);
        keyStore.load(null);
        if (keyStore.containsAlias(KEY_ALIAS)) {
            return (SecretKey) keyStore.getKey(KEY_ALIAS, null);
        }

        KeyGenerator keyGenerator = KeyGenerator.getInstance(
                KeyProperties.KEY_ALGORITHM_AES,
                ANDROID_KEYSTORE
        );
        KeyGenParameterSpec.Builder builder = new KeyGenParameterSpec.Builder(
                KEY_ALIAS,
                KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT
        )
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setRandomizedEncryptionRequired(true);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            builder.setUnlockedDeviceRequired(false);
        }
        keyGenerator.init(builder.build());
        return keyGenerator.generateKey();
    }
}
