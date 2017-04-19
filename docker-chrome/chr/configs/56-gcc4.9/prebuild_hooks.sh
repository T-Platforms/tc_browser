# Workaround for linking problem
sed -i 's/-Wl,--as-needed//' "$OUT_DIR/obj/chrome/chrome_initial.ninja"
