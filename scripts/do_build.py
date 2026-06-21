import json, subprocess, sys, os, shutil

def load_config():
    with open("build-config.json", encoding="utf-8") as f:
        return json.load(f)

def copy_icons():
    src_ico = os.path.join("assets", "images", "icon.ico")
    src_png = os.path.join("assets", "images", "icon.png")
    dst_ico = os.path.join("assets", "icon.ico")
    dst_png = os.path.join("assets", "icon.png")
    if os.path.exists(src_ico) and not os.path.exists(dst_ico):
        shutil.copy2(src_ico, dst_ico)
        print(f"Copied {src_ico} -> {dst_ico}")
    if os.path.exists(src_png) and not os.path.exists(dst_png):
        shutil.copy2(src_png, dst_png)
        print(f"Copied {src_png} -> {dst_png}")

def build_cmd(platform: str):
    cfg = load_config()
    app = cfg["app"]
    android = cfg.get("android", {})

    cmd = [
        "flet", "build", platform,
        "--yes", "--no-rich-output", "--skip-flutter-doctor",
        "--project", app["project"],
        "--product", app["product"],
        "--description", app["description"],
        "--org", app["org"],
        "--bundle-id", app["bundle_id"],
        "--build-version", app["build_version"],
        "--build-number", str(app["build_number"]),
        "--module-name", app["module_name"],
    ]
    if app.get("company"):
        cmd += ["--company", app["company"]]
    if app.get("copyright"):
        cmd += ["--copyright", app["copyright"]]

    # Platform-specific
    if platform in ("apk", "aab"):
        for perm in android.get("permissions", []):
            cmd += ["--android-permissions", f"{perm}=true"]
        bg = android.get("adaptive_icon_background")
        if bg:
            cmd += ["--android-adaptive-icon-background", bg]
        # Signing (detect keystore file)
        ks = "keystore.jks"
        ks_pass = os.environ.get("ANDROID_KEYSTORE_PASSWORD", "")
        key_pass = os.environ.get("ANDROID_KEY_PASSWORD", "")
        key_alias = os.environ.get("ANDROID_KEY_ALIAS", "")
        if os.path.exists(ks) and os.path.getsize(ks) > 100 and ks_pass and key_alias:
            cmd += [
                "--android-signing-key-store", os.path.abspath(ks),
                "--android-signing-key-store-password", ks_pass,
                "--android-signing-key-password", key_pass or ks_pass,
                "--android-signing-key-alias", key_alias,
            ]
    return cmd

if __name__ == "__main__":
    platform = sys.argv[1] if len(sys.argv) > 1 else "windows"
    plat = os.environ.get("TARGET_PLATFORM", platform)
    copy_icons()
    cmd = build_cmd(plat)
    print("Running:", " ".join(cmd))
    subprocess.run(cmd, check=True)
