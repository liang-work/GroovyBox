import json, subprocess, sys

def load_config():
    with open("build-config.json", encoding="utf-8") as f:
        return json.load(f)

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
    if platform in ("apk", "aab"):
        for perm in android.get("permissions", []):
            cmd += ["--android-permissions", f"{perm}=true"]
        bg = android.get("adaptive_icon_background")
        if bg:
            cmd += ["--android-adaptive-icon-background", bg]
    return cmd

if __name__ == "__main__":
    platform = sys.argv[1] if len(sys.argv) > 1 else "windows"
    import os
    plat = os.environ.get("TARGET_PLATFORM", platform)
    cmd = build_cmd(plat)
    print("Running:", " ".join(cmd))
    subprocess.run(cmd, check=True)
