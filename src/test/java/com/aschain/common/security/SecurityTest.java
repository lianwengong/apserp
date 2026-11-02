package com.aschain.common.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.aschain.common.ApiException;
import io.jsonwebtoken.Claims;
import org.junit.jupiter.api.Test;

class PasswordHasherTest {

    private final PasswordHasher hasher = new PasswordHasher();

    @Test
    void hash_should_verify_round_trip() {
        String salt = hasher.newSalt();
        String hash = hasher.hash("Apserp@2026", salt);
        assertThat(hasher.matches("Apserp@2026", hash, salt)).isTrue();
    }

    @Test
    void wrong_password_should_not_match() {
        String salt = hasher.newSalt();
        String hash = hasher.hash("Apserp@2026", salt);
        assertThat(hasher.matches("Apserp@2027", hash, salt)).isFalse();
    }

    @Test
    void same_password_with_different_salt_should_differ() {
        String h1 = hasher.hash("same", hasher.newSalt());
        String h2 = hasher.hash("same", hasher.newSalt());
        assertThat(h1).isNotEqualTo(h2);
    }

    @Test
    void empty_password_in_database_should_never_match() {
        assertThat(hasher.matches("anything", "", "")).isFalse();
        assertThat(hasher.matches("anything", null, null)).isFalse();
    }

    @Test
    void known_vector_should_match_bootstrap_admin() {
        // V20 迁移里写死的管理员初始口令，必须能被这里验证通过
        String hash = "BUiHQ9klRWk5zliqai6kcf6n4VK9DAbIUfCyeSXx3BU=";
        String salt = "mH87uCBXyyWol8vyyAiSbg==";
        assertThat(hasher.matches("Apserp@2026", hash, salt)).isTrue();
    }
}

class JwtServiceTest {

    private final JwtService jwt = new JwtService(
            "unit-test-secret-must-be-at-least-32-bytes-long", 60);

    @Test
    void issued_token_should_carry_claims() {
        String token = jwt.issue(42L, 7, "admin", true, false);
        Claims claims = jwt.parse(token);
        assertThat(claims.getSubject()).isEqualTo("42");
        assertThat(((Number) claims.get(JwtService.CLAIM_TENANT)).intValue()).isEqualTo(7);
        assertThat(claims.get(JwtService.CLAIM_ADMIN)).isEqualTo(true);
        assertThat(claims.get(JwtService.CLAIM_MUST_CHANGE)).isEqualTo(false);
    }

    @Test
    void tampered_token_should_be_rejected() {
        String token = jwt.issue(42L, 7, "admin", false, false);
        String tampered = token.substring(0, token.length() - 2) + "xx";
        assertThatThrownBy(() -> jwt.parse(tampered)).isInstanceOf(ApiException.class);
    }

    @Test
    void token_signed_with_other_key_should_be_rejected() {
        JwtService other = new JwtService("another-secret-another-secret-32bytes!", 60);
        String foreign = other.issue(1L, 1, "x", true, false);
        assertThatThrownBy(() -> jwt.parse(foreign)).isInstanceOf(ApiException.class);
    }

    @Test
    void short_secret_should_fail_fast() {
        assertThatThrownBy(() -> new JwtService("too-short", 60))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("32");
    }
}
