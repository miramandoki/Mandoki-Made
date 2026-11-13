#!/usr/bin/env bash
# READ-ONLY laptop scan (macOS). Deletes and moves nothing.
# Run:  bash laptop-scan.sh      Output: ~/Desktop/laptop-scan-report.txt
# Optional: brew install fdupes   (faster duplicate finder)

OUT="$HOME/Desktop/laptop-scan-report.txt"
exec > >(tee "$OUT") 2>&1
H="$HOME"
sec(){ printf '\n=================== %s ===================\n' "$1"; }

sec "1. DISK OVERVIEW"
df -h /System/Volumes/Data 2>/dev/null || df -h /

sec "2. TOP-LEVEL FOLDERS IN HOME (incl. hidden), biggest first"
du -sh "$H"/.[!.]* "$H"/* 2>/dev/null | sort -hr | head -30

sec "3. ~/Library BREAKDOWN (caches, app data, mail, iOS backups)"
du -sh "$H"/Library/* 2>/dev/null | sort -hr | head -15
echo "-- Caches:";         du -sh "$H"/Library/Caches/* 2>/dev/null | sort -hr | head -15
echo "-- Application Support:"; du -sh "$H"/Library/Application\ Support/* 2>/dev/null | sort -hr | head -15
echo "-- iPhone/iPad backups:"; du -sh "$H"/Library/Application\ Support/MobileSync/Backup/* 2>/dev/null
echo "-- Mail:";           du -sh "$H"/Library/Mail 2>/dev/null
echo "-- Messages attachments:"; du -sh "$H"/Library/Messages 2>/dev/null

sec "4. 40 BIGGEST FILES (>200 MB)"
find "$H" -type f -size +200M -not -path "*/Library/CloudStorage/*" -exec du -h {} + 2>/dev/null | sort -hr | head -40

sec "5. OLD FILES: >100 MB and untouched for 1+ year"
find "$H" -type f -size +100M -atime +365 -not -path "*/Library/*" -exec du -h {} + 2>/dev/null | sort -hr | head -30

sec "6. DOWNLOADS + DESKTOP + TRASH"
du -sh "$H/Downloads" "$H/Desktop" "$H/.Trash" 2>/dev/null
echo "-- Installers / archives in Downloads:"
find "$H/Downloads" -type f \( -name "*.dmg" -o -name "*.pkg" -o -name "*.zip" -o -name "*.iso" \) -exec du -h {} + 2>/dev/null | sort -hr | head -30

sec "7. DEV / APP JUNK (safe to regenerate)"
du -sh "$H/.npm" "$H/.cache" "$H/.docker" "$H/Library/Developer" "$H/.Trash" 2>/dev/null
find "$H" -type d -name node_modules -prune -exec du -sh {} + 2>/dev/null | sort -hr | head -15

sec "8. HIDDEN FOLDERS in home > 100 MB"
du -sh "$H"/.[!.]* 2>/dev/null | sort -hr | awk '{print}' | head -20

sec "9. DESIGN/RENDER FILES (Mandoki Made): .blend .max .psd .c4d .skp .fbx + render caches"
find "$H" -type f \( -iname "*.blend" -o -iname "*.max" -o -iname "*.psd" -o -iname "*.c4d" -o -iname "*.skp" -o -iname "*.fbx" -o -iname "*.exr" \) -size +100M -exec du -h {} + 2>/dev/null | sort -hr | head -30

sec "10. DUPLICATES (same content) in Documents, Desktop, Downloads, Pictures"
DIRS=("$H/Documents" "$H/Desktop" "$H/Downloads" "$H/Pictures")
if command -v fdupes >/dev/null; then
  fdupes -rS "${DIRS[@]}" 2>/dev/null | head -200
else
  echo "(fdupes not found, using slower checksum method; files >5 MB only)"
  find "${DIRS[@]}" -type f -size +5M -exec shasum {} + 2>/dev/null | sort | uniq -w40 -dD | head -200
fi

sec "11. CLOUD FOLDERS: what is online-only vs local"
ls "$H/Library/CloudStorage" 2>/dev/null
for d in "$H"/Library/CloudStorage/* "$H/Dropbox" "$H/Google Drive" "$H/iCloud Drive" "$H/Library/Mobile Documents/com~apple~CloudDocs"; do
  [ -d "$d" ] || continue
  echo "--- $d"
  du -sh "$d" 2>/dev/null
  echo "Files stored LOCALLY (taking space): $(find "$d" -type f -size +0 -exec stat -f '%b' {} + 2>/dev/null | awk '$1>0{n++} END{print n+0}')"
done

sec "12. FILES ONLY ON THIS LAPTOP (not in any cloud folder) - 20 biggest in Documents/Desktop"
find "$H/Documents" "$H/Desktop" -type f -size +20M -exec du -h {} + 2>/dev/null | sort -hr | head -20
echo "-> These are NOT synced. Move the ones you want to keep into Drive/Dropbox."

echo; echo "Report saved to: $OUT"
