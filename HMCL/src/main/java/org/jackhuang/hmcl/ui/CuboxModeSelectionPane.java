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
package org.jackhuang.hmcl.ui;

import com.jfoenix.controls.JFXButton;
import com.jfoenix.controls.JFXDialogLayout;
import javafx.geometry.Pos;
import javafx.scene.control.Label;
import javafx.scene.layout.HBox;
import javafx.scene.layout.Priority;
import javafx.scene.layout.VBox;
import org.jackhuang.hmcl.setting.CuboxMode;
import org.jackhuang.hmcl.theme.ThemeColor;
import org.jackhuang.hmcl.ui.construct.DialogCloseEvent;

import static org.jackhuang.hmcl.util.i18n.I18n.i18n;

/// **ARCHIVED / hibernated.** Cubox currently ships as an offline-only launcher
/// (see `org.jackhuang.hmcl.setting.Cubox#OFFLINE_ONLY`); this chooser is no
/// longer shown. It is kept so the online mode ("CuboxPO") can be revived later.
///
/// First-run (and on-demand) chooser between the two Cubox modes.
///
/// Presents two large colored cards — CuboxFO (offline, cyan) and CuboxPO
/// (online, amber). Picking one calls [CuboxMode#select], which persists the
/// choice and applies the matching brand accent so the launcher immediately
/// takes on the Cubox color.
public final class CuboxModeSelectionPane extends JFXDialogLayout {

    /// Builds the chooser.
    ///
    /// @param firstRun when `true`, the dialog is mandatory (no cancel button):
    ///                 the user must pick a mode. When `false` (opened later to
    ///                 switch modes), a cancel button is shown.
    public CuboxModeSelectionPane(boolean firstRun) {
        setHeading(new Label(i18n("cubox.mode.title")));

        HBox cards = new HBox(16);
        cards.setAlignment(Pos.CENTER);
        cards.getChildren().addAll(
                createCard(CuboxMode.OFFLINE),
                createCard(CuboxMode.ONLINE));

        VBox body = new VBox(12);
        body.getChildren().addAll(new Label(i18n("cubox.mode.hint")), cards);
        setBody(body);

        if (!firstRun) {
            JFXButton cancel = new JFXButton(i18n("button.cancel"));
            cancel.getStyleClass().add("dialog-cancel");
            cancel.setOnAction(e -> fireEvent(new DialogCloseEvent()));
            setActions(cancel);
        }
    }

    /// Builds a single clickable mode card tinted with the mode's brand accent.
    private JFXButton createCard(CuboxMode mode) {
        String accent = ThemeColor.getColorDisplayName(mode.getAccent().color());

        Label title = new Label(i18n(mode.getDisplayKey()));
        title.setStyle("-fx-font-size: 18px; -fx-font-weight: bold; -fx-text-fill: " + accent + ";");

        Label desc = new Label(i18n(mode.getDisplayKey() + ".desc"));
        desc.setWrapText(true);
        desc.setMaxWidth(220);

        VBox content = new VBox(8, title, desc);
        content.setAlignment(Pos.TOP_LEFT);

        JFXButton card = new JFXButton();
        card.setGraphic(content);
        card.setPrefWidth(260);
        card.setPrefHeight(150);
        card.setStyle("-fx-border-color: " + accent + "; -fx-border-width: 2px; "
                + "-fx-border-radius: 8px; -fx-background-radius: 8px; -fx-padding: 16px;");
        HBox.setHgrow(card, Priority.ALWAYS);
        card.setOnAction(e -> {
            CuboxMode.select(mode);
            fireEvent(new DialogCloseEvent());
        });
        return card;
    }
}
