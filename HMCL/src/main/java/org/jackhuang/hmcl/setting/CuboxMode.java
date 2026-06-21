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

/// The two usage modes offered by Cubox.
///
/// Each mode carries its own brand accent color. Selecting a mode applies that
/// accent to the launcher theme (see [#select]), which guarantees the Cubox
/// identity is visible regardless of any theme color previously persisted in
/// the configuration file.
public enum CuboxMode {

    /// CuboxFO — fully offline mode: a simple username, no Microsoft account,
    /// nothing sent to Microsoft. Uses the cyan brand accent.
    OFFLINE(ThemeColor.DEFAULT, "cubox.mode.offline"),

    /// CuboxPO — online / premium mode backed by a Microsoft account. Uses the
    /// amber brand accent. Microsoft sign-in additionally requires an Azure
    /// client id and stays disabled until one is embedded in the build.
    ONLINE(ThemeColor.CUBOX_AMBER, "cubox.mode.online");

    private final @NotNull ThemeColor accent;
    private final @NotNull String displayKey;

    CuboxMode(@NotNull ThemeColor accent, @NotNull String displayKey) {
        this.accent = accent;
        this.displayKey = displayKey;
    }

    /// The brand accent color associated with this mode.
    public @NotNull ThemeColor getAccent() {
        return accent;
    }

    /// The i18n key of this mode's short display name (e.g. "CuboxFO — Offline").
    /// The matching description key is this value suffixed with `.desc`.
    public @NotNull String getDisplayKey() {
        return displayKey;
    }

    /// Parses a stored mode name (as written by [#select]), returning `null`
    /// when the value is absent or unrecognized — e.g. on first run, before the
    /// user has chosen a mode.
    public static @Nullable CuboxMode fromName(@Nullable String name) {
        if (name == null)
            return null;

        try {
            return valueOf(name);
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    /// The mode currently selected in the configuration, or `null` if the user
    /// has not chosen one yet (first run).
    public static @Nullable CuboxMode current() {
        return fromName(config().getCuboxMode());
    }

    /// Selects [mode]: persists it to the configuration and applies its brand
    /// accent color. Applying the accent here is what makes the Cubox color
    /// visible even when an older theme color was previously persisted.
    public static void select(@NotNull CuboxMode mode) {
        config().setCuboxMode(mode.name());
        config().setThemeColor(mode.getAccent());
    }
}
