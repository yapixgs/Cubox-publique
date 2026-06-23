/*
 * Hello Minecraft! Launcher
 * Copyright (C) 2021  huangyuhui <huanghongxun2008@126.com> and contributors
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
package org.jackhuang.hmcl.ui.download;

import com.jfoenix.controls.JFXButton;
import javafx.beans.property.ReadOnlyObjectProperty;
import javafx.beans.property.ReadOnlyObjectWrapper;
import javafx.scene.Node;
import org.jackhuang.hmcl.download.*;
import org.jackhuang.hmcl.download.game.GameRemoteVersion;
import org.jackhuang.hmcl.mod.RemoteMod;
import org.jackhuang.hmcl.mod.curse.CurseForgeRemoteModRepository;
import org.jackhuang.hmcl.setting.DownloadProviders;
import org.jackhuang.hmcl.setting.Profile;
import org.jackhuang.hmcl.setting.Profiles;
import org.jackhuang.hmcl.task.FileDownloadTask;
import org.jackhuang.hmcl.task.Schedulers;
import org.jackhuang.hmcl.task.Task;
import org.jackhuang.hmcl.ui.Controllers;
import org.jackhuang.hmcl.ui.FXUtils;
import org.jackhuang.hmcl.ui.SVG;
import org.jackhuang.hmcl.ui.WeakListenerHolder;
import org.jackhuang.hmcl.ui.animation.TransitionPane;
import org.jackhuang.hmcl.ui.construct.AdvancedListBox;
import org.jackhuang.hmcl.ui.construct.MessageDialogPane;
import org.jackhuang.hmcl.ui.construct.TabHeader;
import org.jackhuang.hmcl.ui.construct.Validator;
import org.jackhuang.hmcl.ui.decorator.DecoratorAnimatedPage;
import org.jackhuang.hmcl.ui.decorator.DecoratorPage;
import org.jackhuang.hmcl.ui.versions.DownloadListPage;
import org.jackhuang.hmcl.ui.versions.HMCLLocalizedDownloadListPage;
import org.jackhuang.hmcl.ui.versions.VersionPage;
import org.jackhuang.hmcl.ui.versions.Versions;
import org.jackhuang.hmcl.ui.wizard.Navigation;
import org.jackhuang.hmcl.ui.wizard.WizardController;
import org.jackhuang.hmcl.ui.wizard.WizardProvider;
import org.jackhuang.hmcl.util.SettingsMap;
import org.jackhuang.hmcl.util.TaskCancellationAction;
import org.jackhuang.hmcl.util.io.FileUtils;
import org.jetbrains.annotations.Nullable;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;
import java.util.Set;
import java.util.concurrent.CancellationException;
import java.util.function.Supplier;
import java.util.stream.Collectors;

import static org.jackhuang.hmcl.ui.FXUtils.runInFX;
import static org.jackhuang.hmcl.util.i18n.I18n.i18n;
import static org.jackhuang.hmcl.util.logging.Logger.LOG;

public class DownloadPage extends DecoratorAnimatedPage implements DecoratorPage {
    public static final org.jackhuang.hmcl.ui.versions.DownloadPage.DownloadCallback FOR_MOD =
            (downloadProvider, profile, version, mod, file) -> download(downloadProvider, profile, version, file, "mods");
    public static final org.jackhuang.hmcl.ui.versions.DownloadPage.DownloadCallback FOR_RESOURCE_PACK =
            (downloadProvider, profile, version, mod, file) -> download(downloadProvider, profile, version, file, "resourcepacks");
    public static final org.jackhuang.hmcl.ui.versions.DownloadPage.DownloadCallback FOR_SHADER =
            (downloadProvider, profile, version, mod, file) -> download(downloadProvider, profile, version, file, "shaderpacks");

    private final ReadOnlyObjectWrapper<DecoratorPage.State> state = new ReadOnlyObjectWrapper<>(DecoratorPage.State.fromTitle(i18n("download"), -1));
    private final TabHeader tab;
    private final TabHeader.Tab<VersionsPage> newGameTab = new TabHeader.Tab<>("newGameTab");
    // Sources séparées : un onglet par (type de contenu × source) — Modrinth (mr) / CurseForge (cf).
    private final TabHeader.Tab<DownloadListPage> mrModpackTab = new TabHeader.Tab<>("mrModpackTab");
    private final TabHeader.Tab<DownloadListPage> mrModTab = new TabHeader.Tab<>("mrModTab");
    private final TabHeader.Tab<DownloadListPage> mrResourcePackTab = new TabHeader.Tab<>("mrResourcePackTab");
    private final TabHeader.Tab<DownloadListPage> mrShaderTab = new TabHeader.Tab<>("mrShaderTab");
    private final TabHeader.Tab<DownloadListPage> cfModpackTab = new TabHeader.Tab<>("cfModpackTab");
    private final TabHeader.Tab<DownloadListPage> cfModTab = new TabHeader.Tab<>("cfModTab");
    private final TabHeader.Tab<DownloadListPage> cfResourcePackTab = new TabHeader.Tab<>("cfResourcePackTab");
    private final TabHeader.Tab<DownloadListPage> cfShaderTab = new TabHeader.Tab<>("cfShaderTab");
    private final TabHeader.Tab<DownloadListPage> worldTab = new TabHeader.Tab<>("worldTab");
    private final TransitionPane transitionPane = new TransitionPane();
    private final DownloadNavigator versionPageNavigator = new DownloadNavigator();

    private WeakListenerHolder listenerHolder;

    public DownloadPage() {
        this(null);
    }

    public DownloadPage(String uploadVersion) {
        newGameTab.setNodeSupplier(loadVersionFor(() -> new VersionsPage(versionPageNavigator, i18n("install.installer.choose", i18n("install.installer.game")), "", DownloadProviders.getDownloadProvider(),
                "game", versionPageNavigator::onGameSelected)));
        org.jackhuang.hmcl.ui.versions.DownloadPage.DownloadCallback modpackCallback =
                (downloadProvider, profile, __, mod, file) ->
                        Versions.downloadModpackImpl(downloadProvider, profile, uploadVersion, mod, file);

        mrModpackTab.setNodeSupplier(loadVersionFor(() -> withImportModpack(HMCLLocalizedDownloadListPage.ofModrinthModPack(modpackCallback, false))));
        cfModpackTab.setNodeSupplier(loadVersionFor(() -> withImportModpack(HMCLLocalizedDownloadListPage.ofCurseForgeModPack(modpackCallback, false))));
        mrModTab.setNodeSupplier(loadVersionFor(() -> HMCLLocalizedDownloadListPage.ofModrinthMod(FOR_MOD, true)));
        cfModTab.setNodeSupplier(loadVersionFor(() -> HMCLLocalizedDownloadListPage.ofCurseForgeMod(FOR_MOD, true)));
        mrResourcePackTab.setNodeSupplier(loadVersionFor(() -> HMCLLocalizedDownloadListPage.ofModrinthResourcePack(FOR_RESOURCE_PACK, true)));
        cfResourcePackTab.setNodeSupplier(loadVersionFor(() -> HMCLLocalizedDownloadListPage.ofCurseForgeResourcePack(FOR_RESOURCE_PACK, true)));
        mrShaderTab.setNodeSupplier(loadVersionFor(() -> HMCLLocalizedDownloadListPage.ofModrinthShaderPack(FOR_SHADER, true)));
        cfShaderTab.setNodeSupplier(loadVersionFor(() -> HMCLLocalizedDownloadListPage.ofCurseForgeShaderPack(FOR_SHADER, true)));
        worldTab.setNodeSupplier(loadVersionFor(() -> new DownloadListPage(CurseForgeRemoteModRepository.WORLDS)));
        tab = new TabHeader(transitionPane, newGameTab,
                mrModpackTab, mrModTab, mrResourcePackTab, mrShaderTab,
                cfModpackTab, cfModTab, cfResourcePackTab, cfShaderTab, worldTab);

        Profiles.registerVersionsListener(this::loadVersions);

        tab.select(newGameTab);

        // Sources d'installation séparées en sections claires : Modrinth / CurseForge.
        AdvancedListBox sideBar = new AdvancedListBox()
                .startCategory(i18n("download.game").toUpperCase(Locale.ROOT))
                .addNavigationDrawerTab(tab, newGameTab, i18n("game"), SVG.STADIA_CONTROLLER, SVG.STADIA_CONTROLLER_FILL)
                .startCategory(i18n("mods.modrinth").toUpperCase(Locale.ROOT))
                .addNavigationDrawerTab(tab, mrModpackTab, i18n("modpack"), SVG.PACKAGE2, SVG.PACKAGE2_FILL)
                .addNavigationDrawerTab(tab, mrModTab, i18n("mods"), SVG.EXTENSION, SVG.EXTENSION_FILL)
                .addNavigationDrawerTab(tab, mrResourcePackTab, i18n("resourcepack"), SVG.TEXTURE)
                .addNavigationDrawerTab(tab, mrShaderTab, i18n("download.shader"), SVG.WB_SUNNY, SVG.WB_SUNNY_FILL);
        if (CurseForgeRemoteModRepository.isAvailable()) {
            sideBar.startCategory(i18n("mods.curseforge").toUpperCase(Locale.ROOT))
                    .addNavigationDrawerTab(tab, cfModpackTab, i18n("modpack"), SVG.PACKAGE2, SVG.PACKAGE2_FILL)
                    .addNavigationDrawerTab(tab, cfModTab, i18n("mods"), SVG.EXTENSION, SVG.EXTENSION_FILL)
                    .addNavigationDrawerTab(tab, cfResourcePackTab, i18n("resourcepack"), SVG.TEXTURE)
                    .addNavigationDrawerTab(tab, cfShaderTab, i18n("download.shader"), SVG.WB_SUNNY, SVG.WB_SUNNY_FILL)
                    .addNavigationDrawerTab(tab, worldTab, i18n("world"), SVG.PUBLIC);
        }
        FXUtils.setLimitWidth(sideBar, 200);
        setLeft(sideBar);

        setCenter(transitionPane);
    }

    /// Adds the "install local modpack" button to a modpack browse page.
    private static DownloadListPage withImportModpack(DownloadListPage page) {
        JFXButton installLocalModpackButton = FXUtils.newRaisedButton(i18n("install.modpack"));
        installLocalModpackButton.setOnAction(e -> Versions.importModpack());
        page.getActions().add(installLocalModpackButton);
        return page;
    }

    private static <T extends Node> Supplier<T> loadVersionFor(Supplier<T> nodeSupplier) {
        return () -> {
            T node = nodeSupplier.get();
            if (node instanceof VersionPage.VersionLoadable) {
                ((VersionPage.VersionLoadable) node).loadVersion(Profiles.getSelectedProfile(), null);
            }
            return node;
        };
    }

    public static void download(DownloadProvider downloadProvider, Profile profile, @Nullable String version, RemoteMod.Version file, String subdirectoryName) {
        if (version == null) version = profile.getSelectedVersion();

        Path runDirectory = profile.getRepository().hasVersion(version) ? profile.getRepository().getRunDirectory(version) : profile.getRepository().getBaseDirectory();

        Set<String> existingFiles;

        try (var list = Files.list(runDirectory.resolve(subdirectoryName))) {
            existingFiles = list.map(Path::getFileName)
                    .map(Path::toString)
                    .collect(Collectors.toSet());
        } catch (IOException e) {
            LOG.warning("Failed to list files in " + runDirectory.resolve(subdirectoryName), e);
            existingFiles = Set.of();
        }

        Set<String> finalExistingFiles = existingFiles;

        Controllers.prompt(i18n("archive.file.name"), (result, handler) -> {
            Path dest = runDirectory.resolve(subdirectoryName).resolve(result);

            Controllers.taskDialog(Task.composeAsync(() -> {
                var task = new FileDownloadTask(downloadProvider.injectURLWithCandidates(file.getFile().getUrl()), dest);
                task.setName(file.getName());
                return task;
            }).whenComplete(Schedulers.javafx(), exception -> {
                if (exception != null) {
                    if (exception instanceof CancellationException) {
                        Controllers.showToast(i18n("message.cancelled"));
                    } else {
                        Controllers.dialog(DownloadProviders.localizeErrorMessage(exception), i18n("install.failed.downloading"), MessageDialogPane.MessageType.ERROR);
                    }
                } else {
                    Controllers.showToast(i18n("install.success"));
                }
            }), i18n("message.downloading"), TaskCancellationAction.NORMAL);
            handler.resolve();
        }, file.getFile().getFilename(), new Validator(i18n("install.new_game.malformed"), FileUtils::isNameValidForJar), new Validator(i18n("profile.already_exists"), (it) -> !finalExistingFiles.contains(it)));

    }

    private void loadVersions(Profile profile) {
        listenerHolder = new WeakListenerHolder();
        runInFX(() -> {
            if (profile == Profiles.getSelectedProfile()) {
                listenerHolder.add(FXUtils.onWeakChangeAndOperate(profile.selectedVersionProperty(), version -> {
                    for (TabHeader.Tab<DownloadListPage> contentTab : java.util.List.of(
                            mrModpackTab, mrModTab, mrResourcePackTab, mrShaderTab,
                            cfModpackTab, cfModTab, cfResourcePackTab, cfShaderTab, worldTab)) {
                        if (contentTab.isInitialized()) {
                            contentTab.getNode().loadVersion(profile, null);
                        }
                    }
                }));
            }
        });
    }

    @Override
    public ReadOnlyObjectProperty<State> stateProperty() {
        return state.getReadOnlyProperty();
    }

    public void showGameDownloads() {
        tab.select(newGameTab, false);
    }

    public void showModpackDownloads() {
        tab.select(mrModpackTab, false);
    }

    public DownloadListPage showResourcePackDownloads() {
        tab.select(mrResourcePackTab, false);
        return mrResourcePackTab.getNode();
    }

    public DownloadListPage showModDownloads() {
        tab.select(mrModTab, false);
        return mrModTab.getNode();
    }

    public void showWorldDownloads() {
        tab.select(worldTab, false);
    }

    private static final class DownloadNavigator implements Navigation {
        private final SettingsMap settings = new SettingsMap();

        @Override
        public void onStart() {

        }

        @Override
        public void onNext() {

        }

        @Override
        public void onPrev(boolean cleanUp) {
        }

        @Override
        public boolean canPrev() {
            return false;
        }

        @Override
        public void onFinish() {

        }

        @Override
        public void onEnd() {

        }

        @Override
        public void onCancel() {

        }

        @Override
        public SettingsMap getSettings() {
            return settings;
        }

        public void onGameSelected() {
            Profile profile = Profiles.getSelectedProfile();
            if (profile.getRepository().isLoaded()) {
                Controllers.getDecorator().startWizard(new VanillaInstallWizardProvider(profile, (GameRemoteVersion) settings.get("game")), i18n("install.new_game"));
            }
        }

    }

    private static class VanillaInstallWizardProvider implements WizardProvider {
        private final Profile profile;
        private final DefaultDependencyManager dependencyManager;
        private final DownloadProvider downloadProvider;
        private final GameRemoteVersion gameVersion;

        public VanillaInstallWizardProvider(Profile profile, GameRemoteVersion gameVersion) {
            this.profile = profile;
            this.gameVersion = gameVersion;
            this.downloadProvider = DownloadProviders.getDownloadProvider();
            this.dependencyManager = profile.getDependency(downloadProvider);
        }

        @Override
        public void start(SettingsMap settings) {
            settings.put(ModpackPage.PROFILE, profile);
            settings.put(LibraryAnalyzer.LibraryType.MINECRAFT.getPatchId(), gameVersion);
        }

        private Task<Void> finishVersionDownloadingAsync(SettingsMap settings) {
            GameBuilder builder = dependencyManager.gameBuilder();

            String name = (String) settings.get("name");
            builder.name(name);
            builder.gameVersion(((RemoteVersion) settings.get(LibraryAnalyzer.LibraryType.MINECRAFT.getPatchId())).getGameVersion());

            settings.asStringMap().forEach((key, value) -> {
                if (!LibraryAnalyzer.LibraryType.MINECRAFT.getPatchId().equals(key)
                        && value instanceof RemoteVersion remoteVersion)
                    builder.version(remoteVersion);
            });

            return builder.buildAsync().whenComplete(any -> profile.getRepository().refreshVersions())
                    .thenRunAsync(Schedulers.javafx(), () -> profile.setSelectedVersion(name));
        }

        @Override
        public Object finish(SettingsMap settings) {
            settings.put("title", i18n("install.new_game.installation"));
            settings.put("success_message", i18n("install.success"));
            settings.put(FailureCallback.KEY, (settings1, exception, next) -> UpdateInstallerWizardProvider.alertFailureMessage(exception, next));

            return finishVersionDownloadingAsync(settings);
        }

        @Override
        public Node createPage(WizardController controller, int step, SettingsMap settings) {
            switch (step) {
                case 0:
                    return new InstallersPage(controller, profile.getRepository(), ((RemoteVersion) controller.getSettings().get("game")).getGameVersion(), downloadProvider);
                default:
                    throw new IllegalStateException("error step " + step + ", settings: " + settings + ", pages: " + controller.getPages());
            }
        }

        @Override
        public boolean cancel() {
            return true;
        }
    }
}
