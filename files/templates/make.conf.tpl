# Golden Master make.conf (baseline)
# NOTE: This sets ~amd64 for "bleeding edge". Adjust if you want stable.
COMMON_FLAGS="-O2 -pipe -march=native"
CFLAGS="${COMMON_FLAGS}"
CXXFLAGS="${COMMON_FLAGS}"
FCFLAGS="${COMMON_FLAGS}"
FFLAGS="${COMMON_FLAGS}"

LDFLAGS="-Wl,-O1 -Wl,--as-needed"
MAKEOPTS="-j$(nproc)"
EMERGE_DEFAULT_OPTS="--jobs=$(nproc) --load-average=$(nproc)"

CPU_FLAGS_X86="@CPU_FLAGS_X86@"
VIDEO_CARDS="@VIDEO_CARDS@"

USE="pulseaudio pipewire wayland vulkan"
ACCEPT_LICENSE="*"
ACCEPT_KEYWORDS="~amd64"
