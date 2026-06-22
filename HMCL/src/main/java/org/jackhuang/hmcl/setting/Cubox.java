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

/// Cubox-wide feature flags.
public final class Cubox {

    private Cubox() {
    }

    /// Cubox currently ships as an **offline-only** launcher.
    ///
    /// The online mode ("CuboxPO", i.e. Microsoft sign-in for premium servers)
    /// is **hibernated**: hidden from the UI and not selectable. It requires a
    /// Microsoft Azure application that is impractical to provide here, so the
    /// feature is archived rather than removed.
    ///
    /// Flip this to `false` to revive the online mode — the supporting code is
    /// kept on purpose: [CuboxMode] and
    /// `org.jackhuang.hmcl.ui.CuboxModeSelectionPane`, plus the Microsoft
    /// entries gated on this flag in the account UI.
    public static final boolean OFFLINE_ONLY = true;
}
