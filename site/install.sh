#!/usr/bin/env bash
# مثبّت بانِي CLI — أمر واحد:
#   curl -fsSL https://skfk86.github.io/banee/install.sh | bash
# يعمل على Linux وmacOS وTermux. يحمّل الملفات اللازمة فقط (أقل من ١ ميغا) بدل المستودع كاملاً.
set -e

REPO_RAW="${BANEE_RAW:-https://raw.githubusercontent.com/skfk86/banee/main}"
DIR="$HOME/.banee"
APP="$DIR/app"
FILES="bin/banee.js lib/agent.js lib/engine.js package.json README.md"

g='\033[32m'; r='\033[31m'; d='\033[2m'; n='\033[0m'
say() { printf "%b\n" "$1"; }
die() { say "${r}✗ $1${n}"; exit 1; }

say "\n🧱 ${g}تثبيت بانِي${n}\n"

# ── Node.js ≥ 18 ──
if ! command -v node >/dev/null 2>&1; then
  if [ -n "$PREFIX" ] && command -v pkg >/dev/null 2>&1; then
    say "${d}تثبيت Node.js عبر pkg...${n}"; pkg install -y nodejs >/dev/null
  else
    die "بانِي يحتاج Node.js 18 أو أحدث. ثبّته ثم أعد الأمر:
   Ubuntu/Debian:  sudo apt install -y nodejs npm
   أو من:          https://nodejs.org"
  fi
fi
NODE_MAJOR=$(node -p 'process.versions.node.split(".")[0]')
[ "$NODE_MAJOR" -ge 18 ] || die "إصدار Node.js قديم ($(node -v)). المطلوب 18 أو أحدث."
command -v npm >/dev/null 2>&1 || die "npm غير موجود. ثبّته مع Node.js."

# ── تحميل الملفات ──
say "${d}تحميل بانِي...${n}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/lib" "$TMP/engine"
for f in $FILES; do
  curl -fsSL "$REPO_RAW/banee-cli/$f" -o "$TMP/$f" || die "تعذّر تحميل $f — تحقق من الاتصال"
done
curl -fsSL "$REPO_RAW/www/index.html" -o "$TMP/engine/index.html" || die "تعذّر تحميل محرك بانِي"

# الإعدادات والمفتاح في $DIR تبقى كما هي عند التحديث
mkdir -p "$DIR"
rm -rf "$APP.new" && mv "$TMP" "$APP.new" && trap - EXIT
if [ -d "$APP/node_modules" ]; then mv "$APP/node_modules" "$APP.new/node_modules"; fi
rm -rf "$APP" && mv "$APP.new" "$APP"
chmod +x "$APP/bin/banee.js"

# ── الاعتماديات (Playwright يُستخدم فقط لبناء تطبيق كامل بـ /new، ومتصفحه يُحمَّل عند أول استخدام) ──
say "${d}تثبيت الاعتماديات...${n}"
( cd "$APP" && npm install --omit=dev --ignore-scripts --no-audit --no-fund --loglevel=error >/dev/null 2>&1 ) \
  || say "${r}تنبيه:${n} تعذّر تثبيت Playwright. المحادثة والتعديل يعملان، وبناء تطبيق كامل (/new) يحتاجه."

# ── الأمر banee ──
if [ -n "$PREFIX" ] && [ -d "$PREFIX/bin" ]; then BIN="$PREFIX/bin"; else BIN="$HOME/.local/bin"; fi
mkdir -p "$BIN"
ln -sf "$APP/bin/banee.js" "$BIN/banee"

case ":$PATH:" in
  *":$BIN:"*) ;;
  *)
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      if [ -f "$rc" ] || [ "$rc" = "$HOME/.bashrc" ]; then
        grep -q "$BIN" "$rc" 2>/dev/null || printf '\nexport PATH="%s:$PATH"\n' "$BIN" >> "$rc"
      fi
    done
    NEED_RELOAD=1 ;;
esac

VER=$(node -p "require('$APP/package.json').version")
say "\n${g}✓ تم تثبيت بانِي $VER${n}\n"
if [ -n "$NEED_RELOAD" ]; then
  say "افتح terminal جديداً (أو شغّل: ${g}source ~/.bashrc${n}) ثم:"
fi
say "  ${g}cd${n} مجلد-مشروعك"
say "  ${g}banee${n}\n"
