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
import org.jetbrains.annotations.Nullable;

import java.net.URI;
import java.net.URISyntaxException;
import java.util.Locale;
import java.util.Optional;

/// Parses a public CurseForge or Modrinth project URL into the information
/// needed to look the project up through a [RemoteModRepository].
///
/// Supported shapes:
/// - Modrinth: `https://modrinth.com/{projectType}/{slug}` where `projectType`
///   is one of `mod`, `modpack`, `resourcepack`, `shader`.
/// - CurseForge: `https://www.curseforge.com/minecraft/{category}/{slug}`
///   (and the `legacy.curseforge.com` host) where `category` is one of
///   `mc-mods`, `modpacks`, `texture-packs`, `shaders`, `worlds`.
///
/// Anything else (unknown host, unknown content type, malformed URL) yields an
/// empty result so callers can show a "not a valid link" message.
@NotNullByDefault
public final class ModRepositoryLink {

    private ModRepositoryLink() {
    }

    /// The hosting platform a link points to.
    public enum Provider {
        /// modrinth.com
        MODRINTH,
        /// curseforge.com
        CURSEFORGE
    }

    /// The result of successfully parsing a project URL.
    ///
    /// @param provider  the hosting platform the link points to
    /// @param type      the kind of content the project is
    /// @param idOrSlug  the project slug (Modrinth accepts it directly as an id;
    ///                  CurseForge must resolve it to a numeric id)
    public record Parsed(Provider provider, RemoteModRepository.Type type, String idOrSlug) {
    }

    /// Parses a CurseForge or Modrinth project URL.
    ///
    /// The input is trimmed and a `https://` scheme is added when missing so
    /// users can paste a bare `modrinth.com/mod/sodium` host-and-path too.
    ///
    /// @param url the raw text the user pasted
    /// @return the parsed project, or empty if the URL is not a recognized link
    public static Optional<Parsed> parse(@Nullable String url) {
        if (url == null) {
            return Optional.empty();
        }

        String trimmed = url.strip();
        if (trimmed.isEmpty()) {
            return Optional.empty();
        }

        // Allow pasting a bare host/path (no scheme) such as "modrinth.com/mod/sodium".
        String normalized = trimmed.contains("://") ? trimmed : "https://" + trimmed;

        URI uri;
        try {
            uri = new URI(normalized);
        } catch (URISyntaxException e) {
            return Optional.empty();
        }

        String host = uri.getHost();
        String path = uri.getPath();
        if (host == null || path == null) {
            return Optional.empty();
        }
        host = host.toLowerCase(Locale.ROOT);

        // Drop empty segments produced by leading/trailing/duplicate slashes.
        String[] segments = path.split("/");
        int count = 0;
        for (String segment : segments) {
            if (!segment.isEmpty()) {
                segments[count++] = segment;
            }
        }

        if (host.equals("modrinth.com") || host.endsWith(".modrinth.com")) {
            return parseModrinth(segments, count);
        }
        if (host.equals("curseforge.com") || host.endsWith(".curseforge.com")) {
            return parseCurseForge(segments, count);
        }
        return Optional.empty();
    }

    /// Parses a Modrinth path of the form `/{projectType}/{slug}`.
    private static Optional<Parsed> parseModrinth(String @Nullable [] segments, int count) {
        if (count < 2) {
            return Optional.empty();
        }
        RemoteModRepository.Type type = switch (segments[0].toLowerCase(Locale.ROOT)) {
            case "mod" -> RemoteModRepository.Type.MOD;
            case "modpack" -> RemoteModRepository.Type.MODPACK;
            case "resourcepack" -> RemoteModRepository.Type.RESOURCE_PACK;
            case "shader" -> RemoteModRepository.Type.SHADER_PACK;
            default -> null; // datapack / plugin and anything else are unsupported
        };
        if (type == null) {
            return Optional.empty();
        }
        return Optional.of(new Parsed(Provider.MODRINTH, type, segments[1]));
    }

    /// Parses a CurseForge path of the form `/minecraft/{category}/{slug}`.
    private static Optional<Parsed> parseCurseForge(String @Nullable [] segments, int count) {
        // Expect: minecraft / {category} / {slug}
        if (count < 3 || !segments[0].equalsIgnoreCase("minecraft")) {
            return Optional.empty();
        }
        RemoteModRepository.Type type = switch (segments[1].toLowerCase(Locale.ROOT)) {
            case "mc-mods" -> RemoteModRepository.Type.MOD;
            case "modpacks" -> RemoteModRepository.Type.MODPACK;
            case "texture-packs" -> RemoteModRepository.Type.RESOURCE_PACK;
            case "shaders" -> RemoteModRepository.Type.SHADER_PACK;
            case "worlds" -> RemoteModRepository.Type.WORLD;
            default -> null; // customization / data-packs / bukkit-plugins are unsupported
        };
        if (type == null) {
            return Optional.empty();
        }
        return Optional.of(new Parsed(Provider.CURSEFORGE, type, segments[2]));
    }
}
