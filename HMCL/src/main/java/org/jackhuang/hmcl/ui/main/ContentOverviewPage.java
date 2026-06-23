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
package org.jackhuang.hmcl.ui.main;

import javafx.beans.property.ReadOnlyObjectProperty;
import javafx.beans.property.ReadOnlyObjectWrapper;
import javafx.geometry.Insets;
import javafx.scene.control.Label;
import javafx.scene.control.ScrollPane;
import javafx.scene.layout.VBox;
import org.jackhuang.hmcl.game.Version;
import org.jackhuang.hmcl.game.World;
import org.jackhuang.hmcl.mod.LocalModFile;
import org.jackhuang.hmcl.mod.ModManager;
import org.jackhuang.hmcl.setting.Profile;
import org.jackhuang.hmcl.setting.Profiles;
import org.jackhuang.hmcl.task.Schedulers;
import org.jackhuang.hmcl.ui.FXUtils;
import org.jackhuang.hmcl.ui.SVG;
import org.jackhuang.hmcl.ui.construct.AdvancedListBox;
import org.jackhuang.hmcl.ui.construct.AdvancedListItem;
import org.jackhuang.hmcl.ui.construct.TabHeader;
import org.jackhuang.hmcl.ui.animation.TransitionPane;
import org.jackhuang.hmcl.ui.decorator.DecoratorAnimatedPage;
import org.jackhuang.hmcl.ui.decorator.DecoratorPage;
import org.jackhuang.hmcl.ui.versions.Versions;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.CompletableFuture;

import static org.jackhuang.hmcl.util.i18n.I18n.i18n;
import static org.jackhuang.hmcl.util.logging.Logger.LOG;

/// Unified, cross-instance overview of installed content (mods and worlds).
///
/// Instead of digging into each instance, this page lists every mod and every
/// world from all instances in one place, each tagged with the instance it
/// belongs to. Clicking an item jumps to that instance's detailed manager.
public final class ContentOverviewPage extends DecoratorAnimatedPage implements DecoratorPage {

    private final ReadOnlyObjectWrapper<State> state =
            new ReadOnlyObjectWrapper<>(State.fromTitle(i18n("cubox.content"), -1));

    private final TabHeader tab;
    private final TabHeader.Tab<ScrollPane> modsTab = new TabHeader.Tab<>("modsTab");
    private final TabHeader.Tab<ScrollPane> worldsTab = new TabHeader.Tab<>("worldsTab");
    private final TransitionPane transitionPane = new TransitionPane();

    private final VBox modsBox = new VBox(4);
    private final VBox worldsBox = new VBox(4);

    public ContentOverviewPage() {
        modsBox.setPadding(new Insets(10));
        worldsBox.setPadding(new Insets(10));

        ScrollPane modsScroll = new ScrollPane(modsBox);
        modsScroll.setFitToWidth(true);
        ScrollPane worldsScroll = new ScrollPane(worldsBox);
        worldsScroll.setFitToWidth(true);

        modsTab.setNodeSupplier(() -> modsScroll);
        worldsTab.setNodeSupplier(() -> worldsScroll);
        tab = new TabHeader(transitionPane, modsTab, worldsTab);
        tab.select(modsTab);

        AdvancedListBox sideBar = new AdvancedListBox()
                .startCategory(i18n("cubox.content").toUpperCase(Locale.ROOT))
                .addNavigationDrawerTab(tab, modsTab, i18n("mods.manage"), SVG.EXTENSION, SVG.EXTENSION_FILL)
                .addNavigationDrawerTab(tab, worldsTab, i18n("world.manage"), SVG.PUBLIC);
        FXUtils.setLimitWidth(sideBar, 200);
        setLeft(sideBar);
        setCenter(transitionPane);

        refresh();
    }

    /// Reloads the mod and world lists from every instance.
    public void refresh() {
        loadInto(modsBox, true);
        loadInto(worldsBox, false);
    }

    private void loadInto(VBox box, boolean mods) {
        box.getChildren().setAll(new Label(i18n("cubox.content.loading")));
        CompletableFuture.supplyAsync(() -> mods ? collectMods() : collectWorlds(), Schedulers.io())
                .whenCompleteAsync((rows, exception) -> {
                    box.getChildren().clear();
                    if (exception != null) {
                        LOG.warning("Failed to load content overview", exception);
                        box.getChildren().add(new Label(i18n("message.failed")));
                    } else if (rows.isEmpty()) {
                        box.getChildren().add(new Label(i18n("cubox.content.empty")));
                    } else {
                        for (Row row : rows) {
                            AdvancedListItem item = new AdvancedListItem();
                            item.setLeftIcon(mods ? SVG.EXTENSION : SVG.PUBLIC);
                            item.setTitle(row.name);
                            item.setSubtitle(row.instanceLabel);
                            Profile profile = row.profile;
                            String version = row.versionId;
                            item.setOnAction(e -> {
                                if (mods) {
                                    Versions.manageMods(profile, version);
                                } else {
                                    Versions.manageWorlds(profile, version);
                                }
                            });
                            box.getChildren().add(item);
                        }
                    }
                }, Schedulers.javafx());
    }

    private List<Row> collectMods() {
        List<Row> rows = new ArrayList<>();
        for (Profile profile : Profiles.getProfiles()) {
            var repository = profile.getRepository();
            if (!repository.isLoaded())
                continue;
            for (Version version : repository.getVersions()) {
                String id = version.getId();
                try {
                    ModManager modManager = repository.getModManager(id);
                    modManager.refresh();
                    for (LocalModFile file : modManager.getLocalFiles()) {
                        String name = file.getName() != null && !file.getName().isEmpty() ? file.getName() : file.getFileName();
                        rows.add(new Row(name, instanceLabel(profile, id), profile, id));
                    }
                } catch (Exception e) {
                    LOG.warning("Failed to read mods of instance " + id, e);
                }
            }
        }
        return rows;
    }

    private List<Row> collectWorlds() {
        List<Row> rows = new ArrayList<>();
        for (Profile profile : Profiles.getProfiles()) {
            var repository = profile.getRepository();
            if (!repository.isLoaded())
                continue;
            for (Version version : repository.getVersions()) {
                String id = version.getId();
                try {
                    World.getWorlds(repository.getSavesDirectory(id))
                            .forEach(world -> rows.add(new Row(world.getWorldName(), instanceLabel(profile, id), profile, id)));
                } catch (Exception e) {
                    LOG.warning("Failed to read worlds of instance " + id, e);
                }
            }
        }
        return rows;
    }

    private static String instanceLabel(Profile profile, String versionId) {
        String profileName = profile.getName();
        if (profileName == null || profileName.isEmpty() || Profiles.getProfiles().size() <= 1)
            return versionId;
        return profileName + " / " + versionId;
    }

    @Override
    public ReadOnlyObjectProperty<State> stateProperty() {
        return state.getReadOnlyProperty();
    }

    /// One row of the overview: a content item and the instance it belongs to.
    private static final class Row {
        final String name;
        final String instanceLabel;
        final Profile profile;
        final String versionId;

        Row(String name, String instanceLabel, Profile profile, String versionId) {
            this.name = name;
            this.instanceLabel = instanceLabel;
            this.profile = profile;
            this.versionId = versionId;
        }
    }
}
