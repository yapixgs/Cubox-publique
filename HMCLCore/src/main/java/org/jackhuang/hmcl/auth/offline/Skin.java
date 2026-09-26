/*
 * Hello Minecraft! Launcher
 * Copyright (C) 2020  huangyuhui <huanghongxun2008@126.com> and contributors
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
package org.jackhuang.hmcl.auth.offline;

import com.google.gson.annotations.SerializedName;
import javafx.scene.image.Image;
import org.jackhuang.hmcl.auth.yggdrasil.TextureModel;
import org.jackhuang.hmcl.task.FetchTask;
import org.jackhuang.hmcl.task.GetTask;
import org.jackhuang.hmcl.task.Task;
import org.jackhuang.hmcl.util.Lang;
import org.jackhuang.hmcl.util.StringUtils;
import org.jackhuang.hmcl.util.gson.JsonUtils;
import org.jackhuang.hmcl.util.io.FileUtils;
import org.jackhuang.hmcl.util.io.NetworkUtils;
import org.jackhuang.hmcl.util.io.UrlResponseInfo;
import org.jetbrains.annotations.Nullable;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;

import static org.jackhuang.hmcl.util.Lang.mapOf;
import static org.jackhuang.hmcl.util.Lang.tryCast;
import static org.jackhuang.hmcl.util.Pair.pair;

public class Skin {

    public enum Type {
        DEFAULT,
        ALEX,
        ARI,
        EFE,
        KAI,
        MAKENA,
        NOOR,
        STEVE,
        SUNNY,
        ZURI,
        LOCAL_FILE,
        LITTLE_SKIN,
        ELY_BY,
        CUSTOM_SKIN_LOADER_API,
        YGGDRASIL_API;

        public static Type fromStorage(String type) {
            switch (type) {
                case "default":
                    return DEFAULT;
                case "alex":
                    return ALEX;
                case "ari":
                    return ARI;
                case "efe":
                    return EFE;
                case "kai":
                    return KAI;
                case "makena":
                    return MAKENA;
                case "noor":
                    return NOOR;
                case "steve":
                    return STEVE;
                case "sunny":
                    return SUNNY;
                case "zuri":
                    return ZURI;
                case "local_file":
                    return LOCAL_FILE;
                case "little_skin":
                    return LITTLE_SKIN;
                case "ely_by":
                    return ELY_BY;
                case "custom_skin_loader_api":
                    return CUSTOM_SKIN_LOADER_API;
                case "yggdrasil_api":
                    return YGGDRASIL_API;
                default:
                    return null;
            }
        }
    }

    private final Type type;
    private final String cslApi;
    private final TextureModel textureModel;
    private final String localSkinPath;
    private final String localCapePath;

    public Skin(Type type, String cslApi, TextureModel textureModel, String localSkinPath, String localCapePath) {
        this.type = type;
        this.cslApi = cslApi;
        this.textureModel = textureModel;
        this.localSkinPath = localSkinPath;
        this.localCapePath = localCapePath;
    }

    public Type getType() {
        return type;
    }

    public String getCslApi() {
        return cslApi;
    }

    public TextureModel getTextureModel() {
        return textureModel == null ? TextureModel.WIDE : textureModel;
    }

    public String getLocalSkinPath() {
        return localSkinPath;
    }

    public String getLocalCapePath() {
        return localCapePath;
    }

    public Task<LoadedSkin> load(String username) {
        switch (type) {
            case DEFAULT:
                return Task.supplyAsync(() -> null);
            case ALEX:
            case ARI:
            case EFE:
            case KAI:
            case MAKENA:
            case NOOR:
            case STEVE:
            case SUNNY:
            case ZURI:
                TextureModel model = this.textureModel != null ? this.textureModel : type == Type.ALEX ? TextureModel.SLIM : TextureModel.WIDE;
                String resource = (model == TextureModel.SLIM ? "/assets/img/skin/slim/" : "/assets/img/skin/wide/") + type.name().toLowerCase(Locale.ROOT) + ".png";

                return Task.supplyAsync(() -> new LoadedSkin(
                        model,
                        Texture.loadTexture(new Image(resource)),
                        null
                ));
            case LOCAL_FILE:
                return Task.supplyAsync(() -> {
                    Texture skin = null, cape = null;
                    Optional<Path> skinPath = FileUtils.tryGetPath(localSkinPath);
                    Optional<Path> capePath = FileUtils.tryGetPath(localCapePath);
                    if (skinPath.isPresent()) skin = Texture.loadTexture(Files.newInputStream(skinPath.get()));
                    if (capePath.isPresent()) cape = Texture.loadTexture(Files.newInputStream(capePath.get()));
                    return new LoadedSkin(getTextureModel(), skin, cape);
                });
            case LITTLE_SKIN:
            case CUSTOM_SKIN_LOADER_API:
                String realCslApi = type == Type.LITTLE_SKIN
                        ? "https://littleskin.cn/csl"
                        : NetworkUtils.addHttpsIfMissing(StringUtils.removeSuffix(Lang.requireNonNullElse(cslApi, ""), "/"));
                return Task.composeAsync(() -> new GetTask(String.format("%s/%s.json", realCslApi, username)))
                        .thenComposeAsync(json -> {
                            SkinJson result = JsonUtils.GSON.fromJson(json, SkinJson.class);

                            if (!result.hasSkin()) {
                                return Task.supplyAsync(() -> null);
                            }

                            return Task.allOf(
                                    Task.supplyAsync(result::getModel),
                                    result.getHash() == null ? Task.supplyAsync(() -> null) : new FetchBytesTask(String.format("%s/textures/%s", realCslApi, result.getHash())),
                                    result.getCapeHash() == null ? Task.supplyAsync(() -> null) : new FetchBytesTask(String.format("%s/textures/%s", realCslApi, result.getCapeHash()))
                            );
                        }).thenApplyAsync(result -> {
                            if (result == null) {
                                return null;
                            }

                            Texture skin, cape;
                            if (result.get(1) != null) {
                                skin = Texture.loadTexture((InputStream) result.get(1));
                            } else {
                                skin = null;
                            }

                            if (result.get(2) != null) {
                                cape = Texture.loadTexture((InputStream) result.get(2));
                            } else {
                                cape = null;
                            }

                            return new LoadedSkin((TextureModel) result.get(0), skin, cape);
                        });
            case ELY_BY:
                // Ely.by exposes an unauthenticated, by-username texture endpoint:
                //   GET http://skinsystem.ely.by/textures/<username>
                //   -> {"SKIN":{"url":...,"metadata":{"model":"slim"}?},"CAPE":{"url":...}?}
                //   (HTTP 204 with an empty body when the username has no skin)
                return Task.composeAsync(() -> new GetTask("http://skinsystem.ely.by/textures/" + username))
                        .thenComposeAsync(json -> {
                            if (StringUtils.isBlank(json)) {
                                return Task.supplyAsync(() -> null);
                            }

                            ElyByTextures textures = JsonUtils.GSON.fromJson(json, ElyByTextures.class);
                            if (textures == null || textures.skin == null || textures.skin.url == null) {
                                return Task.supplyAsync(() -> null);
                            }

                            TextureModel elyModel = textures.skin.metadata != null && "slim".equals(textures.skin.metadata.model)
                                    ? TextureModel.SLIM : TextureModel.WIDE;
                            String elyCapeUrl = textures.cape != null ? textures.cape.url : null;

                            return Task.allOf(
                                    Task.supplyAsync(() -> elyModel),
                                    new FetchBytesTask(textures.skin.url),
                                    elyCapeUrl == null ? Task.supplyAsync(() -> null) : new FetchBytesTask(elyCapeUrl)
                            );
                        }).thenApplyAsync(result -> {
                            if (result == null) {
                                return null;
                            }

                            Texture skin = result.get(1) != null ? Texture.loadTexture((InputStream) result.get(1)) : null;
                            Texture cape = result.get(2) != null ? Texture.loadTexture((InputStream) result.get(2)) : null;
                            return new LoadedSkin((TextureModel) result.get(0), skin, cape);
                        });
            default:
                throw new UnsupportedOperationException();
        }
    }

    public Map<?, ?> toStorage() {
        return mapOf(
                pair("type", type.name().toLowerCase(Locale.ROOT)),
                pair("cslApi", cslApi),
                pair("textureModel", getTextureModel().modelName),
                pair("localSkinPath", localSkinPath),
                pair("localCapePath", localCapePath)
        );
    }

    public static Skin fromStorage(Map<?, ?> storage) {
        if (storage == null) return null;

        Type type = tryCast(storage.get("type"), String.class).flatMap(t -> Optional.ofNullable(Type.fromStorage(t)))
                .orElse(Type.DEFAULT);
        String cslApi = tryCast(storage.get("cslApi"), String.class).orElse(null);
        String textureModel = tryCast(storage.get("textureModel"), String.class).orElse("default");
        String localSkinPath = tryCast(storage.get("localSkinPath"), String.class).orElse(null);
        String localCapePath = tryCast(storage.get("localCapePath"), String.class).orElse(null);

        return new Skin(type, cslApi, "slim".equals(textureModel) ? TextureModel.SLIM : TextureModel.WIDE, localSkinPath, localCapePath);
    }

    private static class FetchBytesTask extends FetchTask<InputStream> {

        public FetchBytesTask(String uri) {
            super(List.of(NetworkUtils.toURI(uri)));
        }

        @Override
        protected void useCachedResult(Path cachedFile) throws IOException {
            setResult(Files.newInputStream(cachedFile));
        }

        @Override
        protected EnumCheckETag shouldCheckETag() {
            return EnumCheckETag.CHECK_E_TAG;
        }

        @Override
        protected Context getContext(@Nullable HttpResponse<?> response, boolean checkETag, String bmclapiHash) throws IOException {
            return new Context() {
                final ByteArrayOutputStream baos = new ByteArrayOutputStream();

                @Override
                public void reset() throws IOException {
                    baos.reset();
                }

                @Override
                public void write(byte[] buffer, int offset, int len) {
                    baos.write(buffer, offset, len);
                }

                @Override
                public void close() throws IOException {
                    if (!isSuccess()) return;

                    setResult(new ByteArrayInputStream(baos.toByteArray()));

                    if (checkETag) {
                        repository.cacheBytes(UrlResponseInfo.of(response), baos.toByteArray());
                    }
                }
            };
        }
    }

    public static class LoadedSkin {
        private final TextureModel model;
        private final Texture skin;
        private final Texture cape;

        public LoadedSkin(TextureModel model, Texture skin, Texture cape) {
            this.model = model;
            this.skin = skin;
            this.cape = cape;
        }

        public TextureModel getModel() {
            return model;
        }

        public Texture getSkin() {
            return skin;
        }

        public Texture getCape() {
            return cape;
        }
    }

    /// Ely.by texture response returned by `http://skinsystem.ely.by/textures/<username>`.
    /// Shape: `{"SKIN":{"url":...,"metadata":{"model":"slim"}?},"CAPE":{"url":...}?}`.
    private static final class ElyByTextures {
        /// The skin texture, or `null` when the username has no skin.
        @SerializedName("SKIN")
        private @Nullable ElyByTexture skin;
        /// The cape texture, or `null` when the username has no cape.
        @SerializedName("CAPE")
        private @Nullable ElyByTexture cape;
    }

    /// A single Ely.by texture entry (skin or cape).
    private static final class ElyByTexture {
        /// The absolute URL of the PNG texture.
        private @Nullable String url;
        /// Optional metadata; carries the arm model ("slim") for skins.
        private @Nullable ElyByMetadata metadata;
    }

    /// Optional Ely.by texture metadata; `model` is "slim" for the Alex model.
    private static final class ElyByMetadata {
        /// The arm model, "slim" for Alex; absent/other means the classic model.
        private @Nullable String model;
    }

    private static class SkinJson {
        private final String username;
        private final String skin;
        private final String cape;
        private final String elytra;

        @SerializedName(value = "textures", alternate = { "skins" })
        private final TextureJson textures;

        public SkinJson(String username, String skin, String cape, String elytra, TextureJson textures) {
            this.username = username;
            this.skin = skin;
            this.cape = cape;
            this.elytra = elytra;
            this.textures = textures;
        }

        public boolean hasSkin() {
            return StringUtils.isNotBlank(username);
        }

        @Nullable
        public TextureModel getModel() {
            if (textures != null && textures.slim != null) {
                return TextureModel.SLIM;
            } else if (textures != null && textures.defaultSkin != null) {
                return TextureModel.WIDE;
            } else {
                return null;
            }
        }

        public String getAlexModelHash() {
            if (textures != null && textures.slim != null) {
                return textures.slim;
            } else {
                return null;
            }
        }

        public String getSteveModelHash() {
            if (textures != null && textures.defaultSkin != null) {
                return textures.defaultSkin;
            } else return skin;
        }

        public String getHash() {
            TextureModel model = getModel();
            if (model == TextureModel.SLIM)
                return getAlexModelHash();
            else if (model == TextureModel.WIDE)
                return getSteveModelHash();
            else
                return null;
        }

        public String getCapeHash() {
            if (textures != null && textures.cape != null) {
                return textures.cape;
            } else return cape;
        }

        public static class TextureJson {
            @SerializedName("default")
            private final String defaultSkin;

            private final String slim;
            private final String cape;
            private final String elytra;

            public TextureJson(String defaultSkin, String slim, String cape, String elytra) {
                this.defaultSkin = defaultSkin;
                this.slim = slim;
                this.cape = cape;
                this.elytra = elytra;
            }
        }
    }
}
