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

/// Lit l'adresse publique d'un projet CurseForge ou Modrinth et en tire ce qu'il faut
/// pour retrouver le projet par un [RemoteModRepository].
///
/// Formes reconnues :
/// - Modrinth : `https://modrinth.com/{projectType}/{slug}` où `projectType` vaut
///   `mod`, `modpack`, `resourcepack` ou `shader` ;
/// - CurseForge : `https://www.curseforge.com/minecraft/{category}/{slug}` (et l'hôte
///   `legacy.curseforge.com`) où `category` vaut `mc-mods`, `modpacks`,
///   `texture-packs`, `shaders` ou `worlds`.
///
/// Tout le reste (hôte inconnu, type de contenu inconnu, adresse mal formée) donne un
/// résultat vide : l'appelant peut afficher « lien non valide ».
///
/// Les noms de cette classe suivent ceux du code amont de HMCL qui l'appelle.
@NotNullByDefault
public final class ModRepositoryLink {

    private ModRepositoryLink() {
    }

    /// La plateforme d'hébergement visée par un lien.
    public enum Provider {
        /// modrinth.com
        MODRINTH,
        /// curseforge.com
        CURSEFORGE
    }

    /// Le résultat d'une adresse de projet reconnue.
    ///
    /// @param provider  la plateforme d'hébergement visée par le lien
    /// @param type      le genre de contenu du projet
    /// @param idOrSlug  le slug du projet (Modrinth l'accepte directement comme
    ///                  identifiant ; CurseForge doit le convertir en identifiant numérique)
    public record Parsed(Provider provider, RemoteModRepository.Type type, String idOrSlug) {
    }

    /// Lit l'adresse d'un projet CurseForge ou Modrinth.
    ///
    /// Le texte est débarrassé de ses espaces, et le schéma `https://` ajouté s'il
    /// manque : on peut aussi coller un simple `modrinth.com/mod/sodium`.
    ///
    /// @param url le texte brut collé par l'utilisateur
    /// @return le projet reconnu, ou vide si l'adresse n'est pas un lien reconnu
    public static Optional<Parsed> parse(@Nullable String url) {
        if (url == null) {
            return Optional.empty();
        }

        String trimmed = url.strip();
        if (trimmed.isEmpty()) {
            return Optional.empty();
        }

        // Accepter un hôte et un chemin sans schéma, comme « modrinth.com/mod/sodium ».
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

        // Écarter les segments vides dus aux barres obliques en tête, en fin ou doublées.
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

    /// Lit un chemin Modrinth de la forme `/{projectType}/{slug}`.
    private static Optional<Parsed> parseModrinth(String @Nullable [] segments, int count) {
        if (count < 2) {
            return Optional.empty();
        }
        RemoteModRepository.Type type = switch (segments[0].toLowerCase(Locale.ROOT)) {
            case "mod" -> RemoteModRepository.Type.MOD;
            case "modpack" -> RemoteModRepository.Type.MODPACK;
            case "resourcepack" -> RemoteModRepository.Type.RESOURCE_PACK;
            case "shader" -> RemoteModRepository.Type.SHADER_PACK;
            default -> null; // datapack, plugin et le reste ne sont pas pris en charge
        };
        if (type == null) {
            return Optional.empty();
        }
        return Optional.of(new Parsed(Provider.MODRINTH, type, segments[1]));
    }

    /// Lit un chemin CurseForge de la forme `/minecraft/{category}/{slug}`.
    private static Optional<Parsed> parseCurseForge(String @Nullable [] segments, int count) {
        // Attendu : minecraft / {category} / {slug}
        if (count < 3 || !segments[0].equalsIgnoreCase("minecraft")) {
            return Optional.empty();
        }
        RemoteModRepository.Type type = switch (segments[1].toLowerCase(Locale.ROOT)) {
            case "mc-mods" -> RemoteModRepository.Type.MOD;
            case "modpacks" -> RemoteModRepository.Type.MODPACK;
            case "texture-packs" -> RemoteModRepository.Type.RESOURCE_PACK;
            case "shaders" -> RemoteModRepository.Type.SHADER_PACK;
            case "worlds" -> RemoteModRepository.Type.WORLD;
            default -> null; // customization, data-packs et bukkit-plugins ne sont pas pris en charge
        };
        if (type == null) {
            return Optional.empty();
        }
        return Optional.of(new Parsed(Provider.CURSEFORGE, type, segments[2]));
    }
}
