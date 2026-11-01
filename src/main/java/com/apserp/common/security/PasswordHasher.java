package com.apserp.common.security;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.spec.InvalidKeySpecException;
import java.util.Base64;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;
import org.springframework.stereotype.Component;

/**
 * 口令哈希：PBKDF2-HMAC-SHA256。
 *
 * <p>参数写死在类里而不是配置里——参数一旦变化，存量口令全部失效，必须是代码级常量。</p>
 *
 * <p>比较使用 {@link MessageDigest#isEqual} 做定长比较，避免时序侧信道。</p>
 */
@Component
public class PasswordHasher {

    private static final String ALGORITHM = "PBKDF2WithHmacSHA256";
    private static final int ITERATIONS = 120_000;
    private static final int KEY_LENGTH_BITS = 256;
    private static final int SALT_BYTES = 16;

    private final SecureRandom random = new SecureRandom();

    public String newSalt() {
        byte[] salt = new byte[SALT_BYTES];
        random.nextBytes(salt);
        return Base64.getEncoder().encodeToString(salt);
    }

    public String hash(String rawPassword, String saltBase64) {
        char[] chars = rawPassword.toCharArray();
        byte[] salt = Base64.getDecoder().decode(saltBase64);
        PBEKeySpec spec = new PBEKeySpec(chars, salt, ITERATIONS, KEY_LENGTH_BITS);
        try {
            byte[] key = SecretKeyFactory.getInstance(ALGORITHM).generateSecret(spec).getEncoded();
            return Base64.getEncoder().encodeToString(key);
        } catch (NoSuchAlgorithmException | InvalidKeySpecException ex) {
            throw new IllegalStateException("口令算法不可用：" + ALGORITHM, ex);
        } finally {
            spec.clearPassword();
            java.util.Arrays.fill(chars, '\0');
        }
    }

    public boolean matches(String rawPassword, String hashBase64, String saltBase64) {
        if (rawPassword == null || hashBase64 == null || saltBase64 == null
                || hashBase64.isBlank() || saltBase64.isBlank()) {
            return false;
        }
        byte[] actual = Base64.getDecoder().decode(hash(rawPassword, saltBase64));
        byte[] expected = Base64.getDecoder().decode(hashBase64);
        return MessageDigest.isEqual(actual, expected);
    }
}
