#!/bin/bash
# GAMIT/GLOBK 10.71 Automated Build Script
# Designed for Docker builds with gfortran 13+

set -e
cd /opt/gg

echo "=== GAMIT/GLOBK 10.71 Build Script ==="

# Fix Makefile.config for gfortran 13+ compatibility
echo "Patching Makefile.config for gfortran 13..."

# Update Linux version range and add compatibility flags
sed -i 's/OS_ID Linux 0001 5580/OS_ID Linux 0001 9999/' libraries/Makefile.config
sed -i 's/FFLAGS = -O3 -Wuninitialized -fno-f2c -ffast-math -fno-automatic -fno-backslash -m64 -mcmodel=large$/FFLAGS = -O3 -Wuninitialized -fno-f2c -ffast-math -fno-automatic -fno-backslash -m64 -mcmodel=large -fallow-argument-mismatch -fallow-invalid-boz/' libraries/Makefile.config

# Update X11 paths for Ubuntu
sed -i 's|^X11LIBPATH /usr/lib$|#X11LIBPATH /usr/lib|' libraries/Makefile.config
sed -i 's|^#X11LIBPATH /usr/lib/x86_64-linux-gnu$|X11LIBPATH /usr/lib/x86_64-linux-gnu|' libraries/Makefile.config

# Create symlinks for Makefile.config
ln -sf libraries/Makefile.config Makefile.config
ln -sf ../libraries/Makefile.config gamit/Makefile.config
ln -sf ../libraries/Makefile.config kf/Makefile.config

# Patch all existing Makefiles
echo "Patching all Makefiles..."
find . -name "Makefile" -type f -exec grep -l "mcmodel=large" {} \; 2>/dev/null | while read f; do
  if ! grep -q "fallow-argument-mismatch" "$f"; then
    sed -i 's/-mcmodel=large/-mcmodel=large -fallow-argument-mismatch -fallow-invalid-boz/g' "$f"
  fi
done

# Build libraries
echo "=== Phase 1: Building libraries ==="
for module in comlib matrix; do
    if [ -d "libraries/$module" ] && [ -f "libraries/$module/Makefile" ]; then
        echo "  Building libraries/$module..."
        (cd "libraries/$module" && make clean 2>/dev/null || true; make)
    fi
done

# Build GAMIT
echo "=== Phase 2: Building GAMIT ==="
for module in lib model grdtab orbits arc solve cfmrg hi tform makex utils fixdrv ctox clean; do
    if [ -d "gamit/$module" ] && [ -f "gamit/$module/Makefile" ]; then
        echo "  Building gamit/$module..."
        (cd "gamit/$module" && make clean 2>/dev/null || true; make 2>&1) || echo "Warning: gamit/$module had issues"
    fi
done

# Build GLOBK handlers and core libraries first
echo "=== Phase 3: Building GLOBK ==="
for module in Khandlers Ghandlers gen_util; do
    if [ -d "kf/$module" ] && [ -f "kf/$module/Makefile" ]; then
        echo "  Building kf/$module..."
        (cd "kf/$module" && make clean 2>/dev/null || true; make 2>&1) || echo "Warning: kf/$module had issues"
    fi
done

# Build GLOBK programs
for module in globk glorg glred glfor glinit glout glsave ctogobs track extract displace glist blsum; do
    if [ -d "kf/$module" ] && [ -f "kf/$module/Makefile" ]; then
        echo "  Building kf/$module..."
        (cd "kf/$module" && make clean 2>/dev/null || true; make 2>&1) || echo "Warning: kf/$module had issues"
    fi
done

# Fix globk missing function
if [ -f "kf/globk/add_GGV.f" ] && [ -f "kf/globk/globk_lib.a" ]; then
    echo "  Fixing globk add_GGV..."
    (cd kf/globk && \
     gfortran -c -O3 -fallow-argument-mismatch -fallow-invalid-boz add_GGV.f && \
     ar rv globk_lib.a add_GGV.o && \
     ranlib globk_lib.a && \
     rm -f add_GGV.o && \
     make 2>&1) || echo "Warning: globk final link had issues"
fi

echo "=== Build Complete ==="

# List built executables
echo ""
echo "Built executables:"
find gamit kf -type f -executable ! -name "*.sh" ! -name "Makefile*" -exec basename {} \; 2>/dev/null | sort -u
