"""Apply CamPah branding and permissions after flutter create."""
from pathlib import Path
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "mobile" / "android" / "app" / "src"
NAMESPACE = "http://schemas.android.com/apk/res/android"
ET.register_namespace("android", NAMESPACE)
attribute = lambda name: f"{{{NAMESPACE}}}{name}"
manifest_path = ANDROID / "main" / "AndroidManifest.xml"
if not manifest_path.exists():
    raise SystemExit("Run flutter create --platforms=android --org=id.campah --project-name=campah_mobile --no-pub mobile first")
tree = ET.parse(manifest_path)
root = tree.getroot()
existing = {node.get(attribute("name")) for node in root.findall("uses-permission")}
for permission in ["INTERNET", "ACCESS_FINE_LOCATION", "ACCESS_COARSE_LOCATION"]:
    full_name = f"android.permission.{permission}"
    if full_name not in existing:
        root.insert(0, ET.Element("uses-permission", {attribute("name"): full_name}))
application = root.find("application")
application.set(attribute("label"), "CamPah")
application.set(attribute("icon"), "@drawable/campah_icon")
ET.indent(tree, space="    ")
tree.write(manifest_path, encoding="utf-8", xml_declaration=True)

debug = ANDROID / "debug" / "AndroidManifest.xml"
debug.parent.mkdir(parents=True, exist_ok=True)
debug.write_text('''<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <application android:usesCleartextTraffic="true" />
</manifest>
''', encoding="utf-8")
icon = ANDROID / "main" / "res" / "drawable" / "campah_icon.xml"
icon.parent.mkdir(parents=True, exist_ok=True)
icon.write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="48dp" android:height="48dp" android:viewportWidth="48" android:viewportHeight="48">
    <path android:fillColor="#195C38" android:pathData="M8,0 L40,0 Q48,0 48,8 L48,40 Q48,48 40,48 L8,48 Q0,48 0,40 L0,8 Q0,0 8,0" />
    <path android:fillColor="#FFFFFF" android:pathData="M17,13 L20,13 L21,10 L27,10 L28,13 L31,13 L31,16 L17,16 Z M18,18 L30,18 L29,36 L19,36 Z" />
    <path android:strokeColor="#195C38" android:strokeWidth="2" android:pathData="M22,21 L22,32 M26,21 L26,32" />
</vector>
''', encoding="utf-8")
print("Android branding, network access, and GPS permissions configured.")
