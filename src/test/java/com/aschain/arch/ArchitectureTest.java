package com.aschain.arch;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/**
 * 架构守护：防止 AI 生成的代码越界。
 * 1) common 不依赖业务域；2) controller 不直接依赖 JdbcTemplate；
 * 3) 业务域之间只能通过 api 包调用（一期先检查 1、2）。
 */
class ArchitectureTest {

    private static JavaClasses classes;

    @BeforeAll
    static void load() {
        classes = new ClassFileImporter()
                .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
                .importPackages("com.aschain");
    }

    @Test
    void common_should_not_depend_on_domains() {
        noClasses().that().resideInAPackage("com.aschain.common..")
                .should().dependOnClassesThat()
                .resideInAnyPackage("com.aschain.md..", "com.aschain.pur..", "com.aschain.sal..",
                        "com.aschain.ret..", "com.aschain.inv..", "com.aschain.fin..")
                .check(classes);
    }

    @Test
    void controllers_should_not_use_jdbc_directly() {
        noClasses().that().haveSimpleNameEndingWith("Controller")
                .should().dependOnClassesThat()
                .haveFullyQualifiedName("org.springframework.jdbc.core.JdbcTemplate")
                .check(classes);
    }

    @Test
    void no_system_out() {
        noClasses().should().accessField(System.class, "out").check(classes);
    }
}
