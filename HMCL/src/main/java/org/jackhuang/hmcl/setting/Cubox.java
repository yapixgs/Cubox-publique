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

/// Interrupteurs de fonctionnalités propres à Cubox.
public final class Cubox {

    private Cubox() {
    }

    /// Cubox est aujourd'hui distribué comme lanceur **uniquement hors ligne**.
    ///
    /// Le mode en ligne (« CuboxPO », connexion Microsoft pour les serveurs premium)
    /// est **en sommeil** : caché de l'interface et impossible à choisir. Il exige une
    /// application Microsoft Azure qu'il n'est pas raisonnable de fournir ici : la
    /// fonctionnalité est archivée plutôt que supprimée.
    ///
    /// Passer à `false` pour réveiller le mode en ligne — le code nécessaire est
    /// gardé exprès : [CuboxMode] et `org.jackhuang.hmcl.ui.CuboxModeSelectionPane`,
    /// plus les entrées Microsoft de l'interface des comptes conditionnées par ce drapeau.
    public static final boolean OFFLINE_ONLY = true;
}
