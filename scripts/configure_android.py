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
icon.write_text('''<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="64dp" android:height="64dp" android:viewportWidth="64" android:viewportHeight="64">
    <path android:fillColor="#103D31" android:pathData="M20,0 L44,0 Q64,0 64,20 L64,44 Q64,64 44,64 L20,64 Q0,64 0,44 L0,20 Q0,0 20,0 Z" />
    <path android:fillColor="@android:color/transparent" android:strokeColor="#F5F8EC" android:strokeWidth="3" android:pathData="M17,22.5 L47,22.5 A5,5 0,0 1,52 27.5 L52,44.5 A6,6 0,0 1,46 50.5 L18,50.5 A6,6 0,0 1,12 44.5 L12,27.5 A5,5 0,0 1,17 22.5 Z" />
    <path android:fillColor="@android:color/transparent" android:strokeColor="#F5F8EC" android:strokeWidth="3" android:strokeLineCap="round" android:strokeLineJoin="round" android:pathData="M17,22 L20.2,17 L28.7,17 L31.8,22 M40,36 A8,8 0,1 1,24 36 A8,8 0,1 1,40 36" />
    <path android:fillColor="#D3F47D" android:pathData="M40,18.5 C40,12.4 44.8,9 51.5,9 C51.5,15.4 47,19.7 40,18.5 Z" />
    <path android:fillColor="@android:color/transparent" android:strokeColor="#D3F47D" android:strokeWidth="2.5" android:strokeLineCap="round" android:pathData="M37.5,22.5 C38.2,19.1 40.9,16.3 45.2,14.3" />
</vector>
''', encoding="utf-8")
print("Android branding, network access, and GPS permissions configured.")
