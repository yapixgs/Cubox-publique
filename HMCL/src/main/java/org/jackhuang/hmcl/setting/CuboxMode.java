/*
 * Hello Minecraft! Launcher
 * Copyright (C) 2025 huangyuhui <huanghongxun2008@126.com> and contributors
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
package org.jackhuang.hmcl.setting;

import org.jackhuang.hmcl.theme.ThemeColor;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import static org.jackhuang.hmcl.setting.ConfigHolder.config;
import static org.jackhuang.hmcl.setting.ConfigHolder.globalConfig;

/// **ARCHIVÉ / en sommeil.** Cubox est aujourd'hui distribué uniquement hors ligne
/// (voir [Cubox#OFFLINE_ONLY]) ; ce système à deux modes n'est pas branché sur
/// l'interface. Il est gardé exprès pour pouvoir réveiller le mode en ligne (« CuboxPO »).
///
/// Les deux modes d'utilisation proposés par Cubox.
///
/// Chaque mode porte sa propre couleur d'accent de la marque. Choisir un mode applique
/// cet accent au thème du lanceur (voir [#select]) : l'identité de Cubox reste visible
/// quelle que soit la couleur de thème enregistrée auparavant dans la configuration.
///
/// Les noms des constantes sont écrits dans la configuration ([#select]) : contrat
/// avec les fichiers de configuration existants, ils ne se renomment pas.
public enum CuboxMode {

    /// CuboxFO — mode entièrement hors ligne : un simple pseudo, aucun compte Microsoft,
    /// rien n'est envoyé à Microsoft. Accent cyan de la marque.
    OFFLINE(ThemeColor.DEFAULT, "cubox.mode.offline"),

    /// CuboxPO — mode en ligne / premium, avec un compte Microsoft. Accent ambre de la
    /// marque. La connexion Microsoft exige en plus un identifiant client Azure et reste
    /// désactivée tant qu'aucun n'est intégré à la construction.
    ONLINE(ThemeColor.CUBOX_AMBER, "cubox.mode.online");

    private final @NotNull ThemeColor accent;
    private final @NotNull String displayKey;

    CuboxMode(@NotNull ThemeColor accent, @NotNull String displayKey) {
        this.accent = accent;
        this.displayKey = displayKey;
    }

    /// La couleur d'accent de la marque associée à ce mode.
    public @NotNull ThemeColor getAccent() {
        return accent;
    }

    /// La clé de traduction du nom court de ce mode (par exemple « CuboxFO — Hors ligne »).
    /// La clé de sa description est cette valeur suivie de `.desc`.
    public @NotNull String getDisplayKey() {
        return displayKey;
    }

    /// Lit un nom de mode enregistré (tel qu'écrit par [#select]) ; `null` quand la
    /// valeur est absente ou inconnue — au premier lancement par exemple, avant que
    /// l'utilisateur ait choisi un mode.
    public static @Nullable CuboxMode fromName(@Nullable String name) {
        if (name == null)
            return null;

        try {
            return valueOf(name);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /// Le mode choisi dans la configuration, ou `null` si l'utilisateur n'en a pas
    /// encore choisi (premier lancement).
    public static @Nullable CuboxMode current() {
        return fromName(config().getCuboxMode());
    }

    /// Choisit [mode] : l'enregistre dans la configuration, applique sa couleur
    /// d'accent et met à jour le parcours des comptes ([#applyToSession]). Appliquer
    /// l'accent ici rend la couleur de Cubox visible même quand une ancienne couleur
    /// de thème avait été enregistrée.
    public static void select(@NotNull CuboxMode mode) {
        config().setCuboxMode(mode.name());
        config().setThemeColor(mode.getAccent());
        applyToSession();
    }

    /// Applique le comportement du mode choisi à la session en cours. Cubox est
    /// d'abord hors ligne : les comptes hors ligne sont toujours disponibles ; le mode
    /// décide ensuite du type de compte proposé par défaut à l'ajout d'un compte —
    /// hors ligne (un simple pseudo) pour [#OFFLINE], Microsoft pour [#ONLINE].
    ///
    /// À appeler au démarrage, pour qu'un mode choisi lors d'un lancement précédent
    /// guide toujours le parcours des comptes (sinon la fenêtre de connexion
    /// Microsoft pourrait apparaître même en mode hors ligne).
    public static void applyToSession() {
        // Les comptes hors ligne sont toujours disponibles dans Cubox (d'abord hors ligne).
        globalConfig().setEnableOfflineAccount(true);

        CuboxMode mode = current();
        if (mode != null)
            config().setPreferredLoginType(mode == ONLINE ? "microsoft" : "offline");
    }
}
