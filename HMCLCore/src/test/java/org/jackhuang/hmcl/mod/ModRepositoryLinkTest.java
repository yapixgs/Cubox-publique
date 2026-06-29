/*
 * Hello Minecraft! Launcher
 * Copyright (C) 2024  huangyuhui <huanghongxun2008@126.com> and contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
package org.jackhuang.hmcl.mod;

import org.jetbrains.annotations.NotNullByDefault;
import org.junit.jupiter.api.Test;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

/// Tests for [ModRepositoryLink], which parses CurseForge / Modrinth project URLs.
@NotNullByDefault
public final class ModRepositoryLinkTest {

    private static ModRepositoryLink.Parsed parse(String url) {
        Optional<ModRepositoryLink.Parsed> parsed = ModRepositoryLink.parse(url);
        assertTrue(parsed.isPresent(), () -> "Expected a parse result for: " + url);
        return parsed.get();
    }

    private static void assertParsed(String url, ModRepositoryLink.Provider provider, RemoteModRepository.Type type, String idOrSlug) {
        ModRepositoryLink.Parsed parsed = parse(url);
        assertEquals(provider, parsed.provider(), url);
        assertEquals(type, parsed.type(), url);
        assertEquals(idOrSlug, parsed.idOrSlug(), url);
    }

    @Test
    public void modrinth() {
        assertParsed("https://modrinth.com/mod/sodium", ModRepositoryLink.Provider.MODRINTH, RemoteModRepository.Type.MOD, "sodium");
        assertParsed("https://modrinth.com/modpack/cobblemon-fabric", ModRepositoryLink.Provider.MODRINTH, RemoteModRepository.Type.MODPACK, "cobblemon-fabric");
        assertParsed("https://modrinth.com/resourcepack/faithful-32x", ModRepositoryLink.Provider.MODRINTH, RemoteModRepository.Type.RESOURCE_PACK, "faithful-32x");
        assertParsed("https://modrinth.com/shader/complementary-reimagined", ModRepositoryLink.Provider.MODRINTH, RemoteModRepository.Type.SHADER_PACK, "complementary-reimagined");
    }

    @Test
    public void modrinthExtraSegmentsAndQuery() {
        // Trailing version path and query string should be ignored.
        assertParsed("https://modrinth.com/mod/sodium/version/mc1.20.1?foo=bar", ModRepositoryLink.Provider.MODRINTH, RemoteModRepository.Type.MOD, "sodium");
    }

    @Test
    public void modrinthBareHostNoScheme() {
        assertParsed("modrinth.com/mod/sodium", ModRepositoryLink.Provider.MODRINTH, RemoteModRepository.Type.MOD, "sodium");
        assertParsed("  https://modrinth.com/mod/sodium  ", ModRepositoryLink.Provider.MODRINTH, RemoteModRepository.Type.MOD, "sodium");
    }

    @Test
    public void curseForge() {
        assertParsed("https://www.curseforge.com/minecraft/mc-mods/jei", ModRepositoryLink.Provider.CURSEFORGE, RemoteModRepository.Type.MOD, "jei");
        assertParsed("https://www.curseforge.com/minecraft/texture-packs/faithful-32x", ModRepositoryLink.Provider.CURSEFORGE, RemoteModRepository.Type.RESOURCE_PACK, "faithful-32x");
        assertParsed("https://www.curseforge.com/minecraft/shaders/complementary-shaders", ModRepositoryLink.Provider.CURSEFORGE, RemoteModRepository.Type.SHADER_PACK, "complementary-shaders");
        assertParsed("https://www.curseforge.com/minecraft/worlds/some-adventure-map", ModRepositoryLink.Provider.CURSEFORGE, RemoteModRepository.Type.WORLD, "some-adventure-map");
        assertParsed("https://www.curseforge.com/minecraft/modpacks/all-the-mods-9", ModRepositoryLink.Provider.CURSEFORGE, RemoteModRepository.Type.MODPACK, "all-the-mods-9");
    }

    @Test
    public void curseForgeLegacyHostAndExtraSegments() {
        assertParsed("https://legacy.curseforge.com/minecraft/mc-mods/jei/files/all", ModRepositoryLink.Provider.CURSEFORGE, RemoteModRepository.Type.MOD, "jei");
    }

    @Test
    public void unsupportedOrInvalid() {
        // Unknown hosts.
        assertTrue(ModRepositoryLink.parse("https://example.com/mod/sodium").isEmpty());
        assertTrue(ModRepositoryLink.parse("https://github.com/HMCL-dev/HMCL").isEmpty());
        // Unsupported content types.
        assertTrue(ModRepositoryLink.parse("https://modrinth.com/plugin/whatever").isEmpty());
        assertTrue(ModRepositoryLink.parse("https://modrinth.com/datapack/whatever").isEmpty());
        assertTrue(ModRepositoryLink.parse("https://www.curseforge.com/minecraft/bukkit-plugins/whatever").isEmpty());
        assertTrue(ModRepositoryLink.parse("https://www.curseforge.com/wow/addons/whatever").isEmpty());
        // Malformed / empty.
        assertTrue(ModRepositoryLink.parse("").isEmpty());
        assertTrue(ModRepositoryLink.parse("   ").isEmpty());
        assertTrue(ModRepositoryLink.parse(null).isEmpty());
        assertTrue(ModRepositoryLink.parse("https://modrinth.com/mod").isEmpty());
        assertTrue(ModRepositoryLink.parse("not a url at all").isEmpty());
    }
}
